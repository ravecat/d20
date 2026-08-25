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
    game_id = game_id(425_873)

    assert {:ok, %Session{} = session} =
             Sessions.create(game_id, Game, "owner", %{"sheet" => "dharug"})

    on_exit(fn -> Sessions.stop(session.id) end)

    assert [{pid, Server}] = Registry.lookup(D20.Registry, {:session, session.id})

    assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(session.id))

    send(pid, {:online, "owner", %{online_at: 1}})

    assert_receive {:session,
                    %Session{
                      members: %{"owner" => %{status: :online}},
                      game: %Game{phase: :ready, players: %{"owner" => _player}}
                    }}

    %{pid: pid, session: session, game_id: game_id}
  end

  test "uses the current game phase as the state-machine state", %{
    pid: pid,
    session: session,
    game_id: game_id
  } do
    assert {:ok, {%Session{game: %Game{phase: :ready}} = current_session, ^game_id}} =
             Sessions.get(session.id)

    assert {:ready, {^game_id, Game, ^current_session}} = :sys.get_state(pid)
  end

  test "keeps player state across duplicate online and final offline events", %{
    pid: pid,
    session: session,
    game_id: game_id
  } do
    assert {:ok, {%Session{game: %Game{players: %{"owner" => player}}}, _game_id}} =
             Sessions.get(session.id)

    send(pid, {:online, "owner", %{online_at: 2}})

    assert_receive {:session,
                    %Session{
                      members: %{"owner" => %{status: :online, online_at: 2}},
                      game: %Game{players: %{"owner" => ^player}}
                    } = online}

    send(pid, {:offline, "owner"})

    assert_receive {:session,
                    %Session{
                      members: %{"owner" => %{status: :offline, online_at: 2}},
                      game: %Game{players: %{"owner" => ^player}}
                    } = offline}

    assert {:ok, {^offline, ^game_id}} = Sessions.get(session.id)
    assert online.game == offline.game
  end

  test "schedules and performs one server-owned roll", %{
    pid: pid,
    session: session,
    game_id: game_id
  } do
    assert {:ok,
            %Session{
              game: %Game{phase: :roll, mode: :solo, players: %{"owner" => _player}, roll: nil}
            } = roll_session} = Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, ^roll_session}
    assert {:roll, {^game_id, Game, ^roll_session}} = :sys.get_state(pid)

    assert {:ok, {^roll_session, ^game_id}} = Sessions.get(session.id)

    send(pid, {:online, "owner", %{online_at: 123}})

    assert_receive {:session,
                    %Session{
                      members: %{"owner" => %{status: :online, online_at: 123}},
                      game: %Game{phase: :roll, mode: :solo, players: %{"owner" => _player}}
                    } = presence_session}

    assert {:roll, {^game_id, Game, ^presence_session}} = :sys.get_state(pid)

    assert_receive {:session,
                    %Session{game: %Game{phase: :submit, mode: :solo, roll: %{value: value}}} =
                      submitted_session},
                   5_000

    assert value in 1..6
    assert {:submit, {^game_id, Game, ^submitted_session}} = :sys.get_state(pid)
    refute_receive {:session, %Session{game: %Game{phase: :submit}}}, 100
  end

  test "rejects client actors for automatic roll commands", %{session: session} do
    assert {:ok, %Session{game: %Game{phase: :roll}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert {:error, :invalid_identity} = Sessions.dispatch(scope(session.id), "roll", %{})
  end

  test "schedules the next roll only after every player submits", %{
    session: session,
    game_id: game_id
  } do
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

    cells = rulesheet |> Rules.legal_shape_placements(player_sheet, :tree, value) |> List.first()

    assert {:ok, %{submit_ready: true, resolution: :shape, selected_cells: ^cells}} =
             Sessions.preview(scope(session.id), "draft", %{
               "mark" => "tree",
               "die_value" => value,
               "selected_cells" => cells
             })

    refute_receive {:session, %Session{}}, 100
    assert {:ok, {^rolled_session, ^game_id}} = Sessions.get(session.id)

    assert {:ok, %Session{game: %Game{phase: :submit}} = owner_submitted} =
             Sessions.dispatch(scope(session.id), "submit", %{
               "mark" => "tree",
               "die_value" => value,
               "selected_cells" => cells,
               "bonus_actions" => []
             })

    assert_receive {:session, ^owner_submitted}

    assert {:ok, {%Session{game: %Game{phase: :submit, turn: 1}}, _game_id}} =
             Sessions.get(session.id)

    assert {:ok, %Session{game: %Game{phase: :roll, mode: :multiplayer, turn: 2}}} =
             Sessions.dispatch(scope(session.id, "player-2"), "submit", %{
               "mark" => "tree",
               "die_value" => value,
               "selected_cells" => [%{"area" => "a", "row" => 0, "column" => 0}],
               "bonus_actions" => []
             })

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

    assert {:ok, {%Session{game: %Game{phase: :roll}}, _game_id}} = Sessions.get(session.id)

    refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 300
    assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 500
  end

  defp scope(session_id, actor_id \\ "owner") do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game(game_id(425_873))
  end
end
