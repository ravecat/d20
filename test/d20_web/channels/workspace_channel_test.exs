defmodule D20Web.WorkspaceChannelTest do
  use D20Web.ChannelCase, async: false

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.UserSocket
  alias D20Web.Workspace
  alias D20Web.WorkspaceChannel

  @uri URI.parse("https://shell.example.com/socket/websocket?vsn=2.0.0")

  defmodule AutomaticServer do
    use D20.Game.Server

    alias D20.Command
    alias D20.Sessions.Session

    def handle_event(:info, :finish, _state, {slug, engine, session}) do
      command = %Command{event: "finish", attrs: %{}}
      {:ok, %Session{} = updated_session} = Session.dispatch(session, engine, command)
      broadcast(session, updated_session)

      {:next_state, :finished, {slug, engine, updated_session}, [idle_action()]}
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

  test "returns every current-member in-progress session with actor-bound module data" do
    actor = actor()
    first = create_session("qwinto", actor.id)
    second = create_session("qwinto", actor.id)
    waiting = create_session("qwinto", actor.id, start?: false)
    _unrelated = create_session("qwinto", actor("other").id)
    _unconfigured = create_session("missing-game", actor.id)

    assert {:ok, %{sessions: sessions}, _socket} = join_workspace(actor)

    assert Enum.map(sessions, & &1.id) |> Enum.sort() == Enum.sort([first.id, second.id])
    assert Enum.map(sessions, & &1.slug) == ["qwinto", "qwinto"]
    refute Enum.any?(sessions, &(&1.id == waiting.id))

    for descriptor <- sessions do
      assert descriptor.module == %{
               embed_url: "https://qwinto.shell.example.com/",
               allowed_origins: ["https://qwinto.shell.example.com"],
               sandbox: ["allow-scripts", "allow-same-origin"]
             }

      assert descriptor.connection.endpoint == "wss://shell.example.com/module"
      assert descriptor.connection.topic == "session:#{descriptor.id}"

      assert {:ok, claims} = D20.Module.Token.verify(D20Web.Endpoint, descriptor.connection.token)

      assert claims.actor == actor
      assert claims.slug == "qwinto"
      assert claims.topic == descriptor.connection.topic
    end
  end

  test "pushes complete snapshots when phase or membership eligibility changes" do
    actor = actor()
    session = create_session("qwinto", actor.id, start?: false)

    assert {:ok, %{sessions: []}, _socket} = join_workspace(actor)

    assert {:ok, %Session{phase: :in_progress}} =
             Sessions.dispatch(scope(session.id, actor.id, "qwinto"), "start", %{})

    assert_push "snapshot", %{sessions: [%{id: session_id}]}
    assert session_id == session.id

    assert {:ok, %Session{members: members}} =
             Sessions.remove_member(scope(session.id, actor.id, "qwinto"))

    refute Map.has_key?(members, actor.id)
    assert_push "snapshot", %{sessions: []}

    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})
    assert Process.alive?(pid)
  end

  test "removes a session after an accepted transition finishes it" do
    actor = actor()
    session = create_lifecycle_session(actor.id)

    assert {:ok, %{sessions: [%{id: session_id}]}, _socket} = join_workspace(actor)
    assert session_id == session.id

    assert {:ok, %Session{phase: :finished}} =
             Sessions.dispatch(scope(session.id, actor.id, "qwinto"), "finish", %{})

    assert_push "snapshot", %{sessions: []}
  end

  test "keeps an offline member discoverable until an explicit leave" do
    actor = actor()
    session = create_lifecycle_session("owner")
    assert {:ok, %{sessions: []}, _socket} = join_workspace(actor)
    assert [{pid, AutomaticServer}] = Registry.lookup(D20.Registry, {:session, session.id})

    send(pid, {:online, actor.id, %{online_at: 1}})
    assert_push "snapshot", %{sessions: [%{id: session_id}]}
    assert session_id == session.id

    assert {:ok, {%Session{members: members}, "qwinto"}} = Sessions.get(session.id)
    assert %{status: :online, online_at: 1} = members[actor.id]

    send(pid, {:offline, actor.id})
    refute_push "snapshot", _payload, 50

    assert {:ok, {%Session{members: members}, "qwinto"}} = Sessions.get(session.id)
    assert %{status: :offline, online_at: 1} = members[actor.id]

    assert {:ok, %Session{members: members}} =
             Sessions.remove_member(scope(session.id, actor.id, "qwinto"))

    refute Map.has_key?(members, actor.id)
    assert_push "snapshot", %{sessions: []}
  end

  test "publishes eligibility changes from a custom server automatic transition" do
    actor = actor()
    session = create_lifecycle_session(actor.id)
    assert {:ok, %{sessions: [%{id: session_id}]}, _socket} = join_workspace(actor)
    assert session_id == session.id
    assert [{pid, AutomaticServer}] = Registry.lookup(D20.Registry, {:session, session.id})

    send(pid, :finish)

    assert_push "snapshot", %{sessions: []}
  end

  test "treats duplicate invalidations as idempotent complete replacements" do
    actor = actor()
    session = create_lifecycle_session(actor.id)
    assert {:ok, %{sessions: [%{}]}, _socket} = join_workspace(actor)
    assert {:ok, {current, "qwinto"}} = Sessions.get(session.id)
    previous = %{current | phase: :waiting_for_players}

    assert :ok = Workspace.publish_session_changes(previous, current)
    assert :ok = Workspace.publish_session_changes(previous, current)

    assert_push "snapshot", %{sessions: [%{id: session_id}]}
    assert_push "snapshot", %{sessions: [%{id: ^session_id}]}
    assert session_id == session.id
  end

  test "an explicit close removes the game from every actor workspace" do
    actor = actor()
    session = create_session("qwinto", actor.id)

    assert {:ok, %{sessions: [_]}, _first_socket} = join_workspace(actor)
    assert {:ok, %{sessions: [_]}, _second_socket} = join_workspace(actor)

    assert {:ok, %Session{}} = Sessions.remove_member(scope(session.id, actor.id, "qwinto"))

    assert_push "snapshot", %{sessions: []}
    assert_push "snapshot", %{sessions: []}
  end

  test "accepts close through WorkspaceChannel and keeps the runtime alive" do
    actor = actor()
    session = create_session("qwinto", actor.id)

    assert {:ok, %{sessions: [_]}, socket} = join_workspace(actor)
    reference = push(socket, "close", %{"id" => session.id})

    assert_reply reference, :ok
    assert_push "snapshot", %{sessions: []}
    assert {:ok, {%Session{members: members}, "qwinto"}} = Sessions.get(session.id)
    refute Map.has_key?(members, actor.id)
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})
    assert Process.alive?(pid)
  end

  test "rejects close when the actor is not a current member" do
    actor = actor()
    session = create_session("qwinto", actor("member").id)

    assert {:ok, %{sessions: []}, socket} = join_workspace(actor)
    reference = push(socket, "close", %{"id" => session.id})

    assert_reply reference, :error, %{reason: "forbidden"}
  end

  test "rebuilds the snapshot when a reported runtime terminates" do
    actor = actor()
    session = create_session("qwinto", actor.id)

    assert {:ok, %{sessions: [%{id: session_id}]}, _socket} = join_workspace(actor)
    assert session_id == session.id

    assert :ok = Sessions.stop(session.id)
    assert_push "snapshot", %{sessions: []}
  end

  test "rebuilds the snapshot after an abnormal runtime exit" do
    actor = actor()
    session = create_session("qwinto", actor.id)

    assert {:ok, %{sessions: [%{id: session_id}]}, _socket} = join_workspace(actor)
    assert session_id == session.id
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session.id})

    Process.exit(pid, :kill)

    assert_push "snapshot", %{sessions: []}
  end

  test "rejects game commands without mutating a session" do
    actor = actor()
    session = create_session("qwinto", actor.id)
    assert {:ok, _snapshot, socket} = join_workspace(actor)
    assert {:ok, {before, "qwinto"}} = Sessions.get(session.id)

    reference = push(socket, "roll", %{"colors" => ["orange"]})

    assert_reply reference, :error, %{reason: "unsupported_event"}
    assert {:ok, {^before, "qwinto"}} = Sessions.get(session.id)
  end

  defp create_session(slug, actor_id, options \\ []) do
    assert {:ok, session} = Sessions.create(slug, D20.Qwinto.Game, actor_id)
    on_exit(fn -> Sessions.stop(session.id) end)

    assert {:ok, %Session{}} = Sessions.dispatch(scope(session.id, actor_id, slug), "join", %{})

    assert {:ok, %Session{}} =
             Sessions.dispatch(scope(session.id, "second-player", slug), "join", %{})

    add_member(session.id, actor_id)
    add_member(session.id, "second-player")

    if Keyword.get(options, :start?, true) do
      assert {:ok, %Session{phase: :in_progress}} =
               Sessions.dispatch(scope(session.id, actor_id, slug), "start", %{})
    end

    session
  end

  defp create_lifecycle_session(actor_id) do
    assert {:ok, session} = Sessions.create("qwinto", LifecycleGame, actor_id)
    on_exit(fn -> Sessions.stop(session.id) end)

    assert {:ok, %Session{}} =
             Sessions.dispatch(scope(session.id, actor_id, "qwinto"), "join", %{})

    add_member(session.id, actor_id)

    assert {:ok, %Session{phase: :in_progress}} =
             Sessions.dispatch(scope(session.id, actor_id, "qwinto"), "start", %{})

    session
  end

  defp join_workspace(actor) do
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: %{auth_token: token, uri: @uri})

    subscribe_and_join(socket, WorkspaceChannel, "workspace", %{})
  end

  defp add_member(session_id, actor_id) do
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session_id})
    send(pid, {:online, actor_id, %{online_at: 1}})
    send(pid, {:offline, actor_id})

    assert {:ok, {%Session{members: %{^actor_id => %{status: :offline}}}, _slug}} =
             Sessions.get(session_id)
  end

  defp scope(session_id, actor_id, slug) do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game(slug)
  end

  defp actor(id \\ Ecto.UUID.generate()), do: %Actor{id: id, type: :anonymous}
end
