defmodule D20.Qwinto.PermissionTest do
  use ExUnit.Case, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Qwinto.Game
  alias D20.Qwinto.Permission
  alias D20.Sessions.Session

  @default_permissions %{
    can_start_game: false,
    can_roll: false,
    can_reroll: false,
    can_see_roll: false,
    can_write: false,
    can_pass: false,
    can_penalize: false
  }

  describe "permissions/2" do
    test "returns the complete denied set when the caller cannot act" do
      session = session(:ready, phase: :waiting_for_players, owner_id: "owner")

      assert Permission.permissions(scope("p3"), session) == @default_permissions
    end

    test "lets only the owner start a ready waiting session" do
      session = session(:ready, phase: :waiting_for_players, owner_id: "owner")

      assert %{can_start_game: true} = Permission.permissions(scope("owner"), session)
      assert %{can_start_game: false} = Permission.permissions(scope("p2"), session)
    end

    test "lets only the active player roll dice during the roll phase" do
      session = session(:roll, order: ["p1", "p2"], cursor: 0)

      assert %{can_roll: true} = Permission.permissions(scope("p1"), session)

      assert %{can_roll: false} = Permission.permissions(scope("p2"), session)
    end

    test "exposes rolled result visibility during write/pass and result phases" do
      choice = session(:write_or_pass, order: ["p1", "p2"], cursor: 0, attempt: 1)
      result = session(:result, order: ["p1", "p2"], cursor: 0)
      roll = session(:roll, order: ["p1", "p2"], cursor: 0)
      finished = session(:finished, order: ["p1", "p2"], cursor: 0)

      assert %{can_see_roll: true} = Permission.permissions(scope("p1"), choice)
      assert %{can_see_roll: true} = Permission.permissions(scope("p2"), choice)
      assert %{can_see_roll: true} = Permission.permissions(scope("p1"), result)
      assert %{can_see_roll: false} = Permission.permissions(scope("p1"), roll)
      assert %{can_see_roll: false} = Permission.permissions(scope("p1"), finished)
    end

    test "lets only the active player reroll the first choice roll" do
      session = session(:write_or_pass, order: ["p1", "p2"], cursor: 0, attempt: 1)

      assert %{can_reroll: true} = Permission.permissions(scope("p1"), session)
      assert %{can_reroll: false} = Permission.permissions(scope("p2"), session)

      session = session(:write_or_pass, order: ["p1", "p2"], cursor: 0, attempt: 2)

      assert %{can_reroll: false} = Permission.permissions(scope("p1"), session)
    end

    test "lets active player write or penalize in first choice phase" do
      session =
        session(:write_or_pass,
          order: ["p1", "p2"],
          cursor: 0,
          attempt: 1,
          dices: %{orange: 4},
          sum: 4,
          players: %{"p1" => player(), "p2" => player()}
        )

      assert %{can_write: true, can_penalize: true, can_reroll: true} =
               Permission.permissions(scope("p1"), session)

      assert %{can_write: false, can_penalize: false, can_reroll: false} =
               Permission.permissions(scope("p2"), session)
    end

    test "exposes result permissions by active and passive role" do
      session =
        session(:result,
          order: ["p1", "p2"],
          cursor: 0,
          dices: %{orange: 4},
          sum: 4,
          players: %{"p1" => player(), "p2" => player()}
        )

      assert %{can_write: true, can_pass: false, can_penalize: true} =
               Permission.permissions(scope("p1"), session)

      assert %{can_write: true, can_pass: true, can_penalize: false} =
               Permission.permissions(scope("p2"), session)
    end

    test "keeps penalty independent from legal result writes" do
      session =
        session(:result,
          order: ["p1", "p2"],
          cursor: 0,
          dices: %{orange: 4},
          sum: 4,
          players: %{"p1" => player(%{orange: full_row()}), "p2" => player()}
        )

      assert %{can_write: false, can_pass: false, can_penalize: true} =
               Permission.permissions(scope("p1"), session)
    end

    test "denies result actions for players that already responded" do
      session =
        session(:result, dices: %{orange: 4}, sum: 4, players: %{"p1" => player(%{}, :wrote)})

      assert %{can_write: false, can_pass: false, can_penalize: false} =
               Permission.permissions(scope("p1"), session)
    end
  end

  describe "permit/3" do
    test "returns the normalized Bodyguard result" do
      session = session(:ready, phase: :waiting_for_players, owner_id: "owner")

      assert Permission.permit(:start_game, scope("owner"), session) == :ok
      assert Permission.permit(:start_game, scope("p2"), session) == {:error, :unauthorized}
    end
  end

  defp scope(actor_id) do
    Scope.for_actor(%Actor{id: actor_id, type: :anonymous})
  end

  defp session(game_phase, opts) do
    game_opts = Keyword.drop(opts, [:phase, :owner_id])

    %Session{
      id: Ecto.UUID.generate(),
      phase: Keyword.get(opts, :phase, :in_progress),
      owner_id: Keyword.get(opts, :owner_id, "p1"),
      game: game(game_phase, game_opts)
    }
  end

  defp game(phase, opts) do
    players = Keyword.get(opts, :players, %{"p1" => player(), "p2" => player()})

    %Game{
      phase: phase,
      order: Keyword.get(opts, :order, Map.keys(players)),
      cursor: Keyword.get(opts, :cursor, 0),
      players: players,
      dices: Keyword.get(opts, :dices, %{}),
      sum: Keyword.get(opts, :sum),
      attempt: Keyword.get(opts, :attempt, 0)
    }
  end

  defp player(rows \\ %{}, status \\ :pending) do
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
