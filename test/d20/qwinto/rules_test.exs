defmodule D20.Qwinto.RulesTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Game
  alias D20.Qwinto.Rules

  describe "validate/2" do
    test "accepts setup and ready commands that satisfy player count constraints" do
      assert :ok = Rules.validate(%Game{phase: :setup}, command("join", "p1"))

      game = %Game{
        phase: :ready,
        order: ["p1", "p2"],
        players: %{"p1" => player(), "p2" => player()}
      }

      assert Rules.ready_to_start?(game)
      assert :ok = Rules.validate(game, command("join", "p3"))
      assert :ok = Rules.validate(game, command("start", "p1"))
    end

    test "rejects start before ready" do
      game = %Game{phase: :setup, order: ["p1"], players: %{"p1" => player()}}

      refute Rules.ready_to_start?(game)
      assert {:error, :invalid_phase} = Rules.validate(game, command("start", "p1"))
    end

    test "rejects a roll from a non-active player" do
      game = %Game{phase: :roll, order: ["p1", "p2"], cursor: 0}

      assert {:error, :not_active_player} =
               Rules.validate(game, command("roll", "p2", %{colors: [:orange]}))
    end

    test "validates reroll through write/pass preconditions" do
      game = %Game{phase: :write_or_pass, order: ["p1", "p2"], cursor: 0, attempt: 1}

      assert :ok = Rules.validate(game, command("reroll", "p1"))
    end

    test "allows only the active player to write during write/pass" do
      game = %Game{
        phase: :write_or_pass,
        order: ["p1", "p2"],
        cursor: 0,
        dices: %{orange: 4},
        sum: 4,
        players: %{"p1" => player(), "p2" => player()}
      }

      assert :ok = Rules.validate(game, command("write", "p1", %{row: :orange, slot: 0}))

      assert {:error, :not_active_player} =
               Rules.validate(game, command("write", "p2", %{row: :orange, slot: 0}))
    end

    test "rejects duplicate values in a write column" do
      game = %Game{
        phase: :result,
        dices: %{orange: 4},
        sum: 4,
        players: %{"p1" => player(%{yellow: %{2 => 4}})}
      }

      assert {:error, :column_duplicate} =
               Rules.validate(game, command("write", "p1", %{row: :orange, slot: 1}))
    end

    test "does not compare cells that only shared the old unshifted column index" do
      game = %Game{
        phase: :result,
        dices: %{orange: 4},
        sum: 4,
        players: %{"p1" => player(%{yellow: %{1 => 4}})}
      }

      assert :ok = Rules.validate(game, command("write", "p1", %{row: :orange, slot: 1}))
    end

    test "accepts writes in single-cell edge columns" do
      game = %Game{phase: :result, dices: %{orange: 4}, sum: 4, players: %{"p1" => player()}}

      assert :ok = Rules.validate(game, command("write", "p1", %{row: :orange, slot: 8}))
    end

    test "allows ready players to pass and only active players to penalize" do
      game = %Game{
        phase: :result,
        order: ["p1", "p2"],
        cursor: 0,
        dices: %{orange: 4},
        sum: 4,
        players: %{"p1" => player(), "p2" => player()}
      }

      assert :ok = Rules.validate(game, command("pass", "p1"))
      assert :ok = Rules.validate(game, command("pass", "p2"))
      assert :ok = Rules.validate(game, command("penalize", "p1"))

      assert {:error, :not_active_player} = Rules.validate(game, command("penalize", "p2"))

      game = %{game | phase: :write_or_pass}

      assert :ok = Rules.validate(game, command("penalize", "p1"))
      assert {:error, :not_active_player} = Rules.validate(game, command("penalize", "p2"))
    end

    test "reports whether a legal write action is available now" do
      game = %Game{phase: :result, dices: %{orange: 4}, sum: 4, players: %{"p1" => player()}}

      assert Rules.write_allowed?(game, "p1")

      game = %Game{
        phase: :result,
        dices: %{orange: 4},
        sum: 4,
        players: %{"p1" => player(%{orange: full_row()})}
      }

      refute Rules.write_allowed?(game, "p1")

      game = %Game{
        phase: :write_or_pass,
        order: ["p1", "p2"],
        cursor: 0,
        dices: %{orange: 4},
        sum: 4,
        players: %{"p1" => player(), "p2" => player()}
      }

      assert Rules.write_allowed?(game, "p1")
      refute Rules.write_allowed?(game, "p2")
    end

    test "lists available slots for the current rolled rows" do
      game = %Game{
        phase: :write_or_pass,
        attempt: 1,
        dices: %{orange: 4, purple: 1},
        sum: 5,
        players: %{"p1" => player()}
      }

      assert %{row: :orange, slot: 0} in Rules.available_slots(game, "p1")
      assert %{row: :purple, slot: 8} in Rules.available_slots(game, "p1")
      refute Enum.any?(Rules.available_slots(game, "p1"), &(&1.row == :yellow))

      game = %{game | phase: :result, attempt: 1}

      assert %{row: :orange, slot: 0} in Rules.available_slots(game, "p1")
      assert %{row: :purple, slot: 8} in Rules.available_slots(game, "p1")

      game = %{game | attempt: 2}

      assert %{row: :orange, slot: 0} in Rules.available_slots(game, "p1")
      assert %{row: :purple, slot: 8} in Rules.available_slots(game, "p1")

      game = %{game | phase: :roll, attempt: 0}

      assert Rules.available_slots(game, "p1") == []
    end

    test "available slots preserve occupancy, row order, and column uniqueness" do
      game = %Game{
        phase: :write_or_pass,
        dices: %{orange: 4},
        sum: 4,
        players: %{"p1" => player(%{orange: %{0 => 1, 2 => 4, 4 => 4}, yellow: %{2 => 4}})}
      }

      available_slots = Rules.available_slots(game, "p1")

      refute %{row: :orange, slot: 0} in available_slots
      refute %{row: :orange, slot: 1} in available_slots
      refute %{row: :orange, slot: 3} in available_slots
      refute %{row: :orange, slot: 5} in available_slots
    end

    test "rejects a player that already responded" do
      game = %Game{phase: :result, dices: %{orange: 4}, players: %{"p1" => player(%{}, :wrote)}}

      assert {:error, :already_responded} =
               Rules.validate(game, command("write", "p1", %{row: :orange, slot: 0}))

      assert {:error, :already_responded} = Rules.validate(game, command("pass", "p1"))
      assert {:error, :already_responded} = Rules.validate(game, command("penalize", "p1"))
    end
  end

  defp command(event, actor_id, attrs \\ %{}) do
    %D20.Command{event: event, actor_id: actor_id, attrs: attrs}
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

  defp full_row do
    0..8 |> Enum.map(&{&1, &1 + 1}) |> Map.new()
  end
end
