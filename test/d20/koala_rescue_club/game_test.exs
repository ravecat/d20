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
      assert {:ok, %Game{phase: :setup, sheet: :yugambeh, opponent: :bot_hard, mode: nil} = game} =
               D20.Game.init(Game, %{"sheet" => "yugambeh", "opponent" => "bot_hard"})

      assert {:ok, %Game{phase: :ready, mode: nil, players: %{"p1" => _player}} = game} =
               dispatch(game, "join", "p1")

      assert {:ok, %Game{phase: :roll, sheet: :yugambeh, mode: :solo, turn: 1, round: 1} = game} =
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
      assert decoded["opponent"] == "bot_hard"
      assert decoded["mode"] == "solo"
      refute Map.has_key?(decoded, "order")
      assert decoded["players"]["p1"]["sheet"]["trees"] == []
      assert decoded["players"]["p1"]["turns"] == []
      assert decoded["players"]["p1"]["last_action"] == nil
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

  describe "fetch_player/2" do
    test "returns the requested player or :error" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")

      assert {:ok, %{status: :ready}} = Game.fetch_player(game, "p1")
      assert :error = Game.fetch_player(game, "missing")
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

      assert map_size(game.players) == 99
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert map_size(game.players) == 99
      assert {:error, :invalid_player_count} = dispatch(game, "join", "p100")
    end

    test "uses one shared roll and advances after all players submit" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")
      assert {:ok, %Game{mode: :multiplayer} = game} = dispatch(game, "start", "p1")

      assert {:ok, %Game{phase: :submit, roll: %{value: value}} = game} =
               dispatch(game, "roll", nil)

      assert game.players["p1"].status == :pending
      assert game.players["p2"].status == :pending

      assert {:ok, %Game{phase: :submit} = game} =
               dispatch(game, "circle_tree", "p1", submit_tree(value, "a", 0, 0))

      assert game.players["p1"].status == :submitted
      assert game.players["p1"].sheet.trees == [%{area: :a, row: 0, column: 0}]

      assert game.players["p1"].turns == [value]

      assert game.players["p1"].last_action == %{
               turn: 1,
               action: "circle_tree",
               die_value: value,
               target_cells: [%{area: :a, row: 0, column: 0}]
             }

      assert {:error, :already_submitted} =
               dispatch(game, "submit", "p1", %{"bonus_actions" => []})

      assert game.players["p1"].turns == [value]

      assert {:ok, %Game{phase: :roll, turn: 2, roll: nil} = game} =
               dispatch(game, "circle_tree", "p2", submit_tree(value, "a", 0, 0))

      assert game.players["p1"].status == :ready
      assert game.players["p2"].status == :ready

      assert game.players["p2"].turns == [value]
    end

    test "freezes multiplayer mode and the accepted roster after start" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")

      assert {:ok,
              %Game{
                phase: :roll,
                mode: :multiplayer,
                players: %{"p1" => _player_1, "p2" => _player_2}
              } = game} = dispatch(game, "start", "p1")

      assert {:ok, ^game} = dispatch(game, "join", "p3")
      assert {:ok, ^game} = dispatch(game, "leave", "p1")
    end

    test "derives mode from players still present when the game starts" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")

      assert {:ok, %Game{phase: :ready, mode: nil, players: %{"p1" => _player}} = game} =
               dispatch(game, "leave", "p2")

      assert {:ok, %Game{phase: :roll, mode: :solo, players: %{"p1" => _player}}} =
               dispatch(game, "start", "p1")
    end

    test "returns to setup when the last player leaves before start" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")

      assert {:ok, %Game{phase: :setup, mode: nil, players: %{}}} = dispatch(game, "leave", "p1")
    end

    test "stores canonical selection and submits it atomically" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :invalid_phase} =
               dispatch(game, "plant_trees", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cells" => [cell("a", 0, 0), cell("a", 0, 1)]
               })

      assert {:ok, game} =
               dispatch(game, "select", "p1", %{
                 "action" => "plant_trees",
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cell" => cell("a", 0, 0)
               })

      assert game.players["p1"].selection == %{
               action: "plant_trees",
               value: 1,
               volunteers: 0,
               cells: [%{area: :a, row: 0, column: 0}]
             }

      refute Map.has_key?(game.players["p1"].selection, :required_cells)
      refute Map.has_key?(game.players["p1"].selection, :available_cells)
      assert game.players["p1"].sheet.trees == []

      assert {:ok, game} = dispatch(game, "select", "p1", %{"target_cell" => cell("a", 0, 1)})

      assert {:ok, %Game{} = game} = dispatch(game, "submit", "p1", %{"bonus_actions" => []})

      assert %{area: :a, row: 0, column: 0} in game.players["p1"].sheet.trees
      assert %{area: :a, row: 0, column: 1} in game.players["p1"].sheet.trees
      assert game.players["p1"].selection == nil
      assert game.players["p1"].turns == [1]
    end

    test "edits, replaces, and resets selection idempotently" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :missing_turn_selection} =
               dispatch(game, "select", "p1", %{"target_cell" => cell("a", 0, 0)})

      game = select_shape(game, "p1", "plant_trees", 1, 0, [cell("a", 0, 0)])
      original = game.players["p1"].selection

      assert {:ok, same_game} =
               dispatch(game, "select", "p1", %{"target_cell" => cell("a", 0, 0)})

      assert same_game.players["p1"].selection == original

      assert {:error, :invalid_target} =
               dispatch(game, "select", "p1", %{"target_cell" => cell("b", 0, 0)})

      assert game.players["p1"].selection == original

      assert {:ok, game} = dispatch(game, "deselect", "p1", %{"target_cell" => cell("a", 0, 0)})

      assert game.players["p1"].selection.cells == []

      assert {:ok, game} = dispatch(game, "deselect", "p1", %{"target_cell" => cell("a", 0, 0)})

      assert game.players["p1"].selection.cells == []

      assert {:ok, game} =
               dispatch(game, "select", "p1", %{
                 "action" => "plant_trees",
                 "die_value" => 2,
                 "volunteers_used" => 1,
                 "target_cell" => cell("a", 1, 0)
               })

      assert %{value: 2, volunteers: 1, cells: [%{row: 1, column: 0}]} =
               game.players["p1"].selection

      assert {:ok, game} = dispatch(game, "reset", "p1")
      assert game.players["p1"].selection == nil
    end

    test "requires complete koala placements on eligible trees" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      selection = %{
        action: "rehome_koalas",
        value: 1,
        volunteers: 0,
        cells: [%{area: :a, row: 0, column: 0}, %{area: :a, row: 0, column: 1}]
      }

      game = put_in(game.players["p1"].selection, selection)

      assert {:error, :no_legal_placement} =
               dispatch(game, "submit", "p1", %{"bonus_actions" => []})

      assert game.players["p1"].selection == selection
      assert game.players["p1"].sheet.koalas == []

      trees = [%{area: :a, row: 0, column: 0}, %{area: :a, row: 0, column: 1}]
      game = put_in(game.players["p1"].sheet.trees, trees)

      assert {:ok, game} = dispatch(game, "submit", "p1", %{"bonus_actions" => []})

      assert game.players["p1"].sheet.koalas == trees
    end

    test "rejects incomplete submission and delays volunteer spending until commit" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      game = select_shape(game, "p1", "plant_trees", 2, 1, [cell("a", 0, 0)])
      selection = game.players["p1"].selection

      assert {:error, :incomplete_turn_selection} =
               dispatch(game, "submit", "p1", %{"bonus_actions" => []})

      assert game.players["p1"].sheet.trees == []
      assert game.players["p1"].sheet.volunteers == available_volunteers()
      assert game.players["p1"].selection == selection

      assert {:ok, game} = dispatch(game, "select", "p1", %{"target_cell" => cell("a", 0, 1)})

      assert {:ok, game} = dispatch(game, "submit", "p1", %{"bonus_actions" => []})

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
               game
               |> select_shape("p1", "plant_trees", 1, 0, [cell("a", 0, 0), cell("a", 0, 1)])
               |> dispatch("submit", "p1", %{"bonus_actions" => []})

      assert game.players["p1"].status == :submitted
      assert game.players["p2"].status == :pending

      assert {:ok, %Game{phase: :roll, turn: 2} = game} =
               dispatch(game, "circle_tree", "p2", submit_tree(1, "a", 0, 0))

      assert game.players["p1"].selection == nil
      assert game.players["p2"].selection == nil
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

      game = select_shape(game, "p1", "rehome_koalas", 1, 0, [cell("a", 0, 2), cell("a", 0, 3)])

      selection = game.players["p1"].selection

      refute %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses

      invalid_bonus = %{
        "bonus_actions" => [
          %{
            "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
            "action" => %{"kind" => "skybridge", "to" => "c"}
          }
        ]
      }

      assert {:error, :invalid_bonus} = dispatch(game, "submit", "p1", invalid_bonus)

      assert game.players["p1"].sheet.koalas == existing_koalas
      assert game.players["p1"].status == :pending
      assert game.players["p1"].selection == selection

      valid_bonus = %{
        "bonus_actions" => [
          %{
            "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
            "action" => %{"kind" => "skybridge", "to" => "b"}
          }
        ]
      }

      assert {:ok, game} = dispatch(game, "submit", "p1", valid_bonus)

      assert game.players["p1"].sheet.koalas == row_0
      assert %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses
      assert %{from: :a, to: :b} in game.players["p1"].sheet.skybridges
      assert game.players["p1"].selection == nil
    end

    test "keeps single-cell tree and koala fallbacks atomic" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))
      assert game.players["p1"].selection == nil
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

      assert game.players["p1"].selection == nil
      assert [%{area: :a, row: 0, column: 0}] = game.players["p1"].sheet.koalas
    end

    test "forfeits an omitted current-turn bonus and prevents later reuse" do
      row_0 = row_cells("a", 0, 0..3)
      existing_koalas = Enum.take(row_0, 3)

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], row_0)
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)],
          existing_koalas
        )
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} =
               dispatch(game, "circle_koala", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cell" => cell("a", 0, 3),
                 "bonus_actions" => []
               })

      assert %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses
      assert game.players["p1"].sheet.skybridges == []
      assert game.players["p1"].sheet.areas == %{a: true}

      game = force_submit_turn(game, 2, 1, 1)

      assert {:error, :bonus_already_resolved} =
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

      refute %{area: :a, row: 1, column: 0} in game.players["p1"].sheet.trees
      assert game.players["p1"].sheet.skybridges == []
    end

    test "rejects an earlier-turn bonus and cleans it up on a valid submission" do
      row_0 = row_cells("a", 0, 0..3)

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], row_0)
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)], row_0)
        |> force_submit_turn(1, 1, 1)

      earlier_bonus = %{
        "die_value" => 1,
        "volunteers_used" => 0,
        "target_cell" => cell("a", 1, 0),
        "bonus_actions" => [
          %{
            "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
            "action" => %{"kind" => "skybridge", "to" => "b"}
          }
        ]
      }

      assert {:error, :invalid_bonus} = dispatch(game, "circle_tree", "p1", earlier_bonus)
      refute %{area: :a, row: 1, column: 0} in game.players["p1"].sheet.trees
      assert game.players["p1"].sheet.bonuses == []

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 1, 0))

      assert %{area: :a, axis: :row, index: 0} in game.players["p1"].sheet.bonuses
      assert game.players["p1"].sheet.skybridges == []
    end

    test "marks an explicitly skipped optional bonus as resolved" do
      row_0 = row_cells("a", 0, 0..3)
      existing_koalas = Enum.take(row_0, 3)

      game =
        "dharug"
        |> started_game()
        |> put_in([Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)], row_0)
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)],
          existing_koalas
        )
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} =
               dispatch(game, "circle_koala", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cell" => cell("a", 0, 3),
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

    test "projects only bonuses opened by the current complete selection" do
      row_0 = row_cells("a", 0, 0..3)
      row_1 = row_cells("a", 1, 0..3)

      game =
        "dharug"
        |> started_game()
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)],
          row_0 ++ row_1
        )
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:koalas)],
          row_0 ++ Enum.take(row_1, 2)
        )
        |> force_submit_turn(1, 1, 1)
        |> select_shape("p1", "rehome_koalas", 1, 0, Enum.drop(row_1, 2))

      assert %{complete: true, bonus_options: bonus_options} = Rules.selection_details(game, "p1")

      assert Enum.map(bonus_options, & &1.ref) == [%{area: :a, axis: :row, index: 1}]
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

    test "uses solo round timing for badge awards" do
      map = Ruleset.sheet!(:dharug)
      c_trees = Ruleset.area_cells(map, :c)

      game =
        "dharug"
        |> started_game()
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)],
          c_trees
        )
        |> force_submit_turn(16, 2, 1)

      assert {:ok, %Game{mode: :solo} = game} =
               dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))

      assert %{tree_lover: :small} = game.players["p1"].badges
    end

    test "awards simultaneous first achievers the same large badge" do
      map = Ruleset.sheet!(:dharug)
      c_trees = Ruleset.area_cells(map, :c)

      assert {:ok, game} = D20.Game.init(Game, %{"sheet" => "dharug"})
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")
      assert {:ok, game} = dispatch(game, "start", "p1")

      game =
        game
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)],
          c_trees
        )
        |> put_in(
          [Access.key!(:players), "p2", Access.key!(:sheet), Access.key!(:trees)],
          c_trees
        )
        |> force_submit_turn(1, 1, 1)

      assert {:ok, %Game{phase: :submit} = game} =
               dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))

      assert {:ok, %Game{phase: :roll} = game} =
               dispatch(game, "circle_tree", "p2", submit_tree(1, "a", 0, 0))

      assert %{tree_lover: :large} = game.players["p1"].badges
      assert %{tree_lover: :large} = game.players["p2"].badges
    end

    test "awards every later achiever the same small badge" do
      map = Ruleset.sheet!(:dharug)
      c_trees = Ruleset.area_cells(map, :c)

      assert {:ok, game} = D20.Game.init(Game, %{"sheet" => "dharug"})
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")
      assert {:ok, game} = dispatch(game, "join", "p3")
      assert {:ok, game} = dispatch(game, "start", "p1")

      game =
        game
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:sheet), Access.key!(:trees)],
          c_trees
        )
        |> force_submit_turn(1, 1, 1)

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))
      assert {:ok, game} = dispatch(game, "circle_tree", "p2", submit_tree(1, "a", 0, 0))

      assert {:ok, %Game{phase: :roll} = game} =
               dispatch(game, "circle_tree", "p3", submit_tree(1, "a", 0, 0))

      assert %{tree_lover: :large} = game.players["p1"].badges

      game =
        game
        |> put_in(
          [Access.key!(:players), "p2", Access.key!(:sheet), Access.key!(:trees)],
          c_trees
        )
        |> put_in(
          [Access.key!(:players), "p3", Access.key!(:sheet), Access.key!(:trees)],
          c_trees
        )
        |> force_submit_turn(2, 1, 1)

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 1))
      assert {:ok, game} = dispatch(game, "circle_tree", "p2", submit_tree(1, "a", 0, 1))

      assert {:ok, %Game{phase: :roll} = game} =
               dispatch(game, "circle_tree", "p3", submit_tree(1, "a", 0, 1))

      assert %{tree_lover: :small} = game.players["p2"].badges
      assert %{tree_lover: :small} = game.players["p3"].badges
    end
  end

  describe "turn history" do
    test "stores only accepted adjusted values in order" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 6)

      game = select_shape(game, "p1", "plant_trees", 1, 1, [cell("a", 0, 0), cell("a", 0, 1)])

      assert {:ok, game} = dispatch(game, "submit", "p1", %{"bonus_actions" => []})

      assert [1] = game.players["p1"].turns

      assert game.players["p1"].last_action == %{
               turn: 1,
               action: "plant_trees",
               die_value: 1,
               target_cells: [%{area: :a, row: 0, column: 0}, %{area: :a, row: 0, column: 1}]
             }

      game = force_submit_turn(game, 2, 1, 1)

      assert {:ok, game} = dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 1, 0))

      assert [1, 1] = game.players["p1"].turns

      assert game.players["p1"].last_action == %{
               turn: 2,
               action: "circle_tree",
               die_value: 1,
               target_cells: [%{area: :a, row: 1, column: 0}]
             }
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

    test "does not assign solo ranks to multiplayer scores" do
      assert {:ok, game} = D20.Game.init(Game, %{"sheet" => "dharug"})
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")
      assert {:ok, %Game{mode: :multiplayer} = game} = dispatch(game, "start", "p1")

      game = force_submit_turn(game, 30, 2, 1)

      assert {:ok, %Game{phase: :submit} = game} =
               dispatch(game, "circle_tree", "p1", submit_tree(1, "a", 0, 0))

      assert {:ok,
              %Game{
                phase: :finished,
                mode: :multiplayer,
                scores: %{"p1" => %{rank: nil}, "p2" => %{rank: nil}}
              }} = dispatch(game, "circle_tree", "p2", submit_tree(1, "a", 0, 0))
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
            {id, %{player | status: :pending, selection: nil}}
          end)
    }
  end

  defp select_shape(game, actor_id, action, value, volunteers, [first_cell | cells]) do
    {:ok, game} =
      dispatch(game, "select", actor_id, %{
        "action" => action,
        "die_value" => value,
        "volunteers_used" => volunteers,
        "target_cell" => first_cell
      })

    Enum.reduce(cells, game, fn cell, game ->
      {:ok, game} = dispatch(game, "select", actor_id, %{"target_cell" => cell})
      game
    end)
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
