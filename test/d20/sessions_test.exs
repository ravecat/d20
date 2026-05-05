defmodule D20.SessionsTest do
  use ExUnit.Case, async: true

  alias D20.Session
  alias D20.Sessions

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
    test "starts a supervised session process with a generated id" do
      assert {:ok, %{id: id, session: %Session{} = session}} = Sessions.create(TestGame, "p1")

      on_exit(fn ->
        Sessions.stop(id)
      end)

      assert {:ok, ^id} = Ecto.UUID.cast(id)
      assert %Session{engine: TestGame, owner_id: "p1"} = session
      assert {:ok, pid} = Sessions.lookup(id)
      assert Process.alive?(pid)
    end

    test "returns invalid owner errors" do
      assert {:error, :invalid_owner_id} = Sessions.create(TestGame, "")
    end

    test "returns invalid engine errors" do
      assert {:error, :invalid_engine} = Sessions.create(__MODULE__, "p1")
    end
  end

  describe "dispatch/4" do
    setup do
      assert {:ok, %{id: id, session: session}} = Sessions.create(TestGame, "p1")

      on_exit(fn ->
        Sessions.stop(id)
      end)

      %{id: id, session: session}
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
      assert {:ok, %{id: id, session: session}} = Sessions.create(TestGame, "p1")

      on_exit(fn ->
        Sessions.stop(id)
      end)

      %{id: id, session: session}
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
end
