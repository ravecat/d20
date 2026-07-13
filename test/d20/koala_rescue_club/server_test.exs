defmodule D20.KoalaRescueClub.ServerTest do
  use D20.DataCase, async: false

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Server
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.SessionChannel

  setup do
    assert {:ok, %Session{} = session} =
             Sessions.create("koala-rescue-club", Game, "owner", %{"sheet" => "dharug"})

    on_exit(fn -> Sessions.stop(session.id) end)

    assert {:ok, pid} = Sessions.lookup(session.id)
    assert [{^pid, Server}] = Registry.lookup(D20.Registry, {:session, session.id})

    assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(session.id))
    assert {:ok, %Session{}} = Sessions.dispatch(scope(session.id), "join", %{})
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
            %Session{game: %Game{phase: :roll, roll: nil, roll_due_at: roll_due_at}} =
              roll_session} = Sessions.dispatch(scope(session.id), "start", %{})

    assert is_integer(roll_due_at)
    assert roll_due_at > System.system_time(:millisecond)

    assert_receive {:session, ^roll_session}
    assert {:roll, {"koala-rescue-club", Game, ^roll_session}} = :sys.get_state(pid)

    assert {:ok, {^roll_session, "koala-rescue-club"}} = Sessions.get(session.id)

    send(pid, {:join, "player-2", %{online_at: 123}})

    assert_receive {:session,
                    %Session{
                      members: %{"player-2" => %{online_at: 123}},
                      game: %Game{phase: :roll, roll_due_at: ^roll_due_at}
                    } = presence_session}

    assert {:roll, {"koala-rescue-club", Game, ^presence_session}} = :sys.get_state(pid)

    assert_receive {:session,
                    %Session{game: %Game{phase: :submit, roll: %{value: value}, roll_due_at: nil}} =
                      submitted_session},
                   5_000

    assert value in 1..6
    assert {:submit, {"koala-rescue-club", Game, ^submitted_session}} = :sys.get_state(pid)
    refute_receive {:session, %Session{game: %Game{phase: :submit}}}, 100
  end

  test "schedules the next roll only after every player submits", %{session: session} do
    assert {:ok, %Session{}} = Sessions.dispatch(scope(session.id, "player-2"), "join", %{})
    assert_receive {:session, %Session{game: %Game{order: ["owner", "player-2"]}}}

    assert {:ok, %Session{}} = Sessions.dispatch(scope(session.id), "start", %{})
    assert_receive {:session, %Session{game: %Game{phase: :roll}}}
    assert_receive {:session, %Session{game: %Game{phase: :submit, roll: %{value: value}}}}, 5_000

    payload = %{
      "die_value" => value,
      "volunteers_used" => 0,
      "target_cell" => %{"area" => "a", "row" => 0, "column" => 0}
    }

    assert {:ok, %Session{game: %Game{phase: :submit}}} =
             Sessions.dispatch(scope(session.id), "circle_tree", payload)

    assert_receive {:session, %Session{game: %Game{phase: :submit}}}

    assert {:ok, {%Session{game: %Game{phase: :submit, turn: 1}}, _slug}} =
             Sessions.get(session.id)

    assert {:ok, %Session{game: %Game{phase: :roll, turn: 2, roll_due_at: roll_due_at}}} =
             Sessions.dispatch(scope(session.id, "player-2"), "circle_tree", payload)

    assert is_integer(roll_due_at)
    assert_receive {:session, %Session{game: %Game{phase: :roll, turn: 2}}}
  end

  test "resets idle expiration without changing the roll deadline", %{pid: pid, session: session} do
    original_timeout = Application.fetch_env!(:d20, :session_idle_timeout)
    on_exit(fn -> Application.put_env(:d20, :session_idle_timeout, original_timeout) end)
    Application.put_env(:d20, :session_idle_timeout, 500)

    assert {:ok, %Session{game: %Game{roll_due_at: roll_due_at}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, %Session{game: %Game{phase: :roll}}}

    monitor_ref = Process.monitor(pid)

    refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 250

    assert {:ok, {%Session{game: %Game{roll_due_at: ^roll_due_at}}, "koala-rescue-club"}} =
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
