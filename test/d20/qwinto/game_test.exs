defmodule D20.Qwinto.GameTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Game

  describe "D20.Game behaviour" do
    test "accumulates players before start" do
      assert {:ok, %Game{phase: :setup} = game} = Game.init()

      assert {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      assert {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})

      assert {:ok,
              %Game{phase: :waiting_for_roll, active_player_id: "p1", order: ["p1", "p2"]} =
                game} =
               Game.dispatch(game, :start, %{"player_id" => "p1"})

      assert {:ok, ^game} = Game.dispatch(game, :join, %{player_id: "p1"})
      assert {:ok, ^game} = Game.dispatch(game, :join, %{player_id: "p3"})
    end

    test "validates player count on start" do
      assert {:ok, game} = Game.init()
      assert {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      assert {:error, :invalid_player_count} = Game.dispatch(game, :start, %{})

      assert {:ok, game} = Game.init()
      assert {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      assert {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      assert {:ok, game} = Game.dispatch(game, :join, %{player_id: "p3"})
      assert {:ok, game} = Game.dispatch(game, :join, %{player_id: "p4"})
      assert {:ok, game} = Game.dispatch(game, :join, %{player_id: "p5"})
      assert {:error, :invalid_player_count} = Game.dispatch(game, :start, %{})
    end
  end

  describe "dispatch/3" do
    test "active player rolls and opens entries" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, %Game{phase: :accepting_entries, roll: %{sum: 9}} = game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "purple"],
                 "values" => [4, 5]
               })

      assert game.players["p1"].responded == false
      assert game.players["p2"].responded == false
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
                 "colors" => ["orange"],
                 "values" => [4]
               })

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
                 "colors" => ["orange"],
                 "values" => [4]
               })

      assert game.phase == :waiting_for_roll
      assert game.active_player_id == "p1"
    end

    test "players write or skip once, then turn advances" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"],
                 "values" => [4]
               })

      assert {:ok, game} =
               Game.dispatch(game, :write, %{
                 "player_id" => "p1",
                 "row" => "orange",
                 "slot" => 0
               })

      assert game.players["p1"].rows.orange[0] == 4
      assert game.players["p1"].responded == true
      assert game.phase == :accepting_entries

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})
      assert game.phase == :waiting_for_roll
      assert game.active_player_id == "p2"
      assert game.roll == nil
    end

    test "active player receives a penalty when skipping" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"],
                 "values" => [4]
               })

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p1"})
      assert game.players["p1"].penalties == 1
      assert game.players["p2"].penalties == 0
    end

    test "rejects writes outside the rolled rows without changing game state" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange"],
                 "values" => [4]
               })

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

      game =
        game
        |> put_in([Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:orange)], %{
          4 => 8
        })
        |> put_in([Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:yellow)], %{
          1 => 9
        })

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "yellow"],
                 "values" => [3, 4]
               })

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

      game =
        put_in(
          game,
          [Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:yellow)],
          %{1 => 9}
        )

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "yellow"],
                 "values" => [4, 5]
               })

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
                 "colors" => ["orange"],
                 "values" => [4]
               })

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p1"})
      assert game.players["p1"].penalties == 4
      assert game.phase == :accepting_entries
      assert game.scores == %{}

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})
      assert game.phase == :finished
      assert map_size(game.scores) == 2
      assert game.scores["p1"].penalties == -20
      assert [%{player_id: "p2"}, %{player_id: "p1"}] = Game.scoreboard(game)
    end

    test "finishes after the turn where any player completes a second colored row" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      game =
        game
        |> put_in([Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:orange)], %{
          0 => 1,
          1 => 2,
          2 => 3,
          3 => 4,
          4 => 5,
          5 => 6,
          6 => 7,
          7 => 8,
          8 => 10
        })
        |> put_in([Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:yellow)], %{
          0 => 1,
          1 => 2,
          2 => 3,
          3 => 4,
          4 => 5,
          5 => 6,
          6 => 7,
          7 => 8
        })

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p1",
                 "colors" => ["yellow", "orange"],
                 "values" => [4, 5]
               })

      assert {:ok, game} =
               Game.dispatch(game, :write, %{
                 "player_id" => "p1",
                 "row" => "yellow",
                 "slot" => 8
               })

      assert game.phase == :accepting_entries
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
                 "colors" => ["orange"],
                 "values" => [4]
               })

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p1"})
      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})

      assert Game.finished?(game)
    end
  end

  describe "scoreboard/1" do
    test "returns empty standings before finish" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      assert Game.scoreboard(game) == []
    end

    test "stores row, bonus, penalty, and total scores in finished game state" do
      {:ok, game} = Game.init()
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p1"})
      {:ok, game} = Game.dispatch(game, :join, %{player_id: "p2"})
      {:ok, game} = Game.dispatch(game, :start, %{})

      game =
        game
        |> put_in([Access.key!(:active_player_id)], "p2")
        |> put_in([Access.key!(:players), "p1"], %{
          rows: %{
            orange: %{0 => 1, 1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 7, 7 => 8, 8 => 9},
            yellow: %{1 => 3},
            purple: %{0 => 1}
          },
          penalties: 1,
          responded: false
        })
        |> put_in([Access.key!(:players), "p2", Access.key!(:penalties)], 3)

      assert {:ok, game} =
               Game.dispatch(game, :roll, %{
                 "player_id" => "p2",
                 "colors" => ["orange"],
                 "values" => [4]
               })

      assert {:ok, game} = Game.dispatch(game, :skip, %{"player_id" => "p2"})
      assert game.phase == :accepting_entries
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

      assert [%{player_id: "p1"}, %{player_id: "p2"}] = Game.scoreboard(game)
    end
  end
end
