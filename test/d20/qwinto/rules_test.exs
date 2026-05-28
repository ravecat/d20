defmodule D20.Qwinto.RulesTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Command
  alias D20.Qwinto.Game
  alias D20.Qwinto.Rules

  describe "validate/2" do
    test "accepts setup and ready commands that satisfy player count constraints" do
      assert :ok = Rules.validate(%Game{phase: :setup}, %Command.Join{player_id: "p1"})

      game = %Game{
        phase: :ready,
        order: ["p1", "p2"],
        players: %{"p1" => player(), "p2" => player()}
      }

      assert Rules.ready_to_start?(game)
      assert :ok = Rules.validate(game, %Command.Join{player_id: "p3"})
      assert :ok = Rules.validate(game, %Command.Start{})
    end

    test "rejects start before ready" do
      game = %Game{phase: :setup, order: ["p1"], players: %{"p1" => player()}}

      refute Rules.ready_to_start?(game)
      assert {:error, :invalid_phase} = Rules.validate(game, %Command.Start{})
    end

    test "rejects a roll from a non-active player" do
      game = %Game{phase: :turn, order: ["p1", "p2"], cursor: 0}

      assert {:error, :not_active_player} =
               Rules.validate(game, %Command.Roll{player_id: "p2", colors: [:orange]})
    end

    test "validates keep and reroll through the same decision preconditions" do
      game = %Game{phase: :decision, order: ["p1", "p2"], cursor: 0, attempt: 1}

      assert :ok = Rules.validate(game, %Command.Keep{player_id: "p1"})
      assert :ok = Rules.validate(game, %Command.Reroll{player_id: "p1"})
    end

    test "rejects duplicate values in a write column" do
      game = %Game{
        phase: :result,
        dices: [:orange],
        sum: 7,
        players: %{"p1" => player(%{yellow: %{2 => 7}})}
      }

      assert {:error, :column_duplicate} =
               Rules.validate(game, %Command.Write{player_id: "p1", row: :orange, slot: 1})
    end

    test "does not compare cells that only shared the old unshifted column index" do
      game = %Game{
        phase: :result,
        dices: [:orange],
        sum: 7,
        players: %{"p1" => player(%{yellow: %{1 => 7}})}
      }

      assert :ok = Rules.validate(game, %Command.Write{player_id: "p1", row: :orange, slot: 1})
    end

    test "accepts writes in single-cell edge columns" do
      game = %Game{phase: :result, dices: [:orange], sum: 7, players: %{"p1" => player()}}

      assert :ok = Rules.validate(game, %Command.Write{player_id: "p1", row: :orange, slot: 8})
    end

    test "rejects a player that already responded" do
      game = %Game{phase: :result, players: %{"p1" => player(%{}, :wrote)}}

      assert {:error, :already_responded} = Rules.validate(game, %Command.Skip{player_id: "p1"})
    end
  end

  defp player(rows \\ %{}, status \\ :ready) do
    %{
      rows: %{
        orange: Map.get(rows, :orange, %{}),
        yellow: Map.get(rows, :yellow, %{}),
        purple: Map.get(rows, :purple, %{})
      },
      penalties: 0,
      status: status
    }
  end
end
