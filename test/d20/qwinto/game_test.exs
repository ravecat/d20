defmodule D20.Qwinto.GameTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Game

  describe "D20.Game behaviour" do
    test "moves from setup to ready at the minimum player count, then starts" do
      assert {:ok, %Game{phase: :setup} = game} = Game.init()

      assert {:ok, %Game{phase: :setup, order: ["p1"]} = game} =
               Game.dispatch(game, :join, %{player_id: "p1"})

      assert {:ok, %Game{phase: :ready, order: ["p1", "p2"]} = game} =
               Game.dispatch(game, :join, %{player_id: "p2"})

      assert {:ok, %Game{phase: :turn, order: ["p1", "p2"], cursor: 0} = game} =
               Game.dispatch(game, :start, %{"player_id" => "p1"})

      assert {:ok, ^game} = Game.dispatch(game, :join, %{player_id: "p1"})
      assert {:ok, ^game} = Game.dispatch(game, :join, %{player_id: "p3"})
    end

    test "rejects start before the game is ready" do
      assert {:ok, game} = Game.init()
      assert {:ok, %Game{phase: :setup} = game} = Game.dispatch(game, :join, %{player_id: "p1"})

      assert {:error, :invalid_phase} = Game.dispatch(game, :start, %{})
    end

    test "accepts additional players while ready until max player count" do
      assert {:ok, game} = Game.init()
      assert {:ok, %Game{phase: :setup} = game} = Game.dispatch(game, :join, %{player_id: "p1"})
      assert {:ok, %Game{phase: :ready} = game} = Game.dispatch(game, :join, %{player_id: "p2"})
      assert {:ok, %Game{phase: :ready} = game} = Game.dispatch(game, :join, %{player_id: "p3"})
      assert {:ok, %Game{phase: :ready} = game} = Game.dispatch(game, :join, %{player_id: "p4"})

      assert {:error, :invalid_player_count} = Game.dispatch(game, :join, %{player_id: "p5"})
      assert game.order == ["p1", "p2", "p3", "p4"]
    end
  end

  describe "dispatch/3" do
    test "active player rolls server dice and decides whether to keep the result" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, %Game{phase: :decision, attempt: 1} = game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "purple"]
               })

      assert game.dice == [:orange, :purple]
      assert length(game.values) == 2
      assert Enum.all?(game.values, &(&1 in 1..6))
      assert game.sum == Enum.sum(game.values)
      assert game.players["p1"].status == :ready
      assert game.players["p2"].status == :ready
      assert game.scores == %{}
    end

    test "rejects malformed attrs before applying game rules" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:error, %Ecto.Changeset{} = changeset} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "orange"],
                 "values" => [4]
               })

      refute changeset.valid?
    end

    test "rejects commands outside their matching phases" do
      {:ok, game} = Game.init()

      assert {:error, :invalid_phase} = Game.dispatch(game, :roll, %{})

      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:error, :invalid_phase} = Game.dispatch(game, :start, %{})
      assert {:error, :invalid_phase} = Game.dispatch(game, :write, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"]
               })

      assert game.phase == :decision
      assert {:error, :invalid_phase} = Game.dispatch(game, :write, %{})
      assert {:error, :invalid_phase} = Game.dispatch(game, :skip, %{})
      assert {:error, :invalid_phase} = Game.dispatch(game, :roll, %{})
    end

    test "rejects non-active player roll without changing game state" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:error, :not_active_player} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p2",
                 "colors" => ["orange"]
               })

      assert game.phase == :turn
      assert game.cursor == 0
    end

    test "players write or skip once, then turn advances" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"]
               })

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p1"})

      assert {:ok, game} =
               Game.dispatch(game, :write, %{
                 "player_id" => "p1",
                 "row" => "orange",
                 "slot" => 0
               })

      assert game.players["p1"].rows.orange[0] == game.sum
      assert game.players["p1"].status == :wrote
      assert game.phase == :result

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})
      assert game.phase == :turn
      assert game.cursor == 1
      assert game.dice == []
      assert game.values == []
      assert game.sum == nil
      assert game.attempt == 0
    end

    test "active player receives a penalty only when skipping final result" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"]
               })

      assert {:error, :invalid_phase} = Game.dispatch(game, :skip, %{"player_id" => "p1"})

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p1"})
      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p1"})
      assert game.players["p1"].penalties == 1
      assert game.players["p1"].status == :failed
      assert game.players["p2"].penalties == 0
    end

    test "active player can reroll once with the same dice before result opens" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["yellow", "purple"]
               })

      assert game.phase == :decision
      assert game.attempt == 1
      assert game.dice == [:yellow, :purple]

      assert {:ok, game} = Game.dispatch(game, :reroll, %{"player_id" => "p1"})

      assert game.phase == :result
      assert game.attempt == 2
      assert game.dice == [:yellow, :purple]
      assert length(game.values) == 2
      assert game.sum == Enum.sum(game.values)
    end

    test "rejects writes outside the rolled rows without changing game state" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"]
               })

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p1"})

      assert {:error, :row_not_in_roll} =
               Game.dispatch(game, :write, %{
                 "player_id" => "p1",
                 "row" => "yellow",
                 "slot" => 0
               })

      assert game.players["p1"].rows.yellow == %{}
    end

    test "rejects row order violations and column duplicates" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "yellow"]
               })

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p1"})

      game =
        put_in(
          game,
          [Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:orange)],
          %{4 => game.sum}
        )

      assert {:error, :row_order} =
               Game.dispatch(game, :write, %{
                 "player_id" => "p1",
                 "row" => "orange",
                 "slot" => 5
               })

      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "yellow"]
               })

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p1"})

      game =
        put_in(
          game,
          [Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:yellow)],
          %{2 => game.sum}
        )

      assert {:error, :column_duplicate} =
               Game.dispatch(game, :write, %{
                 "player_id" => "p1",
                 "row" => "orange",
                 "slot" => 1
               })
    end

    test "finishes after the turn containing the active player's fourth penalty is resolved" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      game = put_in(game.players["p1"].penalties, 3)

      assert game.scores == %{}

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"]
               })

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p1"})
      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p1"})
      assert game.players["p1"].penalties == 4
      assert game.phase == :result
      assert game.scores == %{}

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})
      assert game.phase == :finished
      assert map_size(game.scores) == 2
      assert game.scores["p1"].penalties == -20
    end

    test "finishes after the turn where any player completes a second colored row" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["yellow"]
               })

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p1"})

      orange_row =
        0..8
        |> Enum.map(&{&1, game.sum + 20 + &1})
        |> Map.new()

      yellow_row =
        1..8
        |> Enum.map(&{&1, game.sum + &1})
        |> Map.new()

      game =
        game
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:orange)],
          orange_row
        )
        |> put_in(
          [Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:yellow)],
          yellow_row
        )

      assert {:ok, game} =
               Game.dispatch(game, :write, %{
                 "player_id" => "p1",
                 "row" => "yellow",
                 "slot" => 0
               })

      assert game.phase == :result
      assert game.scores == %{}

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})
      assert game.phase == :finished
      assert map_size(game.scores) == 2
    end
  end

  describe "finished?/1" do
    test "reports whether the internal game state is terminal" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      refute Game.finished?(game)

      game = put_in(game.players["p1"].penalties, 3)

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"]
               })

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p1"})
      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p1"})
      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})

      assert Game.finished?(game)
    end
  end

  describe "scores" do
    test "stores row, bonus, penalty, and total scores in finished game state" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      game =
        game
        |> put_in([Access.key!(:cursor)], 1)
        |> put_in([Access.key!(:players), "p1"], %{
          rows: %{
            orange: %{0 => 1, 1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 7, 7 => 8, 8 => 9},
            yellow: %{2 => 3},
            purple: %{3 => 1}
          },
          penalties: 1,
          status: :ready
        })
        |> put_in([Access.key!(:players), "p2", Access.key!(:penalties)], 3)

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p2",
                 "colors" => ["orange"]
               })

      assert {:ok, game} = Game.dispatch(game, :keep, %{"player_id" => "p2"})
      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})
      assert game.phase == :result
      assert game.scores == %{}

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p1"})
      assert game.phase == :finished

      assert game.scores["p1"] == %{
               player_id: "p1",
               rows: %{orange: 9, yellow: 1, purple: 1},
               bonuses: 2,
               penalties: -5,
               total: 8
             }
    end
  end
end
