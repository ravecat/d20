defmodule D20.NextStationLondon.PermissionTest do
  use ExUnit.Case, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Permission
  alias D20.Sessions.Session

  @denied %{can_start_game: false, can_draw: false, can_pass: false}

  test "lets only the joined owner start an eligible setup session" do
    ready = session(:waiting_for_players, ready_game())

    assert %{can_start_game: true} = Permission.permissions(scope("owner"), ready)
    assert Permission.permissions(scope("p2"), ready) == @denied

    not_joined = %{ready | game: %Game{phase: :setup}}
    assert Permission.permissions(scope("owner"), not_joined) == @denied
  end

  test "lets only pending frozen players draw or pass during turn" do
    game = build_game()
    session = session(:in_progress, game)

    assert %{can_draw: true, can_pass: true} = Permission.permissions(scope("owner"), session)

    submitted = put_in(session.game.players["owner"].status, :submitted)
    assert Permission.permissions(scope("owner"), submitted) == @denied
    assert Permission.permissions(scope("spectator"), session) == @denied
  end

  test "denies mutation during reveal and after finish" do
    revealing = session(:in_progress, %{ready_game() | phase: :reveal, round: 1})
    finished = session(:finished, %{build_game() | phase: :finished})

    assert Permission.permissions(scope("owner"), revealing) == @denied
    assert Permission.permissions(scope("owner"), finished) == @denied
  end

  test "returns normalized Bodyguard results" do
    session = session(:waiting_for_players, ready_game())

    assert Permission.permit(:start_game, scope("owner"), session) == :ok
    assert Permission.permit(:start_game, scope("p2"), session) == {:error, :unauthorized}
  end

  defp ready_game do
    %Game{phase: :setup, players: %{"owner" => Game.initial_player()}}
  end

  defp build_game do
    player = %{Game.initial_player() | status: :pending, pencil_offset: 0}

    %Game{
      phase: :turn,
      round: 1,
      pencil_cycle: [:green, :blue, :pink, :purple],
      players: %{"owner" => player},
      draws: [%{cards: ["street_square"]}]
    }
  end

  defp session(phase, game) do
    %Session{id: "session-1", phase: phase, owner_id: "owner", members: %{}, game: game}
  end

  defp scope(actor_id) do
    Scope.for_actor(%Actor{id: actor_id, type: :anonymous})
  end
end
