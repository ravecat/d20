defmodule D20.Sessions.SessionTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Game, as: QwintoGame
  alias D20.Sessions.Session

  defmodule TestGame do
    @behaviour D20.Game

    @impl D20.Game
    def init, do: {:ok, %{players: [], left: [], started?: false, finished?: false}}

    @impl D20.Game
    def dispatch(state, "join", %{player_id: player_id}) do
      if player_id in state.players do
        {:ok, state}
      else
        {:ok, update_in(state.players, &(&1 ++ [player_id]))}
      end
    end

    def dispatch(state, "leave", %{player_id: player_id}) do
      {:ok, update_in(state.left, &Enum.uniq(&1 ++ [player_id]))}
    end

    def dispatch(state, "start", _attrs) when length(state.players) in 1..2 do
      {:ok, %{state | started?: true}}
    end

    def dispatch(_state, "start", _attrs), do: {:error, :invalid_player_count}
    def dispatch(state, "finish", _attrs), do: {:ok, %{state | finished?: true}}
    def dispatch(state, "noop", _attrs), do: {:ok, state}
    def dispatch(_state, "fail", _attrs), do: {:error, :bad_command}
    def dispatch(_state, _event, _attrs), do: {:error, :bad_command}

    @impl D20.Game
    def finished?(%{finished?: true}), do: true
    def finished?(_state), do: false
  end

  describe "new/2" do
    test "requires a callable game engine" do
      assert {:ok,
              %Session{
                id: id,
                phase: :waiting_for_players,
                owner_id: "p1",
                members: %{},
                game: %{players: ["p1"]}
              }} = Session.new(TestGame, "p1")

      assert {:ok, ^id} = Ecto.UUID.cast(id)
      assert {:error, :invalid_engine} = Session.new(__MODULE__, "p1")
      assert {:error, :invalid_engine} = Session.new(nil, "p1")
      assert {:error, :invalid_engine} = Session.new("not a module", "p1")
      assert {:error, :invalid_owner_id} = Session.new(TestGame, nil)
      assert {:error, :invalid_owner_id} = Session.new(TestGame, "")
      assert {:error, :invalid_owner_id} = Session.new(nil, "")
    end

    test "encodes selected public fields as JSON" do
      assert {:ok, session} = Session.new(QwintoGame, "p1")

      decoded = session |> Jason.encode!() |> Jason.decode!()

      assert decoded["id"] == session.id
      assert decoded["phase"] == "waiting_for_players"
      assert decoded["owner_id"] == "p1"
      assert decoded["members"] == %{}
      assert decoded["game"]["phase"] == "setup"
      refute Map.has_key?(decoded, "engine")
    end
  end

  describe "session events" do
    test "joins are idempotent and forwarded to the game" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} =
               Session.dispatch(session, TestGame, "join", %{player_id: "p2", online_at: 10})

      assert session.members["p2"] == %{online_at: 10}
      assert session.game.players == ["p1", "p2"]

      assert {:ok, session} =
               Session.dispatch(session, TestGame, "join", %{player_id: "p2", online_at: 11})

      assert session.members["p2"] == %{online_at: 11}
      assert session.game.players == ["p1", "p2"]

      assert {:error, :invalid_command} =
               Session.dispatch(session, TestGame, "join", %{player_id: "p3"})

      assert {:error, :invalid_identity} =
               Session.dispatch(session, TestGame, "join", %{player_id: ""})
    end

    test "propagates game join capacity errors without adding session members" do
      {:ok, session} = Session.new(QwintoGame, "p1")

      {:ok, session} =
        Session.dispatch(session, QwintoGame, "join", %{player_id: "p2", online_at: 20})

      {:ok, session} =
        Session.dispatch(session, QwintoGame, "join", %{player_id: "p3", online_at: 30})

      {:ok, session} =
        Session.dispatch(session, QwintoGame, "join", %{player_id: "p4", online_at: 40})

      assert {:error, :invalid_player_count} =
               Session.dispatch(session, QwintoGame, "join", %{player_id: "p5", online_at: 50})

      assert Enum.sort(Map.keys(session.members)) == ["p2", "p3", "p4"]
      refute Map.has_key?(session.game.players, "p5")
    end

    test "requires the owner to start the session" do
      {:ok, session} = Session.new(TestGame, "p1")

      {:ok, session} =
        Session.dispatch(session, TestGame, "join", %{player_id: "p2", online_at: 10})

      assert {:error, :not_owner} =
               Session.dispatch(session, TestGame, "start", %{player_id: "p2"})

      assert {:error, :invalid_identity} =
               Session.dispatch(session, TestGame, "start", %{player_id: ""})
    end

    test "rejects command payloads that are not maps" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:error, :invalid_command} = Session.dispatch(session, TestGame, "noop", [])
    end

    test "accepts string event names" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} =
               Session.dispatch(session, TestGame, "join", %{player_id: "p2", online_at: 10})

      assert session.members["p2"] == %{online_at: 10}
      assert session.game.players == ["p1", "p2"]
    end

    test "delegates game event names to the game engine" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:error, :bad_command} = Session.dispatch(session, TestGame, "not_a_command", %{})
    end

    test "routes in-progress joins through the game engine" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, TestGame, "start", %{player_id: "p1"})

      assert {:ok, session} =
               Session.dispatch(session, TestGame, "join", %{player_id: "p3", online_at: 13})

      assert session.members["p3"] == %{online_at: 13}
      assert session.game.players == ["p1", "p3"]
    end

    test "leaves remove existing members and are forwarded to the game" do
      {:ok, session} = Session.new(TestGame, "p1")

      {:ok, session} =
        Session.dispatch(session, TestGame, "join", %{player_id: "p2", online_at: 10})

      assert {:ok, session} = Session.dispatch(session, TestGame, "leave", %{player_id: "p2"})
      refute Map.has_key?(session.members, "p2")
      assert session.game.left == ["p2"]

      assert {:ok, session} =
               Session.dispatch(session, TestGame, "join", %{player_id: "p2", online_at: 12})

      assert session.members["p2"] == %{online_at: 12}

      assert {:ok, ^session} = Session.dispatch(session, TestGame, "leave", %{player_id: "p3"})
    end

    test "keeps owner identity when the owner joins and leaves" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} = Session.dispatch(session, TestGame, "leave", %{player_id: "p1"})
      assert session.owner_id == "p1"
      assert session.members == %{}
      assert session.game.left == []

      assert {:ok, session} =
               Session.dispatch(session, TestGame, "join", %{player_id: "p1", online_at: 14})

      assert session.members["p1"] == %{online_at: 14}

      assert {:ok, session} = Session.dispatch(session, TestGame, "leave", %{player_id: "p1"})
      assert session.owner_id == "p1"
      refute Map.has_key?(session.members, "p1")
      assert session.game.left == ["p1"]
    end
  end

  describe "game events" do
    test "starts the hosted game and delegates commands while in progress" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, %Session{phase: :in_progress, game: %{started?: true}} = session} =
               Session.dispatch(session, TestGame, "start", %{player_id: "p1"})

      assert {:ok, %Session{phase: :in_progress} = session} =
               Session.dispatch(session, TestGame, "noop", %{})

      assert {:error, :bad_command} = Session.dispatch(session, TestGame, "fail", %{})
    end

    test "moves to finished when the hosted game becomes finished" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, TestGame, "start", %{player_id: "p1"})

      assert {:ok, %Session{phase: :finished, game: %{finished?: true}} = session} =
               Session.dispatch(session, TestGame, "finish", %{})

      assert {:error, :invalid_phase} = Session.dispatch(session, TestGame, "noop", %{})

      assert {:error, :invalid_phase} =
               Session.dispatch(session, TestGame, "join", %{player_id: "p2"})

      assert {:error, :invalid_phase} =
               Session.dispatch(session, TestGame, "leave", %{player_id: "p1"})
    end
  end
end
