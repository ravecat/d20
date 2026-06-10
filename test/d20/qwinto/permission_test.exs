defmodule D20.Qwinto.PermissionTest do
  use ExUnit.Case, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Qwinto.Game
  alias D20.Qwinto.Permission
  alias D20.Sessions.Session

  @default_permissions %{
    can_start_game: false,
    can_select_dice: false,
    can_roll: false,
    can_keep: false,
    can_reroll: false,
    can_write_result: false,
    can_pass_result: false,
    can_take_penalty: false
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

    test "lets only the active player select and roll dice during the turn phase" do
      session = session(:turn, order: ["p1", "p2"], cursor: 0)

      assert %{can_select_dice: true, can_roll: true} =
               Permission.permissions(scope("p1"), session)

      assert %{can_select_dice: false, can_roll: false} =
               Permission.permissions(scope("p2"), session)
    end

    test "lets only the active player keep or reroll the first decision roll" do
      session = session(:decision, order: ["p1", "p2"], cursor: 0, attempt: 1)

      assert %{can_keep: true, can_reroll: true} = Permission.permissions(scope("p1"), session)
      assert %{can_keep: false, can_reroll: false} = Permission.permissions(scope("p2"), session)

      session = session(:decision, order: ["p1", "p2"], cursor: 0, attempt: 2)

      assert %{can_keep: false, can_reroll: false} = Permission.permissions(scope("p1"), session)
    end

    test "exposes result permissions for active and non-active ready players" do
      session =
        session(:result,
          order: ["p1", "p2"],
          cursor: 0,
          dices: [:orange],
          sum: 7,
          players: %{"p1" => player(), "p2" => player()}
        )

      assert %{can_write_result: true, can_pass_result: true, can_take_penalty: true} =
               Permission.permissions(scope("p1"), session)

      assert %{can_write_result: true, can_pass_result: true, can_take_penalty: false} =
               Permission.permissions(scope("p2"), session)
    end

    test "keeps penalty independent from legal result writes" do
      session =
        session(:result,
          order: ["p1", "p2"],
          cursor: 0,
          dices: [:orange],
          sum: 7,
          players: %{"p1" => player(%{orange: full_row()}), "p2" => player()}
        )

      assert %{can_write_result: false, can_pass_result: true, can_take_penalty: true} =
               Permission.permissions(scope("p1"), session)
    end

    test "denies result actions for players that already responded" do
      session =
        session(:result, dices: [:orange], sum: 7, players: %{"p1" => player(%{}, :wrote)})

      assert %{can_write_result: false, can_pass_result: false, can_take_penalty: false} =
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
      dices: Keyword.get(opts, :dices, []),
      sum: Keyword.get(opts, :sum),
      attempt: Keyword.get(opts, :attempt, 0)
    }
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
