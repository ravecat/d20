defmodule D20.KoalaRescueClub.GameTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Game
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

      assert {:error, :already_submitted} =
               dispatch(
                 game,
                 "submit_turn_selection",
                 "p1",
                 submit_shape("plant_trees", value, 0, [cell("a", 0, 1), cell("a", 0, 2)])
               )

      assert {:ok, %Game{phase: :roll, turn: 2, roll: nil} = game} =
               dispatch(game, "circle_tree", "p2", submit_tree(value, "a", 0, 0))

      assert game.players["p1"].status == :ready
      assert game.players["p2"].status == :ready
    end

    test "replaces whole-shape commands with atomic full-selection submission" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :invalid_phase} =
               dispatch(game, "plant_trees", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cells" => [cell("a", 0, 0), cell("a", 0, 1)]
               })

      assert {:ok, %Game{} = game} =
               dispatch(
                 game,
                 "submit_turn_selection",
                 "p1",
                 submit_shape("plant_trees", 1, 0, [cell("a", 0, 0), cell("a", 0, 1)])
               )

      assert %{area: :a, row: 0, column: 0} in game.players["p1"].sheet.trees
      assert %{area: :a, row: 0, column: 1} in game.players["p1"].sheet.trees
      refute Map.has_key?(game.players["p1"], :turn_selection)
    end

    test "rejects retired draft mutation commands without changing the game" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :invalid_phase} =
               dispatch(game, "select_turn_cell", "p1", %{"target_cell" => cell("a", 0, 0)})

      assert {:error, :invalid_phase} =
               dispatch(game, "deselect_turn_cell", "p1", %{"target_cell" => cell("a", 0, 0)})

      assert {:error, :invalid_phase} = dispatch(game, "reset_turn_selection", "p1")
      refute Map.has_key?(game.players["p1"], :turn_selection)
    end

    test "requires complete koala placements on eligible trees" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      selection = submit_shape("rehome_koalas", 1, 0, [cell("a", 0, 0), cell("a", 0, 1)])

      assert {:error, :koala_requires_tree} =
               dispatch(game, "submit_turn_selection", "p1", selection)

      trees = [%{area: :a, row: 0, column: 0}, %{area: :a, row: 0, column: 1}]
      game = put_in(game.players["p1"].sheet.trees, trees)

      assert {:ok, game} = dispatch(game, "submit_turn_selection", "p1", selection)

      assert game.players["p1"].sheet.koalas == trees
    end

    test "rejects incomplete submission and delays volunteer spending until commit" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :incomplete_turn_selection} =
               dispatch(
                 game,
                 "submit_turn_selection",
                 "p1",
                 submit_shape("plant_trees", 2, 1, [cell("a", 0, 0)])
               )

      assert game.players["p1"].sheet.trees == []
      assert game.players["p1"].sheet.volunteers == available_volunteers()

      assert {:ok, game} =
               dispatch(
                 game,
                 "submit_turn_selection",
                 "p1",
                 submit_shape("plant_trees", 2, 1, [cell("a", 0, 0), cell("a", 0, 1)])
               )

      assert game.players["p1"].sheet.volunteers == [
               :used,
               :locked,
               :locked,
               :locked,
               :locked,
               :locked
             ]
    end

    test "advances a multiplayer turn after shape and fallback submissions" do
      {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")
      assert {:ok, game} = dispatch(game, "start", "p1")
      game = force_submit_turn(game, 1, 1, 1)

      assert {:ok, %Game{phase: :submit} = game} =
               dispatch(
                 game,
                 "submit_turn_selection",
                 "p1",
                 submit_shape("plant_trees", 1, 0, [cell("a", 0, 0), cell("a", 0, 1)])
               )

      assert game.players["p1"].status == :submitted
      assert game.players["p2"].status == :pending

      assert {:ok, %Game{phase: :roll, turn: 2} = game} =
               dispatch(game, "circle_tree", "p2", submit_tree(1, "a", 0, 0))

      refute Map.has_key?(game.players["p1"], :turn_selection)
      refute Map.has_key?(game.players["p2"], :turn_selection)
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

    test "applies a full shape and its bonuses atomically" do
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

      selection = submit_shape("rehome_koalas", 1, 0, [cell("a", 0, 2), cell("a", 0, 3)])

      refute %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses

      invalid_bonus =
        Map.put(selection, "bonus_actions", [
          %{
            "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
            "action" => %{"kind" => "skybridge", "to" => "c"}
          }
        ])

      assert {:error, :invalid_bonus} =
               dispatch(game, "submit_turn_selection", "p1", invalid_bonus)

      assert game.players["p1"].sheet.koalas == existing_koalas
      assert game.players["p1"].status == :pending

      valid_bonus =
        Map.put(selection, "bonus_actions", [
          %{
            "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
            "action" => %{"kind" => "skybridge", "to" => "b"}
          }
        ])

      assert {:ok, game} = dispatch(game, "submit_turn_selection", "p1", valid_bonus)

      assert game.players["p1"].sheet.koalas == row_0
      assert %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses
      assert %{from: :a, to: :b} in game.players["p1"].sheet.skybridges
    end

    test "keeps single-cell tree and koala fallbacks atomic" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))
      refute Map.has_key?(game.players["p1"], :turn_selection)
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

      refute Map.has_key?(game.players["p1"], :turn_selection)
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
        players: Map.new(game.players, fn {id, player} -> {id, %{player | status: :pending}} end)
    }
  end

  defp submit_shape(action, die_value, volunteers_used, selected_cells) do
    %{
      "action" => action,
      "die_value" => die_value,
      "volunteers_used" => volunteers_used,
      "selected_cells" => selected_cells,
      "bonus_actions" => []
    }
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
