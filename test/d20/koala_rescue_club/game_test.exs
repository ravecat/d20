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
      assert decoded["roll_due_at"] == nil
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
               dispatch(game, "roll", "p1")

      assert game.players["p1"].status == :pending
      assert game.players["p2"].status == :pending

      assert {:ok, %Game{phase: :submit} = game} =
               dispatch(game, "circle_tree", "p1", submit_tree(value, "a", 0, 0))

      assert game.players["p1"].status == :submitted
      assert game.players["p1"].sheet.trees == [%{area: :a, row: 0, column: 0}]

      assert {:ok, %Game{phase: :roll, turn: 2, roll: nil} = game} =
               dispatch(game, "circle_tree", "p2", submit_tree(value, "a", 0, 0))

      assert game.players["p1"].status == :ready
      assert game.players["p2"].status == :ready
    end

    test "validates shape placement and koala prerequisites" do
      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:ok, %Game{} = game} =
               dispatch(game, "plant_trees", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cells" => [cell("a", 0, 0), cell("a", 0, 1)]
               })

      assert %{area: :a, row: 0, column: 0} in game.players["p1"].sheet.trees
      assert %{area: :a, row: 0, column: 1} in game.players["p1"].sheet.trees

      game = "dharug" |> started_game() |> force_submit_turn(1, 1, 1)

      assert {:error, :koala_requires_tree} =
               dispatch(game, "rehome_koalas", "p1", %{
                 "die_value" => 1,
                 "volunteers_used" => 0,
                 "target_cells" => [cell("a", 0, 0), cell("a", 0, 1)]
               })
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
