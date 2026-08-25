defmodule D20.SessionsTest do
  use D20.DataCase, async: false

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Command
  alias D20.KoalaRescueClub.Game, as: KoalaGame
  alias D20.Sessions
  alias D20.Sessions.Registry, as: SessionRegistry
  alias D20.Sessions.Server
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel

  defmodule TestGame do
    use D20.Game

    @impl D20.Game
    def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    @impl D20.Game
    def init(_attrs), do: {:ok, %{events: []}}

    @impl D20.Game
    def dispatch(_state, %Command{event: "fail"}), do: {:error, :invalid_command}

    def dispatch(state, %Command{event: event, actor_id: actor_id, attrs: attrs}) do
      {:ok, update_in(state.events, &(&1 ++ [{event, actor_id, attrs}]))}
    end

    @impl D20.Game
    def preview(state, %Command{event: "inspect", actor_id: actor_id, attrs: attrs}) do
      {:ok, %{actor_id: actor_id, attrs: attrs, event_count: length(state.events)}}
    end

    @impl D20.Game
    def finished?(state) do
      Enum.any?(state.events, fn {event, _actor_id, _attrs} -> event == "finish" end)
    end
  end

  defmodule CustomServer do
    use D20.Sessions.Server

    alias D20.Sessions.Session

    @impl :gen_statem
    def init({_game_id, _engine, %Session{}} = data) do
      {:ok, :running, data}
    end

    @impl :gen_statem
    def handle_event({:call, from}, {:dispatch, %Command{} = command}, state, data) do
      command = %{command | attrs: Map.put(command.attrs, :server, :custom)}

      D20.Sessions.Server.handle_event({:call, from}, {:dispatch, command}, state, data)
    end
  end

  defmodule CustomServerGame do
    use D20.Game, server: CustomServer

    @impl D20.Game
    def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    @impl D20.Game
    def init(_attrs), do: {:ok, %{events: []}}

    @impl D20.Game
    def dispatch(_state, %Command{event: "fail"}), do: {:error, :invalid_command}

    def dispatch(state, %Command{event: event, actor_id: actor_id, attrs: attrs}) do
      {:ok, update_in(state.events, &(&1 ++ [{event, actor_id, attrs}]))}
    end

    @impl D20.Game
    def finished?(_state), do: false
  end

  defmodule SharedDefaultServer do
    use D20.Sessions.Server
  end

  defmodule SharedDefaultServerGame do
    use D20.Game, server: SharedDefaultServer

    @impl D20.Game
    def changeset(params), do: TestGame.changeset(params)

    @impl D20.Game
    def init(attrs), do: TestGame.init(attrs)

    @impl D20.Game
    def dispatch(state, command), do: TestGame.dispatch(state, command)

    @impl D20.Game
    def finished?(state), do: TestGame.finished?(state)
  end

  defmodule RejectPresenceGame do
    use D20.Game

    @impl D20.Game
    def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    @impl D20.Game
    def init(_attrs), do: {:ok, %{events: []}}

    @impl D20.Game
    def dispatch(_state, %Command{event: "join", actor_id: "rejected"}),
      do: {:error, :presence_rejected}

    def dispatch(_state, %Command{event: "left"}), do: {:error, :presence_rejected}

    def dispatch(state, %Command{event: event, actor_id: actor_id, attrs: attrs}) do
      {:ok, update_in(state.events, &(&1 ++ [{event, actor_id, attrs}]))}
    end

    @impl D20.Game
    def finished?(_state), do: false
  end

  describe "game server contract" do
    test "keeps game-specific hooks out of the default and generated servers" do
      assert Enum.sort(Server.behaviour_info(:callbacks)) ==
               Enum.sort(start_link: 1, get: 1, dispatch: 2, preview: 2)

      refute function_exported?(Server, :handle_event, 5)
      refute function_exported?(Server, :transition, 5)

      for server <- [Server, CustomServer, SharedDefaultServer],
          {hook, arity} <- [state_name: 1, prepare_transition: 2, handle_game_event: 4] do
        refute function_exported?(server, hook, arity)
      end

      for server <- [Server, CustomServer, SharedDefaultServer],
          {client, arity} <- [attach: 2, detach: 2] do
        refute function_exported?(server, client, arity)
      end

      for server <- [Server, CustomServer, SharedDefaultServer],
          {callback, arity} <- [callback_mode: 0, init: 1, handle_event: 4] do
        assert function_exported?(server, callback, arity)
      end
    end

    test "provides Presence admission behavior to custom servers by default" do
      game_id = game_id(183_006)
      assert {:ok, %Session{} = session} = Sessions.create(game_id, SharedDefaultServerGame, "p1")

      on_exit(fn -> Sessions.stop(session.id) end)

      topic = SessionChannel.topic(session.id)
      assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, topic)
      assert {:ok, {^session, ^game_id}} = Sessions.get(session.id)

      assert {:ok, %{}} =
               Presence.handle_metas(
                 topic,
                 %{joins: %{"p2" => %{metas: [%{online_at: 123}]}}, leaves: %{}},
                 %{"p2" => %{metas: [%{online_at: 123}]}},
                 %{}
               )

      assert_receive {:session,
                      %Session{
                        members: %{"p2" => %{status: :online, online_at: 123}},
                        game: %{events: [{"join", "p2", %{online_at: 123}}]}
                      } = updated_session}

      assert {:ok, {^updated_session, ^game_id}} = Sessions.get(session.id)
    end

    test "provides serialized attachment behavior to custom servers by default" do
      game_id = game_id(183_006)
      assert {:ok, %Session{} = session} = Sessions.create(game_id, CustomServerGame, "owner")

      on_exit(fn -> Sessions.stop(session.id) end)

      actor_scope = scope(session.id, "actor")
      assert [{pid, CustomServer}] = Registry.lookup(D20.Registry, {:session, session.id})

      assert :ok = Sessions.attach(actor_scope)
      assert :ok = Sessions.attach(actor_scope)
      assert SessionRegistry.list("actor") == [{pid, session.id}]

      send(pid, {:online, "actor", %{online_at: 123}})

      assert {:ok, {%Session{members: %{"actor" => %{status: :online}}, game: game}, ^game_id}} =
               Sessions.get(session.id)

      assert :ok = Sessions.detach(actor_scope, session.id)

      assert {:ok,
              {%Session{members: %{"actor" => %{status: :offline}}, game: detached_game},
               ^game_id}} = Sessions.get(session.id)

      assert detached_game == game
      assert SessionRegistry.list("actor") == []
    end
  end

  describe "create/3" do
    test "starts a supervised session process for a local game id" do
      game_id = game_id(183_006)
      assert {:ok, %Session{} = session} = Sessions.create(game_id, TestGame, "p1")
      id = session.id
      session_ref = id

      on_exit(fn -> Sessions.stop(session_ref) end)

      assert {:ok, ^id} = Ecto.UUID.cast(id)
      assert %Session{id: ^id, owner_id: "p1"} = session
      assert {:ok, {^session, ^game_id}} = Sessions.get(session_ref)
      assert [{pid, Server}] = Registry.lookup(D20.Registry, {:session, session_ref})
      assert Process.alive?(pid)

      assert {:waiting_for_players, {^game_id, TestGame, ^session}} = :sys.get_state(pid)
    end

    test "starts the engine configured game server" do
      game_id = game_id(183_006)
      assert {:ok, %Session{} = session} = Sessions.create(game_id, CustomServerGame, "p1")
      session_ref = session.id

      on_exit(fn -> Sessions.stop(session_ref) end)

      assert [{_pid, CustomServer}] = Registry.lookup(D20.Registry, {:session, session_ref})

      assert {:ok, %Session{} = session} =
               session_ref |> scope("p1") |> Sessions.dispatch("start", %{})

      assert {"start", "p1", %{server: :custom}} in session.game.events
      assert {:ok, {^session, ^game_id}} = Sessions.get(session_ref)
    end

    test "uses TypeID primary-key casting for the persisted game lookup" do
      assert {:error, :game_not_found} = Sessions.create(TypeID.new("game"), TestGame, "p1")

      assert_raise Ecto.Query.CastError, fn -> Sessions.create("not-an-id", TestGame, "p1") end

      assert_raise Ecto.Query.CastError, fn ->
        Sessions.create(TypeID.new("user"), TestGame, "p1")
      end
    end

    test "rejects a game when session launch is unavailable" do
      assert {:error, :forbidden} = Sessions.create(game_id(360_471), TestGame, "p1")
    end

    test "returns invalid owner errors" do
      qwinto_id = game_id(183_006)
      assert {:error, :invalid_owner_id} = Sessions.create(qwinto_id, TestGame, "")
      assert {:error, :invalid_owner_id} = Sessions.create(qwinto_id, TestGame, nil)
    end

    test "returns engine validation errors" do
      assert {:error, :invalid_engine} = Sessions.create(game_id(183_006), String, "p1")
    end

    test "passes creation attrs into the game before starting the session process" do
      koala_id = game_id(425_873)

      assert {:ok, %Session{game: %KoalaGame{sheet: :yugambeh}} = session} =
               Sessions.create(koala_id, KoalaGame, "p1", %{"sheet" => "yugambeh"})

      on_exit(fn -> Sessions.stop(session.id) end)

      assert {:ok, {^session, ^koala_id}} = Sessions.get(session.id)
    end

    test "manages a Koala state-machine server through the shared session API" do
      koala_id = game_id(425_873)

      assert {:ok, %Session{} = session} =
               Sessions.create(koala_id, KoalaGame, "p1", %{"sheet" => "dharug"})

      on_exit(fn -> Sessions.stop(session.id) end)

      assert [{_pid, D20.KoalaRescueClub.Server}] =
               Registry.lookup(D20.Registry, {:session, session.id})

      assert {:ok, {^session, ^koala_id}} = Sessions.get(session.id)

      assert {:ok, %Session{members: %{}} = joined_session} =
               Sessions.dispatch(scope(session.id, "p1"), "join", %{})

      assert {:ok, {^joined_session, ^koala_id}} = Sessions.get(session.id)

      assert :ok = Sessions.stop(session.id)
      assert_session_stopped(session.id)
    end

    test "does not start a session process when creation attrs are invalid" do
      before_count = Registry.count(D20.Registry)

      assert {:error, %Ecto.Changeset{valid?: false}} =
               Sessions.create(game_id(425_873), KoalaGame, "p1", %{"sheet" => "missing"})

      assert Registry.count(D20.Registry) == before_count
    end
  end

  describe "dispatch/3" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "serializes session transitions through the process", %{
      id: id,
      ref: ref,
      game_id: game_id
    } do
      assert {:ok, %Session{} = session} = Sessions.dispatch(scope(ref, "p1"), "start", %{})
      assert {"start", "p1", %{}} in session.game.events
      assert session.id == id
      assert {:ok, {^session, ^game_id}} = Sessions.get(ref)
    end

    test "dispatches scoped game commands with the actor id", %{ref: ref} do
      assert {:ok, %Session{}} = Sessions.dispatch(scope(ref, "p1"), "start", %{})

      scope = scope(ref, "p2")

      payload = %{:player_id => "forged-atom", "player_id" => "forged-string", "value" => 1}

      assert {:ok, %Session{} = session} = Sessions.dispatch(scope, "noop", payload)
      assert {"noop", "p2", payload} in session.game.events
    end

    test "dispatches scoped lifecycle commands with the actor id", %{ref: ref} do
      scope = scope(ref, "p1")

      assert {:ok, %Session{} = session} =
               Sessions.dispatch(scope, "start", %{"player_id" => "forged"})

      assert {"start", "p1", %{"player_id" => "forged"}} in session.game.events
    end

    test "rejects scoped dispatches without session or actor context" do
      assert {:error, :forbidden} = Sessions.dispatch(%Scope{}, "noop", %{})
    end

    test "keeps current state when a dispatch returns an error", %{ref: ref, game_id: game_id} do
      assert {:ok, %Session{}} = Sessions.dispatch(scope(ref, "p1"), "start", %{})
      assert {:ok, {before, ^game_id}} = Sessions.get(ref)
      assert {:error, :invalid_command} = Sessions.dispatch(scope(ref, "p1"), "fail", %{})
      assert {:ok, {^before, ^game_id}} = Sessions.get(ref)
    end

    test "stores, publishes, and replies with one authoritative accepted state", %{
      ref: ref,
      pid: pid,
      game_id: game_id
    } do
      assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(ref))

      assert {:ok, %Session{} = session} = Sessions.dispatch(scope(ref, "p1"), "start", %{})
      assert_receive {:session, ^session}
      assert {:ok, {^session, ^game_id}} = Sessions.get(ref)
      assert {:in_progress, {^game_id, TestGame, ^session}} = :sys.get_state(pid)

      assert {:error, :invalid_command} = Sessions.dispatch(scope(ref, "p1"), "fail", %{})
      refute_receive {:session, %Session{}}, 50
      assert {:ok, {^session, ^game_id}} = Sessions.get(ref)
      assert {:in_progress, {^game_id, TestGame, ^session}} = :sys.get_state(pid)

      assert {:ok, %Session{phase: :finished} = finished_session} =
               Sessions.dispatch(scope(ref, "p1"), "finish", %{})

      assert_receive {:session, ^finished_session}
      assert {:finished, {^game_id, TestGame, ^finished_session}} = :sys.get_state(pid)
    end

    test "keeps client state out of the server state", %{id: id, ref: ref, game_id: game_id} do
      assert {:ok, {%Session{id: ^id} = session, ^game_id}} = Sessions.get(ref)
      refute Map.has_key?(session, :client_state)
    end

    test "updates members from session presence events", %{id: id, ref: ref, game_id: game_id} do
      topic = SessionChannel.topic(id)
      assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, topic)

      assert {:ok, %{}} =
               Presence.handle_metas(
                 topic,
                 %{
                   joins: %{
                     "p2" => %{
                       metas: [%{online_at: 123, display_name: "forged", avatar: "forged-avatar"}]
                     }
                   },
                   leaves: %{}
                 },
                 %{
                   "p2" => %{
                     metas: [%{online_at: 123, display_name: "forged", avatar: "forged-avatar"}]
                   }
                 },
                 %{}
               )

      assert {:ok, {session, ^game_id}} = Sessions.get(ref)
      assert_receive {:session, ^session}

      assert %{status: :online, online_at: 123, display_name: "forged", avatar: "forged-avatar"} =
               session.members["p2"]

      assert session.game.events == [
               {"join", "p2", %{online_at: 123, display_name: "forged", avatar: "forged-avatar"}}
             ]

      assert {:ok, %{}} =
               Presence.handle_metas(
                 topic,
                 %{joins: %{}, leaves: %{"p2" => %{metas: [%{}]}}},
                 %{},
                 %{}
               )

      assert {:ok, {session, ^game_id}} = Sessions.get(ref)
      assert_receive {:session, ^session}

      assert %{status: :offline, online_at: 123, display_name: "forged", avatar: "forged-avatar"} =
               session.members["p2"]

      assert session.game.events == [
               {"join", "p2", %{online_at: 123, display_name: "forged", avatar: "forged-avatar"}}
             ]
    end

    test "keeps membership through Presence status transitions", %{id: id, ref: ref, pid: pid} do
      assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(id))

      send(pid, {:online, "p2", %{online_at: 123, phx_ref: "current-ref"}})

      assert_receive {:session,
                      %Session{
                        members: %{"p2" => %{status: :online, online_at: 123}},
                        game: %{events: [{"join", "p2", %{online_at: 123}}]}
                      } = online}

      send(pid, {:offline, "p2"})

      assert_receive {:session,
                      %Session{members: %{"p2" => %{status: :offline, online_at: 123}}} = offline}

      assert offline.game == online.game

      assert {:ok, {^offline, _game_id}} = Sessions.get(ref)

      send(pid, {:offline, "p2"})

      refute_receive {:session, %Session{}}, 50
      assert {:ok, {^offline, _game_id}} = Sessions.get(ref)
      refute online == offline
    end
  end

  describe "preview/3" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "serializes a caller-scoped read without storing or publishing", %{
      ref: ref,
      pid: pid,
      game_id: game_id
    } do
      assert {:ok, %Session{}} = Sessions.dispatch(scope(ref, "p1"), "start", %{})
      assert {:ok, {before, ^game_id}} = Sessions.get(ref)
      assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(ref))

      assert {:ok, %{actor_id: "p2", attrs: %{candidate: 1}, event_count: 1}} =
               Sessions.preview(scope(ref, "p2"), "inspect", %{candidate: 1})

      refute_receive {:session, %Session{}}, 50
      assert {:ok, {^before, ^game_id}} = Sessions.get(ref)
      assert {:in_progress, {^game_id, TestGame, ^before}} = :sys.get_state(pid)
    end

    test "requires session and actor context" do
      assert {:error, :forbidden} = Sessions.preview(%Scope{}, "inspect", %{})
    end
  end

  describe "Presence-driven admission" do
    setup do
      start_test_session(RejectPresenceGame, "p1")
    end

    test "retains online membership when game admission is rejected", %{
      ref: ref,
      pid: pid,
      game_id: game_id
    } do
      assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(ref))

      send(pid, {:online, "rejected", %{online_at: 123}})

      assert_receive {:session,
                      %Session{
                        members: %{"rejected" => %{status: :online, online_at: 123}},
                        game: %{events: []}
                      } = online}

      assert {:ok, {^online, ^game_id}} = Sessions.get(ref)

      assert {:waiting_for_players, {^game_id, RejectPresenceGame, ^online}} = :sys.get_state(pid)
    end

    test "keeps admitted game state when the member goes offline", %{ref: ref, pid: pid} do
      assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(ref))

      send(pid, {:online, "p2", %{online_at: 123}})

      assert_receive {:session,
                      %Session{
                        members: %{"p2" => %{status: :online}},
                        game: %{events: [{"join", "p2", %{online_at: 123}}]}
                      } = online}

      send(pid, {:offline, "p2"})

      assert_receive {:session, %Session{members: %{"p2" => %{status: :offline}}} = offline}

      assert {:ok, {^offline, _game_id}} = Sessions.get(ref)
      assert offline.game == online.game
    end
  end

  describe "missing sessions" do
    test "returns not found for missing session ids" do
      id = "missing-#{System.unique_integer([:positive])}"

      assert {:error, :session_not_found} = Sessions.get(id)
      assert {:error, :session_not_found} = Sessions.dispatch(scope(id, "p1"), "join", %{})
    end
  end

  describe "actor attachments" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "serializes idempotent attach and detach through the Session process", %{
      ref: ref,
      pid: pid
    } do
      actor_scope = scope(ref, "p2")

      assert :ok = Sessions.attach(actor_scope)
      assert :ok = Sessions.attach(actor_scope)
      assert SessionRegistry.list("p2") == [{pid, ref}]

      send(pid, {:online, "p2", %{online_at: 123}})

      assert {:ok, {%Session{members: %{"p2" => %{status: :online}}, game: game}, _game_id}} =
               Sessions.get(ref)

      assert :ok = Sessions.detach(actor_scope, ref)
      assert :ok = Sessions.detach(actor_scope, ref)
      assert SessionRegistry.list("p2") == []

      assert {:ok,
              {%Session{members: %{"p2" => %{status: :offline}}, game: detached_game}, _game_id}} =
               Sessions.get(ref)

      assert detached_game == game
      refute Enum.any?(detached_game.events, fn {event, _actor_id, _attrs} -> event == "left" end)
    end

    test "ordinary Presence offline keeps the attachment", %{ref: ref, pid: pid} do
      assert :ok = Sessions.attach(scope(ref, "p2"))
      send(pid, {:online, "p2", %{online_at: 123}})

      assert {:ok, {%Session{members: %{"p2" => %{status: :online}}}, _game_id}} =
               Sessions.get(ref)

      send(pid, {:offline, "p2"})

      assert {:ok, {%Session{members: %{"p2" => %{status: :offline}}}, _game_id}} =
               Sessions.get(ref)

      assert SessionRegistry.list("p2") == [{pid, ref}]
    end

    test "rejects attach and detach without authenticated scope", %{ref: ref} do
      assert {:error, :forbidden} = Sessions.attach(%Scope{})
      assert {:error, :forbidden} = Sessions.detach(%Scope{}, ref)
    end

    test "treats detach from a missing runtime as an idempotent success" do
      missing_id = Ecto.UUID.generate()

      assert :ok = Sessions.detach(scope(missing_id, "p2"), missing_id)
    end
  end

  describe "list/1" do
    test "returns only attached member runtimes without treating ownership as participation" do
      actor_id = Ecto.UUID.generate()
      actor_scope = Scope.for_actor(%Actor{id: actor_id, type: :anonymous})

      game_id = game_id(183_006)
      assert {:ok, owned_session} = Sessions.create(game_id, TestGame, actor_id)
      assert {:ok, joined_session} = Sessions.create(game_id, TestGame, "other-owner")

      assert {:ok, second_joined_session} = Sessions.create(game_id, TestGame, "other-owner")

      assert {:ok, unrelated_session} = Sessions.create(game_id, TestGame, "other-owner")

      sessions = [owned_session, joined_session, second_joined_session, unrelated_session]
      on_exit(fn -> Enum.each(sessions, &Sessions.stop(&1.id)) end)

      assert Sessions.list(actor_scope) == []

      mark_online(joined_session.id, actor_id)
      mark_online(second_joined_session.id, actor_id)
      mark_online(unrelated_session.id, "another-actor")

      assert :ok = Sessions.attach(scope(joined_session.id, actor_id))
      assert :ok = Sessions.attach(scope(second_joined_session.id, actor_id))
      assert :ok = Sessions.attach(scope(unrelated_session.id, "another-actor"))

      assert runtime_sessions =
               actor_scope
               |> Sessions.list()
               |> Enum.map(fn {pid, {%Session{id: id}, slug}} -> {pid, id, slug} end)

      assert Enum.all?(runtime_sessions, fn {pid, _id, _game_id} -> Process.alive?(pid) end)

      assert runtime_sessions
             |> Enum.map(fn {_pid, id, id_game} -> {id, id_game} end)
             |> Enum.sort() ==
               Enum.sort([{joined_session.id, game_id}, {second_joined_session.id, game_id}])
    end

    test "returns no sessions without an actor scope" do
      assert Sessions.list(%Scope{}) == []
    end
  end

  describe "get/1" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "returns server metadata for the session", %{id: id, game_id: game_id} do
      assert {:ok, {%Session{id: ^id}, ^game_id}} = Sessions.get(id)
    end
  end

  describe "stop/1" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "stops an existing session process and treats missing sessions as stopped", %{ref: ref} do
      assert :ok = Sessions.stop(ref)
      assert :ok = Sessions.stop(ref)
    end

    test "does not restart a crashed volatile session process", %{ref: session_ref} do
      assert [{pid, Server}] = Registry.lookup(D20.Registry, {:session, session_ref})

      monitor_ref = Process.monitor(pid)
      Process.exit(pid, :kill)

      assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :killed}

      case Registry.lookup(D20.Registry, {:session, session_ref}) do
        [{registered_pid, Server}] -> refute Process.alive?(registered_pid)
        [] -> :ok
      end
    end

    test "removes every attachment owned by the stopped Session process", %{
      ref: session_ref,
      pid: pid
    } do
      assert :ok = Sessions.attach(scope(session_ref, "p1"))
      assert :ok = Sessions.attach(scope(session_ref, "p2"))
      assert SessionRegistry.list("p1") == [{pid, session_ref}]
      assert SessionRegistry.list("p2") == [{pid, session_ref}]

      partition = session_registry_partition()
      :erlang.trace(partition, true, [:receive])
      on_exit(fn -> :erlang.trace(partition, false, [:receive]) end)

      assert :ok = Sessions.stop(session_ref)
      assert_registry_cleanup_received(partition, pid)
      :sys.get_state(partition)
      :erlang.trace(partition, false, [:receive])

      assert SessionRegistry.list("p1") == []
      assert SessionRegistry.list("p2") == []
    end
  end

  describe "idle timeout" do
    setup do
      original_timeout = Application.fetch_env!(:d20, :session_idle_timeout)

      on_exit(fn -> Application.put_env(:d20, :session_idle_timeout, original_timeout) end)
    end

    test "stops a session process after the configured idle timeout" do
      Application.put_env(:d20, :session_idle_timeout, 50)

      %{ref: session_ref, pid: pid} = start_test_session(TestGame, "p1")

      monitor_ref = Process.monitor(pid)

      assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 300
      assert_session_stopped(session_ref)
    end

    test "resets the idle timeout after session messages" do
      Application.put_env(:d20, :session_idle_timeout, 500)

      %{ref: session_ref, pid: pid} = start_test_session(TestGame, "p1")

      monitor_ref = Process.monitor(pid)

      refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 250
      assert {:ok, {%Session{}, _game_id}} = Sessions.get(session_ref)
      refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 300
      assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 500
    end
  end

  defp start_test_session(engine, owner_id) do
    assert {:ok, session} = Session.new(engine, owner_id)
    game_id = game_id(183_006)

    pid = start_supervised!({Server, game_id: game_id, engine: engine, session: session})
    send(pid, :presence)
    assert {:ok, {_session, ^game_id}} = Server.get(pid)
    ref = session.id

    %{id: session.id, ref: ref, session: session, pid: pid, game_id: game_id}
  end

  defp mark_online(session_id, actor_id) do
    assert [{pid, _server}] = Registry.lookup(D20.Registry, {:session, session_id})
    send(pid, {:online, actor_id, %{online_at: 123}})

    assert {:ok, {%Session{members: %{^actor_id => %{status: :online}}}, _game_id}} =
             Sessions.get(session_id)
  end

  defp assert_session_stopped(session_ref) do
    case Registry.lookup(D20.Registry, {:session, session_ref}) do
      [{pid, _server}] -> refute Process.alive?(pid)
      [] -> :ok
    end
  end

  defp session_registry_partition do
    [{_id, partition, :worker, [Registry.Partition]}] =
      SessionRegistry |> Process.whereis() |> Supervisor.which_children()

    partition
  end

  defp assert_registry_cleanup_received(partition, owner) do
    receive do
      {:trace, ^partition, :receive, {:DOWN, _reference, :process, ^owner, :normal}} -> :ok
      {:trace, ^partition, :receive, {:EXIT, ^owner, :normal}} -> :ok
    after
      1_000 -> flunk("Registry did not observe the Session process termination")
    end
  end

  defp scope(session_id, actor_id) do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game(game_id(183_006))
  end
end
