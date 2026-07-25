defmodule D20.Qwinto.GameTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Game

  describe "D20.Game behaviour" do
    test "identifies the active player from order and cursor" do
      game = %Game{order: ["p1", "p2"], cursor: 1}

      assert Game.active_player?(game, "p2")
      refute Game.active_player?(game, "p1")
    end

    test "encodes the full game state as JSON" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, game} = dispatch(game, "join", "p1")
      assert {:ok, game} = dispatch(game, "join", "p2")
      assert {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "write", "p1", %{"row" => "orange", "slot" => 0})

      decoded = game |> Jason.encode!() |> Jason.decode!()

      assert decoded["phase"] == "result"
      assert decoded["order"] == ["p1", "p2"]
      assert decoded["cursor"] == 0
      assert decoded["dices"] == %{"orange" => game.dices.orange}
      assert decoded["sum"] == game.sum
      assert decoded["attempt"] == 1
      assert decoded["scores"] == %{}
      assert decoded["players"]["p1"]["status"] == "wrote"
      assert decoded["players"]["p2"]["status"] == "pending"
      assert decoded["players"]["p1"]["rows"]["orange"]["0"] == game.sum
    end

    test "moves from setup to ready at the minimum player count, then starts" do
      assert {:ok, %Game{phase: :setup} = game} = D20.Game.init(Game)

      assert {:ok, %Game{phase: :setup, order: ["p1"]} = game} = dispatch(game, "join", "p1")
      assert game.players["p1"].status == :idle

      assert {:ok, %Game{phase: :ready, order: ["p1", "p2"]} = game} =
               dispatch(game, "join", "p2")

      assert {:ok, %Game{phase: :roll, order: ["p1", "p2"], cursor: 0} = game} =
               dispatch(game, "start", "p1")

      assert game.players["p1"].status == :pending
      assert game.players["p2"].status == :idle
      assert {:ok, ^game} = dispatch(game, "join", "p1")
      assert {:ok, ^game} = dispatch(game, "join", "p3")
    end

    test "rejects start before the game is ready" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, %Game{phase: :setup} = game} = dispatch(game, "join", "p1")

      assert {:error, :invalid_phase} = dispatch(game, "start", "p1")
    end

    test "accepts additional players while ready until max player count" do
      assert {:ok, game} = D20.Game.init(Game)
      assert {:ok, %Game{phase: :setup} = game} = dispatch(game, "join", "p1")
      assert {:ok, %Game{phase: :ready} = game} = dispatch(game, "join", "p2")
      assert {:ok, %Game{phase: :ready} = game} = dispatch(game, "join", "p3")
      assert {:ok, %Game{phase: :ready} = game} = dispatch(game, "join", "p4")

      assert {:error, :invalid_player_count} = dispatch(game, "join", "p5")
      assert game.order == ["p1", "p2", "p3", "p4"]
    end
  end

  describe "dispatch/2" do
    test "active player rolls server dice and chooses how to resolve the result" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, %Game{phase: :write_or_pass, attempt: 1} = game} =
               dispatch(game, "roll", "p1", %{"colors" => ["orange", "purple"]})

      rolled_values = Map.values(game.dices)

      assert MapSet.new(Map.keys(game.dices)) == MapSet.new([:orange, :purple])
      assert length(rolled_values) == 2
      assert Enum.all?(rolled_values, &(&1 in 1..6))
      assert game.sum == Enum.sum(rolled_values)
      assert game.players["p1"].status == :pending
      assert game.players["p2"].status == :idle
      assert game.scores == %{}
    end

    test "roll marks the active player pending for existing roll snapshots" do
      game = %Game{
        phase: :roll,
        order: ["p1", "p2"],
        cursor: 0,
        players: %{"p1" => player(:idle), "p2" => player(:idle)}
      }

      assert {:ok, %Game{phase: :write_or_pass} = game} =
               dispatch(game, "roll", "p1", %{"colors" => ["orange"]})

      assert game.players["p1"].status == :pending
      assert game.players["p2"].status == :idle
    end

    test "rejects malformed attrs before applying game rules" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:error, %Ecto.Changeset{} = changeset} =
               dispatch(game, "roll", "p1", %{"colors" => ["orange", "orange"]})

      refute changeset.valid?
    end

    test "rejects commands outside their matching phases" do
      {:ok, game} = D20.Game.init(Game)

      assert {:error, :invalid_phase} = dispatch(game, "roll", "p1")

      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:error, :invalid_phase} = dispatch(game, "start", "p1")
      assert {:error, :invalid_phase} = dispatch(game, "write", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})

      assert game.phase == :write_or_pass
      assert {:error, %Ecto.Changeset{}} = dispatch(game, "write", "p1")
      assert {:error, :invalid_phase} = dispatch(game, "pass", "p1")
      assert {:error, :invalid_phase} = dispatch(game, "roll", "p1")
    end

    test "rejects non-active player roll without changing game state" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:error, :not_active_player} =
               dispatch(game, "roll", "p2", %{"colors" => ["orange"]})

      assert game.phase == :roll
      assert game.cursor == 0
    end

    test "players write or pass once, then turn advances" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "write", "p1", %{"row" => "orange", "slot" => 0})

      assert game.players["p1"].rows.orange[0] == game.sum
      assert game.players["p1"].status == :wrote
      assert game.players["p2"].status == :pending
      assert game.phase == :result

      assert {:ok, game} = dispatch(game, "pass", "p2")
      assert game.phase == :roll
      assert game.cursor == 1
      assert game.dices == %{}
      assert game.sum == nil
      assert game.attempt == 0
      assert game.players["p1"].status == :idle
      assert game.players["p2"].status == :pending
    end

    test "active player can write immediately from write/pass and opens result" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "write", "p1", %{"row" => "orange", "slot" => 0})

      assert game.phase == :result
      assert game.players["p1"].rows.orange[0] == game.sum
      assert game.players["p1"].status == :wrote
      assert game.players["p2"].status == :pending

      assert {:ok, game} = dispatch(game, "pass", "p2")
      assert game.phase == :roll
      assert game.cursor == 1
    end

    test "active player can cancel from write/pass and opens result with penalty" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "penalize", "p1")

      assert game.phase == :result
      assert game.players["p1"].penalties == 1
      assert game.players["p1"].status == :skipped
      assert game.players["p2"].status == :pending
    end

    test "active player can take a penalty instead of writing the final result" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "reroll", "p1")
      assert {:ok, game} = dispatch(game, "penalize", "p1")

      assert game.phase == :result
      assert game.players["p1"].penalties == 1
      assert game.players["p1"].status == :skipped
      assert game.players["p2"].status == :pending
      assert game.players["p2"].penalties == 0
    end

    test "pass marks only passive players skipped without penalty" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "join", "p3")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "write", "p1", %{"row" => "orange", "slot" => 0})
      assert {:ok, game} = dispatch(game, "pass", "p2")

      assert game.phase == :result
      assert game.players["p2"].penalties == 0
      assert game.players["p2"].status == :skipped
      assert game.players["p3"].status == :pending

      assert {:ok, game} = dispatch(game, "pass", "p3")
      assert game.phase == :roll
      assert game.cursor == 1
    end

    test "active player can reroll once with the same dice before result opens" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["yellow", "purple"]})

      assert game.phase == :write_or_pass
      assert game.attempt == 1
      assert MapSet.new(Map.keys(game.dices)) == MapSet.new([:yellow, :purple])

      assert {:ok, game} = dispatch(game, "reroll", "p1")

      assert game.phase == :result
      assert game.attempt == 2
      assert game.players["p1"].status == :pending
      assert game.players["p2"].status == :pending
      rolled_values = Map.values(game.dices)

      assert MapSet.new(Map.keys(game.dices)) == MapSet.new([:yellow, :purple])
      assert length(rolled_values) == 2
      assert game.sum == Enum.sum(rolled_values)
    end

    test "rejects writes outside the rolled rows without changing game state" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})

      assert {:error, :invalid_slot} =
               dispatch(game, "write", "p1", %{"row" => "yellow", "slot" => 0})

      assert game.players["p1"].rows.yellow == %{}
    end

    test "rejects row order violations and column duplicates" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange", "yellow"]})

      game =
        put_in(game, [Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:orange)], %{
          4 => game.sum
        })

      assert {:error, :invalid_row_order} =
               dispatch(game, "write", "p1", %{"row" => "orange", "slot" => 5})

      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange", "yellow"]})

      game =
        put_in(game, [Access.key!(:players), "p1", Access.key!(:rows), Access.key!(:yellow)], %{
          2 => game.sum
        })

      assert {:error, :column_duplicate} =
               dispatch(game, "write", "p1", %{"row" => "orange", "slot" => 1})
    end

    test "finishes after the turn containing the active player's fourth penalty is resolved" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      game = put_in(game.players["p1"].penalties, 3)

      assert game.scores == %{}

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "penalize", "p1")
      assert game.players["p1"].penalties == 4
      assert game.phase == :result
      assert game.scores == %{}

      assert {:ok, game} = dispatch(game, "pass", "p2")
      assert game.phase == :finished
      assert map_size(game.scores) == 2
      assert game.scores["p1"].penalties == -20
      assert {:error, :finished} = dispatch(game, "join", "p3")
      assert {:error, :finished} = dispatch(game, "left", "p1")
      assert {:error, :finished} = dispatch(game, "roll", "p1")
    end

    test "finishes after the turn where any player completes a second colored row" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["yellow"]})
      orange_row = 0..8 |> Enum.map(&{&1, game.sum + 20 + &1}) |> Map.new()

      yellow_row = 1..8 |> Enum.map(&{&1, game.sum + &1}) |> Map.new()

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

      assert {:ok, game} = dispatch(game, "write", "p1", %{"row" => "yellow", "slot" => 0})

      assert game.phase == :result
      assert game.scores == %{}

      assert {:ok, game} = dispatch(game, "pass", "p2")
      assert game.phase == :finished
      assert map_size(game.scores) == 2
    end
  end

  describe "finished?/1" do
    test "reports whether the internal game state is terminal" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

      refute Game.finished?(game)

      game = put_in(game.players["p1"].penalties, 3)

      assert {:ok, game} = dispatch(game, "roll", "p1", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "penalize", "p1")
      assert {:ok, game} = dispatch(game, "pass", "p2")

      assert Game.finished?(game)
    end
  end

  describe "scores" do
    test "stores row, bonus, penalty, and total scores in finished game state" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "join", "p2")
      {:ok, game} = dispatch(game, "start", "p1")

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
          status: :idle
        })
        |> put_in([Access.key!(:players), "p2", Access.key!(:status)], :pending)
        |> put_in([Access.key!(:players), "p2", Access.key!(:penalties)], 3)

      assert {:ok, game} = dispatch(game, "roll", "p2", %{"colors" => ["orange"]})
      assert {:ok, game} = dispatch(game, "penalize", "p2")
      assert game.phase == :result
      assert game.scores == %{}

      assert {:ok, game} = dispatch(game, "pass", "p1")
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

  defp dispatch(game, event, actor_id, attrs \\ %{}) do
    Game.dispatch(game, %D20.Command{event: event, actor_id: actor_id, attrs: attrs})
  end

  defp player(status) do
    %{rows: %{orange: %{}, yellow: %{}, purple: %{}}, penalties: 0, status: status}
  end
end
