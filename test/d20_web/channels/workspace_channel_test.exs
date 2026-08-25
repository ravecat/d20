defmodule D20Web.WorkspaceChannelTest do
  use D20Web.ChannelCase, async: false

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.SessionChannel
  alias D20Web.UserSocket
  alias D20Web.Workspace
  alias D20Web.WorkspaceChannel

  @uri URI.parse("https://shell.example.com/socket/websocket?vsn=2.0.0")

  defmodule AutomaticServer do
    use D20.Sessions.Server

    alias D20.Command
    alias D20.Sessions.Session

    def handle_event(:info, :finish, _state, {game_id, engine, session}) do
      command = %Command{event: "finish", attrs: %{}}
      {:ok, %Session{} = updated_session} = Session.dispatch(session, engine, command)
      broadcast(session, updated_session)

      {:next_state, :finished, {game_id, engine, updated_session}, [idle_action()]}
    end
  end

  defmodule LifecycleGame do
    use D20.Game, server: AutomaticServer

    alias D20.Command

    @impl D20.Game
    def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    @impl D20.Game
    def init(_attrs), do: {:ok, %{phase: :setup}}

    @impl D20.Game
    def dispatch(game, %Command{event: "start"}), do: {:ok, %{game | phase: :running}}
    def dispatch(game, %Command{event: "finish"}), do: {:ok, %{game | phase: :finished}}
    def dispatch(game, %Command{}), do: {:ok, game}

    @impl D20.Game
    def finished?(%{phase: phase}), do: phase == :finished
  end

  test "rejects workspace discovery without an authenticated actor scope" do
    socket = socket UserSocket, "socket-id", %{request_uri: @uri}

    assert {:error, %{reason: "forbidden"}} =
             subscribe_and_join(socket, WorkspaceChannel, "workspace", %{})
  end

  test "returns an empty snapshot when the actor has no eligible sessions" do
    actor = actor()

    assert {:ok, %{sessions: []}, _socket} = join_workspace(actor)
  end

  test "returns session descriptors with runtime pids for monitor reconciliation" do
    actor = actor()
    session = create_session(actor.id)

    assert {:ok, %{sessions: [%{id: session_id}]}, socket} = join_workspace(actor)
    assert {[%{id: ^session_id}], runtime_pids} = Workspace.sessions(socket)
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})
    assert runtime_pids == MapSet.new([pid])
  end

  test "returns every current-member in-progress session with actor-bound module data" do
    actor = actor()
    game_id = game_id(183_006)
    game_id_string = TypeID.to_string(game_id)
    first = create_session(actor.id)
    second = create_session(actor.id)
    waiting = create_session(actor.id, start?: false)
    _unrelated = create_session(actor("other").id)

    assert {:error, :game_not_found} =
             D20.Sessions.create(TypeID.new("game"), D20.Qwinto.Game, actor.id)

    assert {:ok, %{sessions: sessions}, _socket} = join_workspace(actor)

    assert Enum.map(sessions, & &1.id) |> Enum.sort() == Enum.sort([first.id, second.id])
    assert Enum.map(sessions, & &1.game_id) == [game_id_string, game_id_string]
    assert Enum.map(sessions, & &1.phase) == [:in_progress, :in_progress]
    refute Enum.any?(sessions, &(&1.id == waiting.id))

    embed_url = "https://game-#{TypeID.suffix(game_id)}.shell.example.com/"
    origin = "https://game-#{TypeID.suffix(game_id)}.shell.example.com"

    for descriptor <- sessions do
      assert descriptor.module == %{
               embed_url: embed_url,
               allowed_origins: [origin],
               sandbox: ["allow-scripts", "allow-same-origin"]
             }

      assert descriptor.connection.endpoint == "wss://shell.example.com/module"
      assert descriptor.connection.topic == "session:#{descriptor.id}"

      assert {:ok, claims} = D20.Module.Token.verify(D20Web.Endpoint, descriptor.connection.token)

      assert claims.actor == actor
      assert claims.game_id == game_id
      assert claims.topic == descriptor.connection.topic
    end
  end

  test "pushes a complete snapshot when phase eligibility changes" do
    actor = actor()
    game_id = game_id(183_006)
    session = create_session(actor.id, start?: false)

    assert {:ok, %{sessions: []}, _socket} = join_workspace(actor)

    assert {:ok, %Session{phase: :in_progress}} =
             Sessions.dispatch(scope(session.id, actor.id, game_id), "start", %{})

    assert_push "snapshot", %{sessions: [%{id: session_id, phase: :in_progress}]}
    assert session_id == session.id

    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})
    assert Process.alive?(pid)
  end

  test "keeps a session discoverable after an accepted transition finishes it" do
    actor = actor()
    session = create_lifecycle_session(actor.id)

    assert {:ok, %{sessions: [%{id: session_id, phase: :in_progress}]}, _socket} =
             join_workspace(actor)

    assert session_id == session.id

    assert {:ok, %Session{phase: :finished}} =
             Sessions.dispatch(scope(session.id, actor.id, game_id(183_006)), "finish", %{})

    assert_push "snapshot", %{sessions: [%{id: ^session_id, phase: :finished}]}
  end

  test "returns a current-member finished session on a new workspace join" do
    actor = actor()
    session = create_lifecycle_session(actor.id)

    assert {:ok, %Session{phase: :finished}} =
             Sessions.dispatch(scope(session.id, actor.id, game_id(183_006)), "finish", %{})

    assert {:ok, %{sessions: [%{id: session_id, phase: :finished}]}, _socket} =
             join_workspace(actor)

    assert session_id == session.id
  end

  test "keeps an offline member discoverable" do
    actor = actor()
    game_id = game_id(183_006)
    session = create_lifecycle_session("owner")
    assert :ok = Sessions.attach(scope(session.id, actor.id, game_id))
    assert {:ok, %{sessions: []}, socket} = join_workspace(actor)
    assert [{pid, AutomaticServer}] = Registry.lookup(D20.Registry, {:session, session.id})

    send(pid, {:online, actor.id, %{online_at: 1}})
    assert_push "snapshot", %{sessions: [%{id: session_id}]}
    assert session_id == session.id

    assert {:ok, {%Session{members: members}, ^game_id}} = Sessions.get(session.id)
    assert %{status: :online, online_at: 1} = members[actor.id]

    send(pid, {:offline, actor.id})
    refute_push "snapshot", _payload, 50

    assert {:ok, {%Session{members: members}, ^game_id}} = Sessions.get(session.id)
    assert %{status: :offline, online_at: 1} = members[actor.id]
    assert {[%{id: session_id}], runtime_pids} = Workspace.sessions(socket)
    assert runtime_pids == MapSet.new([pid])
    assert session_id == session.id
  end

  test "publishes eligibility changes from a custom server automatic transition" do
    actor = actor()
    session = create_lifecycle_session(actor.id)
    assert {:ok, %{sessions: [%{id: session_id}]}, _socket} = join_workspace(actor)
    assert session_id == session.id
    assert [{pid, AutomaticServer}] = Registry.lookup(D20.Registry, {:session, session.id})

    send(pid, :finish)

    assert_push "snapshot", %{sessions: [%{id: ^session_id, phase: :finished}]}
  end

  test "treats duplicate invalidations as idempotent complete replacements" do
    actor = actor()
    session = create_lifecycle_session(actor.id)
    assert {:ok, %{sessions: [%{}]}, _socket} = join_workspace(actor)
    assert {:ok, {current, _game_id}} = Sessions.get(session.id)
    previous = %{current | phase: :waiting_for_players}

    assert :ok = Workspace.publish_session_changes(previous, current)
    assert :ok = Workspace.publish_session_changes(previous, current)

    assert_push "snapshot", %{sessions: [%{id: session_id}]}
    assert_push "snapshot", %{sessions: [%{id: ^session_id}]}
    assert session_id == session.id
  end

  test "persists Close across every actor Workspace and restores it through direct re-entry" do
    actor = actor()
    actor_id = actor.id
    session = create_session(actor.id)

    assert {:ok, %{sessions: [_]}, first_socket} = join_workspace(actor)
    assert {:ok, %{sessions: [_]}, _second_socket} = join_workspace(actor)
    assert {:ok, _projection, session_socket} = join_session_channel(session.id, actor)
    assert_push "projection", %{}

    assert {:ok, {before, _game_id}} = Sessions.get(session.id)
    :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(session.id))
    session_reference = Process.monitor(session_socket.channel_pid)
    reference = push(first_socket, "close_session", %{"id" => session.id})

    assert_reply reference, :ok
    assert_receive {:DOWN, ^session_reference, :process, _pid, :normal}
    assert_push "snapshot", %{sessions: []}
    assert_push "snapshot", %{sessions: []}

    assert_receive {:session,
                    %Session{members: %{^actor_id => %{status: :offline}}} = after_close}

    assert {:ok, {^after_close, _game_id}} = Sessions.get(session.id)
    assert after_close.game == before.game
    assert Enum.sort(Map.keys(after_close.members)) == Enum.sort(Map.keys(before.members))
    assert %{status: :offline} = after_close.members[actor.id]
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})
    assert Process.alive?(pid)

    assert {:ok, %{sessions: []}, fresh_socket} = join_workspace(actor)
    assert {[], MapSet.new()} == Workspace.sessions(fresh_socket)

    assert {:ok, _projection, _rejoined_socket} = join_session_channel(session.id, actor)

    assert_push "snapshot", %{sessions: [%{id: rejoined_session_id}]}
    assert rejoined_session_id == session.id

    assert {[%{id: ^rejoined_session_id}], runtime_pids} = Workspace.sessions(fresh_socket)
    assert runtime_pids == MapSet.new([pid])
  end

  test "coordinates close for a finished session and keeps membership and runtime" do
    actor = actor()
    actor_id = actor.id
    session = create_lifecycle_session(actor.id)

    assert {:ok, %Session{phase: :finished}} =
             Sessions.dispatch(scope(session.id, actor.id, game_id(183_006)), "finish", %{})

    assert {:ok, %{sessions: [_]}, socket} = join_workspace(actor)
    assert {:ok, _projection, session_socket} = join_session_channel(session.id, actor)
    assert_push "projection", %{}
    assert {:ok, {before, _game_id}} = Sessions.get(session.id)
    :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(session.id))
    session_reference = Process.monitor(session_socket.channel_pid)
    reference = push(socket, "close_session", %{"id" => session.id})

    assert_reply reference, :ok
    assert_receive {:DOWN, ^session_reference, :process, _pid, :normal}
    assert_push "snapshot", %{sessions: []}

    assert_receive {:session,
                    %Session{members: %{^actor_id => %{status: :offline}}} = after_close}

    assert {:ok, {^after_close, _game_id}} = Sessions.get(session.id)
    assert after_close.game == before.game
    assert MapSet.new(Map.keys(after_close.members)) == MapSet.new(Map.keys(before.members))
    assert %{status: :offline} = after_close.members[actor.id]
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})
    assert Process.alive?(pid)
  end

  test "accepts idempotent close for an offline durable member" do
    actor = actor()
    actor_id = actor.id
    session = create_session(actor.id)
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})

    send(pid, {:offline, actor.id})

    assert {:ok, {%Session{members: %{^actor_id => %{status: :offline}}} = before, _game_id}} =
             Sessions.get(session.id)

    assert {:ok, %{sessions: [_]}, socket} = join_workspace(actor)
    reference = push(socket, "close_session", %{"id" => session.id})

    assert_reply reference, :ok
    assert_push "snapshot", %{sessions: []}
    assert {:ok, {^before, _game_id}} = Sessions.get(session.id)
    assert Process.alive?(pid)

    repeated_reference = push(socket, "close_session", %{"id" => session.id})
    assert_reply repeated_reference, :ok
    assert_push "snapshot", %{sessions: []}
    assert {:ok, %{sessions: []}, _fresh_socket} = join_workspace(actor)
  end

  test "accepts close for a waiting attachment and keeps its runtime state" do
    actor = actor()
    session = create_session(actor.id, start?: false)

    assert {:ok, %{sessions: []}, socket} = join_workspace(actor)
    assert {:ok, {before, _game_id}} = Sessions.get(session.id)
    reference = push(socket, "close_session", %{"id" => session.id})

    assert_reply reference, :ok
    assert_push "snapshot", %{sessions: []}

    assert {:ok, {%Session{} = after_close, _game_id}} = Sessions.get(session.id)
    assert after_close.game == before.game
    assert %{status: :offline} = after_close.members[actor.id]
  end

  test "accepts close as a no-op for an actor outside the session" do
    owner = actor("owner")
    actor = actor("outsider")
    session = create_session(owner.id)

    assert {:ok, %{sessions: []}, socket} = join_workspace(actor)
    assert {:ok, {before, _game_id}} = Sessions.get(session.id)
    reference = push(socket, "close_session", %{"id" => session.id})

    assert_reply reference, :ok
    assert_push "snapshot", %{sessions: []}
    assert {:ok, {^before, _game_id}} = Sessions.get(session.id)
  end

  test "rebuilds the snapshot when a reported runtime terminates" do
    actor = actor()
    session = create_session(actor.id)

    assert {:ok, %{sessions: [%{id: session_id}]}, _socket} = join_workspace(actor)
    assert session_id == session.id

    assert :ok = Sessions.stop(session.id)
    assert_push "snapshot", %{sessions: []}
  end

  test "rebuilds the snapshot after an abnormal runtime exit" do
    actor = actor()
    session = create_session(actor.id)

    assert {:ok, %{sessions: [%{id: session_id}]}, _socket} = join_workspace(actor)
    assert session_id == session.id
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})

    Process.exit(pid, :kill)

    assert_push "snapshot", %{sessions: []}
  end

  test "rejects game commands without mutating a session" do
    actor = actor()
    session = create_session(actor.id)
    assert {:ok, _snapshot, socket} = join_workspace(actor)
    assert {:ok, {before, _game_id}} = Sessions.get(session.id)

    reference = push(socket, "roll", %{"colors" => ["orange"]})

    assert_reply reference, :error, %{reason: "unsupported_event"}
    assert {:ok, {^before, _game_id}} = Sessions.get(session.id)
  end

  defp create_session(actor_id, options \\ []) do
    game_id = game_id(183_006)
    assert {:ok, session} = Sessions.create(game_id, D20.Qwinto.Game, actor_id)
    on_exit(fn -> Sessions.stop(session.id) end)

    assert {:ok, %Session{}} =
             Sessions.dispatch(scope(session.id, actor_id, game_id), "join", %{})

    assert {:ok, %Session{}} =
             Sessions.dispatch(scope(session.id, "second-player", game_id), "join", %{})

    add_member(session.id, actor_id)
    add_member(session.id, "second-player")
    assert :ok = Sessions.attach(scope(session.id, actor_id, game_id))
    assert :ok = Sessions.attach(scope(session.id, "second-player", game_id))

    if Keyword.get(options, :start?, true) do
      assert {:ok, %Session{phase: :in_progress}} =
               Sessions.dispatch(scope(session.id, actor_id, game_id), "start", %{})
    end

    session
  end

  defp create_lifecycle_session(actor_id) do
    game_id = game_id(183_006)
    assert {:ok, session} = Sessions.create(game_id, LifecycleGame, actor_id)
    on_exit(fn -> Sessions.stop(session.id) end)

    assert {:ok, %Session{}} =
             Sessions.dispatch(scope(session.id, actor_id, game_id), "join", %{})

    add_member(session.id, actor_id)
    assert :ok = Sessions.attach(scope(session.id, actor_id, game_id))

    assert {:ok, %Session{phase: :in_progress}} =
             Sessions.dispatch(scope(session.id, actor_id, game_id), "start", %{})

    session
  end

  defp join_workspace(actor) do
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: %{auth_token: token, uri: @uri})

    subscribe_and_join(socket, WorkspaceChannel, "workspace", %{})
  end

  defp join_session_channel(session_id, actor) do
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: %{auth_token: token, uri: @uri})

    subscribe_and_join(socket, SessionChannel.topic(session_id), %{})
  end

  defp add_member(session_id, actor_id) do
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session_id})
    send(pid, {:online, actor_id, %{online_at: 1}})

    assert {:ok, {%Session{members: %{^actor_id => %{status: :online}}}, _game_id}} =
             Sessions.get(session_id)
  end

  defp scope(session_id, actor_id, game_id) do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game(game_id)
  end

  defp actor(id \\ Ecto.UUID.generate()), do: %Actor{id: id, type: :anonymous}
end
