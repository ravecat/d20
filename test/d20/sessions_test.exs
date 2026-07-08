defmodule D20.SessionsTest do
  use D20.DataCase, async: false

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Command
  alias D20.KoalaRescueClub.Game, as: KoalaGame
  alias D20.Sessions
  alias D20.Sessions.Server
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel

  defmodule TestGame do
    @behaviour D20.Game

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

  describe "create/3" do
    test "starts a supervised session process for a game slug" do
      assert {:ok, %Session{} = session} = Sessions.create("qwinto", TestGame, "p1")
      id = session.id
      session_ref = id

      on_exit(fn -> Sessions.stop(session_ref) end)

      assert {:ok, ^id} = Ecto.UUID.cast(id)
      assert %Session{id: ^id, owner_id: "p1"} = session
      assert {:ok, {^session, "qwinto"}} = Sessions.get(session_ref)
      assert {:ok, pid} = Sessions.lookup(session_ref)
      assert Process.alive?(pid)
    end

    test "returns invalid owner errors" do
      assert {:error, :invalid_owner_id} = Sessions.create("qwinto", TestGame, "")
      assert {:error, :invalid_owner_id} = Sessions.create("qwinto", TestGame, nil)
    end

    test "returns engine validation errors" do
      assert {:error, :invalid_engine} = Sessions.create("qwinto", String, "p1")
    end

    test "passes creation attrs into the game before starting the session process" do
      assert {:ok, %Session{game: %KoalaGame{sheet: :yugambeh}} = session} =
               Sessions.create("koala-rescue-club", KoalaGame, "p1", %{"sheet" => "yugambeh"})

      on_exit(fn -> Sessions.stop(session.id) end)

      assert {:ok, {^session, "koala-rescue-club"}} = Sessions.get(session.id)
    end

    test "does not start a session process when creation attrs are invalid" do
      before_count = Registry.count(D20.Registry)

      assert {:error, %Ecto.Changeset{valid?: false}} =
               Sessions.create("koala-rescue-club", KoalaGame, "p1", %{"sheet" => "missing"})

      assert Registry.count(D20.Registry) == before_count
    end
  end

  describe "dispatch/3" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "serializes session transitions through the process", %{id: id, ref: ref} do
      assert {:ok, %Session{} = session} = Sessions.dispatch(scope(ref, "p1"), "start", %{})
      assert {"start", "p1", %{}} in session.game.events
      assert session.id == id
      assert {:ok, {^session, "test-game"}} = Sessions.get(ref)
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

    test "keeps current state when a dispatch returns an error", %{ref: ref} do
      assert {:ok, %Session{}} = Sessions.dispatch(scope(ref, "p1"), "start", %{})
      assert {:ok, {before, "test-game"}} = Sessions.get(ref)
      assert {:error, :invalid_command} = Sessions.dispatch(scope(ref, "p1"), "fail", %{})
      assert {:ok, {^before, "test-game"}} = Sessions.get(ref)
    end

    test "keeps client state out of the server state", %{id: id, ref: ref} do
      assert {:ok, {%Session{id: ^id} = session, "test-game"}} = Sessions.get(ref)
      refute Map.has_key?(session, :client_state)
    end

    test "updates members from session presence events", %{id: id, ref: ref} do
      topic = SessionChannel.topic(id)

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

      assert {:ok, {session, "test-game"}} = Sessions.get(ref)

      assert %{online_at: 123, display_name: display_name, avatar: avatar} = session.members["p2"]

      assert is_binary(display_name)
      assert is_binary(avatar)
      refute display_name == "forged"
      refute avatar == "forged-avatar"

      assert {:ok, %{}} =
               Presence.handle_metas(
                 topic,
                 %{joins: %{}, leaves: %{"p2" => %{metas: [%{}]}}},
                 %{},
                 %{}
               )

      assert {:ok, {session, "test-game"}} = Sessions.get(ref)
      refute Map.has_key?(session.members, "p2")
    end
  end

  describe "missing sessions" do
    test "returns not found for missing session ids" do
      id = "missing-#{System.unique_integer([:positive])}"

      assert {:error, :session_not_found} = Sessions.get(id)
      assert {:error, :session_not_found} = Sessions.dispatch(scope(id, "p1"), "join", %{})
      assert {:error, :session_not_found} = Sessions.lookup(id)
    end
  end

  describe "get/1" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "returns server metadata for the session", %{id: id} do
      assert {:ok, {%Session{id: ^id}, "test-game"}} = Sessions.get(id)
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
      assert {:ok, pid} = Sessions.lookup(session_ref)

      monitor_ref = Process.monitor(pid)
      Process.exit(pid, :kill)

      assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :killed}

      case Sessions.lookup(session_ref) do
        {:ok, pid} -> refute Process.alive?(pid)
        {:error, :session_not_found} -> :ok
      end
    end
  end

  defp start_test_session(engine, owner_id) do
    assert {:ok, session} = Session.new(engine, owner_id)

    assert {:ok, _pid} =
             DynamicSupervisor.start_child(
               D20.Sessions.Supervisor,
               {Server, slug: "test-game", engine: engine, session: session}
             )

    ref = session.id

    on_exit(fn -> Sessions.stop(ref) end)

    %{id: session.id, ref: ref, session: session}
  end

  defp scope(session_id, actor_id) do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game("test-game")
  end
end
