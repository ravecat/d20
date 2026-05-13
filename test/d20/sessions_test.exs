defmodule D20.SessionsTest do
  use ExUnit.Case, async: true

  alias D20.Sessions
  alias D20.Sessions.Server
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel

  defmodule TestGame do
    @behaviour D20.Game

    @impl D20.Game
    def init, do: {:ok, %{events: []}}

    @impl D20.Game
    def dispatch(_state, :fail, _attrs), do: {:error, :bad_command}

    def dispatch(state, event, attrs) do
      {:ok, update_in(state.events, &(&1 ++ [{event, attrs}]))}
    end

    @impl D20.Game
    def finished?(_state), do: false
  end

  describe "create/2" do
    test "starts a supervised session process for a game slug" do
      assert {:ok, %Session{} = session} = Sessions.create("qwinto", "p1")
      id = session.id

      on_exit(fn ->
        Sessions.stop(id)
      end)

      assert {:ok, ^id} = Ecto.UUID.cast(id)
      assert %Session{id: ^id, engine: D20.Qwinto.Game, owner_id: "p1"} = session
      assert {:ok, pid} = Sessions.lookup(id)
      assert Process.alive?(pid)
    end

    test "returns invalid owner errors" do
      assert {:error, :invalid_owner_id} = Sessions.create("qwinto", "")
      assert {:error, :invalid_owner_id} = Sessions.create("qwinto", nil)
    end

    test "returns playable game lookup errors" do
      assert {:error, :game_not_found} = Sessions.create("missing", "p1")
    end
  end

  describe "dispatch/3" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "serializes session transitions through the process", %{id: id} do
      assert {:ok, %Session{} = session} = Sessions.dispatch(id, :noop, %{value: 1})
      assert {:noop, %{value: 1}} in session.game.events
      assert {:ok, ^session} = Sessions.get(id)
    end

    test "keeps current state when a dispatch returns an error", %{id: id} do
      assert {:ok, before} = Sessions.get(id)
      assert {:error, :bad_command} = Sessions.dispatch(id, :fail, %{})
      assert {:ok, ^before} = Sessions.get(id)
    end

    test "keeps client state out of the server state", %{id: id} do
      assert {:ok, %Session{id: ^id} = session} = Sessions.get(id)
      refute Map.has_key?(session, :client_state)
    end

    test "updates members from session presence events", %{id: id} do
      topic = SessionChannel.topic(id)

      assert {:ok, %{}} =
               Presence.handle_metas(
                 topic,
                 %{joins: %{"p2" => %{metas: [%{online_at: 123}]}}, leaves: %{}},
                 %{"p2" => %{metas: [%{online_at: 123}]}},
                 %{}
               )

      assert {:ok, session} = Sessions.get(id)
      assert session.members["p2"] == %{online_at: 123}

      assert {:ok, %{}} =
               Presence.handle_metas(
                 topic,
                 %{joins: %{}, leaves: %{"p2" => %{metas: [%{}]}}},
                 %{},
                 %{}
               )

      assert {:ok, session} = Sessions.get(id)
      refute Map.has_key?(session.members, "p2")
    end
  end

  describe "missing sessions" do
    test "returns not found for missing session ids" do
      id = "missing-#{System.unique_integer([:positive])}"

      assert {:error, :session_not_found} = Sessions.get(id)
      assert {:error, :session_not_found} = Sessions.dispatch(id, :join, %{player_id: "p1"})
      assert {:error, :session_not_found} = Sessions.lookup("")
    end
  end

  describe "stop/3" do
    setup do
      start_test_session(TestGame, "p1")
    end

    test "stops an existing session process and treats missing sessions as stopped", %{id: id} do
      assert :ok = Sessions.stop(id)
      assert {:error, :session_not_found} = Sessions.get(id)
      assert :ok = Sessions.stop(id)
    end

    test "does not restart a crashed volatile session process", %{id: id} do
      assert {:ok, pid} = Sessions.lookup(id)

      ref = Process.monitor(pid)
      Process.exit(pid, :kill)

      assert_receive {:DOWN, ^ref, :process, ^pid, :killed}
      assert {:error, :session_not_found} = Sessions.get(id)
    end
  end

  defp start_test_session(engine, owner_id) do
    assert {:ok, session} = Session.new(engine, owner_id)

    assert {:ok, _pid} =
             DynamicSupervisor.start_child(D20.Sessions.Supervisor, {Server, session: session})

    on_exit(fn ->
      Sessions.stop(session.id)
    end)

    %{id: session.id, session: session}
  end
end
