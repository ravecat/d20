defmodule D20.KoalaRescueClub.ServerTest do
  use D20.DataCase, async: false

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset
  alias D20.KoalaRescueClub.Server
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.SessionChannel

  setup do
    assert {:ok, %Session{} = session} =
             Sessions.create("koala-rescue-club", Game, "owner", %{"sheet" => "dharug"})

    on_exit(fn -> Sessions.stop(session.id) end)

    assert [{pid, Server}] = Registry.lookup(D20.Registry, {:session, session.id})

    assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(session.id))

    send(pid, {:online, "owner", %{online_at: 1}})
    assert_receive {:session, %Session{members: %{"owner" => %{status: :online}}}}

    assert {:ok, %Session{game: %Game{phase: :ready}}} =
             Sessions.dispatch(scope(session.id), "join", %{})

    assert_receive {:session, %Session{game: %Game{phase: :ready}}}

    %{pid: pid, session: session}
  end

  test "uses the current game phase as the state-machine state", %{pid: pid, session: session} do
    assert {:ok, {%Session{game: %Game{phase: :ready}} = current_session, "koala-rescue-club"}} =
             Sessions.get(session.id)

    assert {:ready, {"koala-rescue-club", Game, ^current_session}} = :sys.get_state(pid)
  end

  test "schedules and performs one server-owned roll", %{pid: pid, session: session} do
    assert {:ok,
            %Session{
              game: %Game{phase: :roll, mode: :solo, players: %{"owner" => _player}, roll: nil}
            } = roll_session} = Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, ^roll_session}
    assert {:roll, {"koala-rescue-club", Game, ^roll_session}} = :sys.get_state(pid)

    assert {:ok, {^roll_session, "koala-rescue-club"}} = Sessions.get(session.id)

    send(pid, {:online, "owner", %{online_at: 123}})

    assert_receive {:session,
                    %Session{
                      members: %{"owner" => %{status: :online, online_at: 123}},
                      game: %Game{phase: :roll, mode: :solo, players: %{"owner" => _player}}
                    } = presence_session}

    assert {:roll, {"koala-rescue-club", Game, ^presence_session}} = :sys.get_state(pid)

    assert_receive {:session,
                    %Session{game: %Game{phase: :submit, mode: :solo, roll: %{value: value}}} =
                      submitted_session},
                   5_000

    assert value in 1..6
    assert {:submit, {"koala-rescue-club", Game, ^submitted_session}} = :sys.get_state(pid)
    refute_receive {:session, %Session{game: %Game{phase: :submit}}}, 100
  end

  test "rejects client actors for automatic roll commands", %{session: session} do
    assert {:ok, %Session{game: %Game{phase: :roll}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert {:error, :invalid_identity} = Sessions.dispatch(scope(session.id), "roll", %{})
  end

  test "schedules the next roll only after every player submits", %{session: session} do
    assert {:ok, %Session{}} = Sessions.dispatch(scope(session.id, "player-2"), "join", %{})

    assert_receive {:session,
                    %Session{game: %Game{players: %{"owner" => _owner, "player-2" => _player_2}}}}

    assert {:ok, %Session{game: %Game{mode: :multiplayer}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, %Session{game: %Game{phase: :roll, mode: :multiplayer}}}

    assert_receive {:session,
                    %Session{
                      game: %Game{phase: :submit, mode: :multiplayer, roll: %{value: value}}
                    } = rolled_session},
                   5_000

    rulesheet = Ruleset.sheet!(rolled_session.game.sheet)
    player_sheet = rolled_session.game.players["owner"].sheet

    [first_cell | remaining_cells] =
      rulesheet
      |> Rules.legal_shape_placements(player_sheet, "plant_trees", value)
      |> List.first()

    assert {:ok, %Session{game: %Game{phase: :submit}} = first_selection} =
             Sessions.dispatch(scope(session.id), "select", %{
               "action" => "plant_trees",
               "die_value" => value,
               "volunteers_used" => 0,
               "target_cell" => first_cell
             })

    assert_receive {:session, ^first_selection}

    Enum.each(remaining_cells, fn cell ->
      assert {:ok, %Session{game: %Game{phase: :submit}} = selection} =
               Sessions.dispatch(scope(session.id), "select", %{"target_cell" => cell})

      assert_receive {:session, ^selection}
    end)

    assert {:ok, %Session{game: %Game{phase: :submit}} = owner_submitted} =
             Sessions.dispatch(scope(session.id), "submit", %{"bonus_actions" => []})

    assert_receive {:session, ^owner_submitted}

    payload = %{
      "die_value" => value,
      "volunteers_used" => 0,
      "target_cell" => %{"area" => "a", "row" => 0, "column" => 0}
    }

    assert {:ok, {%Session{game: %Game{phase: :submit, turn: 1}}, _slug}} =
             Sessions.get(session.id)

    assert {:ok, %Session{game: %Game{phase: :roll, mode: :multiplayer, turn: 2}}} =
             Sessions.dispatch(scope(session.id, "player-2"), "circle_tree", payload)

    assert_receive {:session, %Session{game: %Game{phase: :roll, mode: :multiplayer, turn: 2}}}
  end

  test "resets idle expiration without replacing the automatic roll timeout", %{
    pid: pid,
    session: session
  } do
    original_timeout = Application.fetch_env!(:d20, :session_idle_timeout)
    on_exit(fn -> Application.put_env(:d20, :session_idle_timeout, original_timeout) end)
    Application.put_env(:d20, :session_idle_timeout, 500)

    assert {:ok, %Session{game: %Game{phase: :roll}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, %Session{game: %Game{phase: :roll}}}

    monitor_ref = Process.monitor(pid)

    refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 250

    assert {:ok, {%Session{game: %Game{phase: :roll}}, "koala-rescue-club"}} =
             Sessions.get(session.id)

    refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 300
    assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 500
  end

  defp scope(session_id, actor_id \\ "owner") do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game("koala-rescue-club")
  end
end
