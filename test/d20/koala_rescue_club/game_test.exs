defmodule D20.KoalaRescueClub.GameTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset
  alias D20.KoalaRescueClub.Server

  describe "D20.Game behaviour" do
    test "uses the automatic-roll session server" do
      assert D20.Game.server(Game) == Server
    end

    test "starts with a selected sheet and encodes state as JSON" do
      assert {:ok, %Game{phase: :setup, sheet: :yugambeh} = game} =
               D20.Game.init(Game, %{"sheet" => "yugambeh"})

      assert {:ok, %Game{phase: :ready, order: ["p1"]} = game} = dispatch(game, "join", "p1")

      assert {:ok, %Game{phase: :roll, sheet: :yugambeh, turn: 1, round: 1} = game} =
               dispatch(game, "start", "p1")

      assert game.players["p1"].sheet.volunteers == [
               :locked,
               :locked,
               :locked,
               :locked,
               :locked,
               :locked
             ]

      assert game.players["p1"].sheet.areas == %{a: true}

      decoded = game |> Jason.encode!() |> Jason.decode!()

      assert decoded["phase"] == "roll"
      assert decoded["sheet"] == "yugambeh"
      assert decoded["players"]["p1"]["sheet"]["trees"] == []
    end

    test "finishes after turn 30 is resolved" do
      game = "dharug" |> started_game() |> force_submit_turn(30, 2, 1)

      assert {:ok, %Game{phase: :finished, scores: %{"p1" => score}}} =
               dispatch(game, "circle_tree", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cell" => cell("a", 0, 0)
               })

      assert score.rank in [
               :junior_club_member,
               :club_secretary,
               :club_treasurer,
               :vice_president,
               :president
             ]
    end
  end

  describe "dispatch/2" do
    test "checks actor requirements per command" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:error, :invalid_identity} = dispatch(game, "join", nil)

      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:error, :invalid_identity} = dispatch(game, "start", nil)

      assert {:ok, game} = dispatch(game, "start", "p1")
      assert {:error, :invalid_identity} = dispatch(game, "roll", "p1")
      assert {:ok, %Game{phase: :submit}} = dispatch(game, "roll", nil)
    end

    test "rejects players above the supported range" do
      assert {:ok, game} = D20.Game.init(Game)

      game =
        Enum.reduce(1..99, game, fn index, game ->
          {:ok, game} = dispatch(game, "join", "p#{index}")
          game
        end)

      assert length(game.order) == 99
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert length(game.order) == 99
      assert {:error, :invalid_player_count} = dispatch(game, "join", "p100")
    end

    test "uses one shared roll and advances after all players submit" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")
      assert {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, %Game{phase: :submit, roll: %{value: value}} = game} =
               dispatch(game, "roll", nil)

      assert game.players["p1"].status == :pending
      assert game.players["p2"].status == :pending

      assert {:ok, %Game{phase: :submit} = game} =
               dispatch(game, "circle_tree", "p1", submit_tree(value, "a", 0, 0))

      assert game.players["p1"].status == :submitted
      assert game.players["p1"].sheet.trees == [%{area: :a, row: 0, column: 0}]

      assert {:error, :already_submitted} = click_cell(game, "plant_trees", value, 0, "a", 0, 1)

      assert {:ok, %Game{phase: :roll, turn: 2, roll: nil} = game} =
               dispatch(game, "circle_tree", "p2", submit_tree(value, "a", 0, 0))

      assert game.players["p1"].status == :ready
      assert game.players["p2"].status == :ready
    end

    test "replaces whole-shape commands with staged shape submission" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :invalid_phase} =
               dispatch(game, "plant_trees", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cells" => [cell("a", 0, 0), cell("a", 0, 1)]
               })

      assert {:ok, game} = click_cell(game, "plant_trees", 1, 0, "a", 0, 0)
      assert game.players["p1"].sheet.trees == []
      assert game.players["p1"].sheet.volunteers == available_volunteers()

      assert {:ok, game} = select_cell(game, "a", 0, 1)

      assert %{complete: true, available_cells: []} = Rules.turn_selection(game, "p1")
      assert game.players["p1"].sheet.trees == []

      assert {:ok, %Game{} = game} = dispatch(game, "submit_turn_selection", "p1")

      assert %{area: :a, row: 0, column: 0} in game.players["p1"].sheet.trees
      assert %{area: :a, row: 0, column: 1} in game.players["p1"].sheet.trees

      assert game.players["p1"].turn_selection == nil
    end

    test "starts and switches a shape selection with cell clicks" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:ok, selected} = click_cell(game, "plant_trees", 1, 0, "a", 0, 0)

      assert %{
               action: "plant_trees",
               die_value: 1,
               volunteers_used: 0,
               selected_cells: [%{area: :a, row: 0, column: 0}]
             } = selected.players["p1"].turn_selection

      assert selected.players["p1"].sheet == game.players["p1"].sheet

      assert {:ok, switched} = click_cell(selected, "plant_trees", 2, 1, "a", 0, 1)

      assert %{
               action: "plant_trees",
               die_value: 2,
               volunteers_used: 1,
               selected_cells: [%{area: :a, row: 0, column: 1}]
             } = switched.players["p1"].turn_selection
    end

    test "requires complete koala placements on eligible trees" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :no_legal_placement} = click_cell(game, "rehome_koalas", 1, 0, "a", 0, 0)

      trees = [%{area: :a, row: 0, column: 0}, %{area: :a, row: 0, column: 1}]
      game = put_in(game.players["p1"].sheet.trees, trees)

      assert {:ok, game} = click_cell(game, "rehome_koalas", 1, 0, "a", 0, 0)
      assert {:ok, game} = select_cell(game, "a", 0, 1)
      assert {:ok, game} = dispatch(game, "submit_turn_selection", "p1")

      assert game.players["p1"].sheet.koalas == trees
    end

    test "edits, replaces, and resets a partial selection without side effects" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:ok, selected} = click_cell(game, "plant_trees", 1, 0, "a", 0, 0)
      assert {:ok, ^selected} = select_cell(selected, "a", 0, 0)

      assert {:error, :invalid_target} = select_cell(selected, "b", 0, 0)

      assert {:ok, deselected} =
               dispatch(selected, "deselect_turn_cell", "p1", %{"target_cell" => cell("a", 0, 0)})

      assert deselected.players["p1"].turn_selection.selected_cells == []

      assert {:ok, ^deselected} =
               dispatch(deselected, "deselect_turn_cell", "p1", %{
                 "target_cell" => cell("a", 0, 0)
               })

      assert {:ok, replaced} = click_cell(selected, "plant_trees", 2, 1, "a", 0, 1)

      assert %{
               action: "plant_trees",
               die_value: 2,
               volunteers_used: 1,
               selected_cells: [%{area: :a, row: 0, column: 1}]
             } = replaced.players["p1"].turn_selection

      assert replaced.players["p1"].sheet == game.players["p1"].sheet

      assert {:error, :no_legal_placement} =
               click_cell(replaced, "rehome_koalas", 2, 1, "a", 0, 0)

      assert {:ok, reset} = dispatch(replaced, "reset_turn_selection", "p1")
      assert reset.players["p1"].turn_selection == nil
      assert reset.players["p1"].sheet == game.players["p1"].sheet
      assert reset.players["p1"].status == :pending
    end

    test "derives the same continuation regardless of selection order" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 4)

      assert {:ok, first_order} = click_cell(game, "plant_trees", 4, 0, "a", 0, 0)
      assert {:ok, first_order} = select_cell(first_order, "a", 0, 1)

      assert {:ok, second_order} = click_cell(game, "plant_trees", 4, 0, "a", 0, 1)
      assert {:ok, second_order} = select_cell(second_order, "a", 0, 0)

      assert %{
               complete: first_complete,
               selected_cells: first_selected,
               available_cells: first_available
             } = Rules.turn_selection(first_order, "p1")

      assert %{
               complete: ^first_complete,
               selected_cells: ^first_selected,
               available_cells: ^first_available
             } = Rules.turn_selection(second_order, "p1")
    end

    test "rejects incomplete submission and delays volunteer spending until commit" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:ok, game} = click_cell(game, "plant_trees", 2, 1, "a", 0, 0)

      assert {:error, :incomplete_turn_selection} = dispatch(game, "submit_turn_selection", "p1")

      assert game.players["p1"].sheet.trees == []
      assert game.players["p1"].sheet.volunteers == available_volunteers()
      assert game.players["p1"].turn_selection != nil

      assert {:ok, game} = select_cell(game, "a", 0, 1)
      assert {:ok, game} = dispatch(game, "submit_turn_selection", "p1")

      assert game.players["p1"].sheet.volunteers == [
               :used,
               :locked,
               :locked,
               :locked,
               :locked,
               :locked
             ]
    end

    test "advances a multiplayer turn after staged and fallback submissions" do
      {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")
      assert {:ok, game} = dispatch(game, "start", "p1")
      game = force_submit_turn(game, 1, 1, 1)

      assert {:ok, game} = click_cell(game, "plant_trees", 1, 0, "a", 0, 0)
      assert {:ok, game} = select_cell(game, "a", 0, 1)

      assert {:ok, %Game{phase: :submit} = game} = dispatch(game, "submit_turn_selection", "p1")

      assert game.players["p1"].status == :submitted
      assert game.players["p2"].status == :pending

      assert {:ok, %Game{phase: :roll, turn: 2} = game} =
               dispatch(game, "circle_tree", "p2", submit_tree(1, "a", 0, 0))

      assert game.players["p1"].turn_selection == nil
      assert game.players["p2"].turn_selection == nil
    end

    test "rejects inaccessible areas and insufficient volunteer adjustments" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :inaccessible_area} =
               dispatch(game, "circle_tree", "p1", submit_tree(1, "b", 0, 0))

      assert {:error, :insufficient_volunteers} =
               dispatch(game, "circle_tree", "p1", %{
                 "die_value" => 4,
                 "volunteers_used" => 3,
                 "target_cell" => cell("a", 0, 0)
               })
    end

    test "marks available volunteers as used when adjusting die value" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:ok, game} =
               dispatch(game, "circle_tree", "p1", %{
                 "die_value" => 2,
                 "volunteers_used" => 1,
                 "target_cell" => cell("a", 0, 0)
               })

      assert game.players["p1"].sheet.volunteers == [
               :used,
               :locked,
               :locked,
               :locked,
               :locked,
               :locked
             ]
    end

    test "rejects bonus actions that are not unlocked" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :bonus_not_unlocked} =
               dispatch(game, "circle_tree", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cell" => cell("a", 0, 0),
                 "bonus_actions" => [
                   %{
                     "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
                     "action" => %{"kind" => "skybridge", "to" => "b"}
                   }
                 ]
               })
    end

    test "previews staged bonuses and preserves the complete draft on invalid submission" do
      row_0 = row_cells("a", 0, 0..3)
      existing_koalas = Enum.take(row_0, 2)

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], row_0)
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)],
          existing_koalas
        )
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} = click_cell(game, "rehome_koalas", 1, 0, "a", 0, 2)
      assert {:ok, game} = select_cell(game, "a", 0, 3)

      assert %{
               complete: true,
               bonus_options: [
                 %{ref: %{area: :a, axis: :row, index: 0}, bonus: %{kind: :skybridge, to: :b}}
               ]
             } = Rules.turn_selection(game, "p1")

      refute %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses

      invalid_bonus = %{
        "bonus_actions" => [
          %{
            "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
            "action" => %{"kind" => "skybridge", "to" => "c"}
          }
        ]
      }

      assert {:error, :invalid_bonus} =
               dispatch(game, "submit_turn_selection", "p1", invalid_bonus)

      assert Rules.turn_selection(game, "p1").complete
      assert game.players["p1"].sheet.koalas == existing_koalas
      assert game.players["p1"].status == :pending

      valid_bonus = %{
        "bonus_actions" => [
          %{
            "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
            "action" => %{"kind" => "skybridge", "to" => "b"}
          }
        ]
      }

      assert {:ok, game} = dispatch(game, "submit_turn_selection", "p1", valid_bonus)

      assert game.players["p1"].sheet.koalas == row_0
      assert %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses
      assert %{from: :a, to: :b} in game.players["p1"].sheet.skybridges
    end

    test "keeps single-cell tree and koala fallbacks atomic" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))
      assert game.players["p1"].turn_selection == nil
      assert [%{area: :a, row: 0, column: 0}] = game.players["p1"].sheet.trees

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], [
          %{area: :a, row: 0, column: 0}
        ])
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} =
               dispatch(game, "circle_koala", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cell" => cell("a", 0, 0)
               })

      assert game.players["p1"].turn_selection == nil
      assert [%{area: :a, row: 0, column: 0}] = game.players["p1"].sheet.koalas
    end

    test "stores resolved bonus coordinates" do
      row_0 = row_cells("a", 0, 0..3)

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], row_0)
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)], row_0)
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} =
               dispatch(game, "circle_tree", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cell" => cell("a", 1, 0),
                 "bonus_actions" => [
                   %{
                     "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
                     "action" => %{"kind" => "skybridge", "to" => "b"}
                   }
                 ]
               })

      assert %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses
      assert %{from: :a, to: :b} in game.players["p1"].sheet.skybridges
      assert game.players["p1"].sheet.areas == %{a: true, b: true}

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], row_0)
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)], row_0)
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 1, 0))

      refute Enum.any?(
               game.players["p1"].sheet.bonuses,
               &match?(%{area: :a, axis: :row, index: 0}, &1)
             )
    end

    test "marks an explicitly skipped optional bonus as resolved" do
      row_0 = row_cells("a", 0, 0..3)

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], row_0)
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)], row_0)
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} =
               dispatch(game, "circle_tree", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cell" => cell("a", 1, 0),
                 "bonus_actions" => [
                   %{
                     "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
                     "action" => %{"kind" => "skip"}
                   }
                 ]
               })

      assert %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses
      assert game.players["p1"].sheet.skybridges == []
    end

    test "awards badges from selected sheet predicates" do
      map = Ruleset.sheet!(:dharug)
      c_trees = Ruleset.area_cells(map, :c)

      game =
        "dharug"
        |> started_game()
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)],
          c_trees
        )
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))

      assert %{tree_lover: :large} = game.players["p1"].badges
    end
  end

  describe "turn_options/2" do
    test "projects all die values with costs and server-derived primary actions" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      options = Rules.turn_options(game, "p1")

      assert Map.keys(options) |> Enum.sort() == ~w(1 2 3 4 5 6)
      assert options["1"].volunteer_cost == 0
      assert options["2"].volunteer_cost == 1
      assert options["3"].volunteer_cost == 2
      assert options["4"].volunteer_cost == 3
      assert options["5"].volunteer_cost == 2
      assert options["6"].volunteer_cost == 1

      assert %{available_cells: plant_cells} = options["1"].actions["plant_trees"]
      assert %{available_cells: tree_cells} = options["1"].actions["circle_tree"]
      assert plant_cells != []
      assert tree_cells != []
      assert Enum.all?(tree_cells, &(&1.area == :a))
      refute Map.has_key?(options["1"].actions, "rehome_koalas")
      refute Map.has_key?(options["1"].actions, "circle_koala")

      assert options["3"].actions == %{}
      assert options["4"].actions == %{}
      assert options["5"].actions == %{}
    end

    test "derives single-koala cells from the caller sheet and clears options after submission" do
      tree = %{area: :a, row: 0, column: 0}

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], [tree])
        |> force_submit_turn(1, 1, 1)

      assert %{available_cells: [^tree]} =
               Rules.turn_options(game, "p1")["1"].actions["circle_koala"]

      submitted = put_in(game.players["p1"].status, :submitted)

      assert Rules.turn_options(submitted, "p1") == %{}
    end
  end

  describe "scores" do
    test "stores separate tree, koala, hospital, and total scores for scoring turns" do
      map = Ruleset.sheet!(:dharug)
      c_cells = Ruleset.area_cells(map, :c)
      d_cells = Ruleset.area_cells(map, :d)

      game =
        "dharug"
        |> started_game()
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)],
          c_cells
        )
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)],
          d_cells
        )
        |> put_in(
          [
            Access.key!(:players),
            "p1",
            Access.key!(:sheet),
            Access.key!(:hospitals),
            :hospital_2
          ],
          3
        )
        |> force_submit_turn(15, 1, 1)

      assert {:ok, %Game{phase: :roll, turn: 16} = game} =
               dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))

      assert [%{trees: 1, koalas: 1, hospitals: 2, total: 4}] = game.players["p1"].rounds
    end

    test "stores computed total in final scores" do
      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:rounds)], [
          %{trees: 1, koalas: 2, hospitals: 3, total: 6}
        ])
        |> put_in([Access.key!(:players), "p1", Access.key!(:badges)], %{tree_lover: :large})
        |> force_submit_turn(30, 2, 1)

      assert {:ok,
              %Game{phase: :finished, scores: %{"p1" => %{total: 9, rank: :junior_club_member}}}} =
               dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))
    end
  end

  defp started_game(sheet) do
    {:ok, game} = D20.Game.init(Game, %{"sheet" => sheet})
    {:ok, game} = dispatch(game, "join", "p1")
    {:ok, game} = dispatch(game, "start", "p1")
    game
  end

  defp force_submit_turn(game, turn, round, value) do
    %{
      game
      | phase: :submit,
        turn: turn,
        round: round,
        roll: %{value: value},
        players:
          Map.new(game.players, fn {id, player} ->
            {id, %{player | status: :pending, turn_selection: nil}}
          end)
    }
  end

  defp select_cell(game, area, row, column) do
    dispatch(game, "select_turn_cell", "p1", %{"target_cell" => cell(area, row, column)})
  end

  defp click_cell(game, action, die_value, volunteers_used, area, row, column) do
    dispatch(game, "select_turn_cell", "p1", %{
      "action" => action,
      "die_value" => die_value,
      "volunteers_used" => volunteers_used,
      "target_cell" => cell(area, row, column)
    })
  end

  defp available_volunteers do
    [:available, :locked, :locked, :locked, :locked, :locked]
  end

  defp submit_tree(value, area, row, column) do
    %{"die_value" => value, "volunteers_used" => 0, "target_cell" => cell(area, row, column)}
  end

  defp cell(area, row, column) do
    %{"area" => area, "row" => row, "column" => column}
  end

  defp row_cells(area, row, columns) do
    Enum.map(columns, &%{area: String.to_existing_atom(area), row: row, column: &1})
  end

  defp dispatch(game, event, actor_id, attrs \\ %{}) do
    Game.dispatch(game, %Command{event: event, actor_id: actor_id, attrs: attrs})
  end
end
