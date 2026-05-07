defmodule D20.SessionTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Game, as: QwintoGame
  alias D20.Session

  defmodule TestGame do
    @behaviour D20.Game

    @impl D20.Game
    def init, do: {:ok, %{players: [], left: [], started?: false, finished?: false}}

    @impl D20.Game
    def dispatch(state, :join, %{player_id: player_id}) do
      if player_id in state.players do
        {:ok, state}
      else
        {:ok, update_in(state.players, &(&1 ++ [player_id]))}
      end
    end

    def dispatch(state, :leave, %{player_id: player_id}) do
      {:ok, update_in(state.left, &Enum.uniq(&1 ++ [player_id]))}
    end

    def dispatch(state, :start, _attrs) when length(state.players) in 1..2 do
      {:ok, %{state | started?: true}}
    end

    def dispatch(_state, :start, _attrs), do: {:error, :invalid_player_count}
    def dispatch(state, :finish, _attrs), do: {:ok, %{state | finished?: true}}
    def dispatch(state, :noop, _attrs), do: {:ok, state}
    def dispatch(_state, :fail, _attrs), do: {:error, :bad_command}

    @impl D20.Game
    def projection(state), do: %{players: state.players, started?: state.started?}

    @impl D20.Game
    def finished?(%{finished?: true}), do: true
    def finished?(_state), do: false
  end

  describe "new/2" do
    test "requires a callable game engine" do
      assert {:ok,
              %Session{
                phase: :waiting_for_players,
                engine: TestGame,
                owner_id: "p1",
                members: %{"p1" => :online},
                game: %{players: ["p1"]}
              }} = Session.new(TestGame, "p1")

      assert {:error, :invalid_engine} = Session.new(__MODULE__, "p1")
      assert {:error, :invalid_engine} = Session.new(nil, "p1")
      assert {:error, :invalid_engine} = Session.new("not a module", "p1")
      assert {:error, :invalid_owner_id} = Session.new(TestGame, nil)
      assert {:error, :invalid_owner_id} = Session.new(TestGame, "")
      assert {:error, :invalid_owner_id} = Session.new(nil, "")
    end
  end

  describe "projection/1" do
    test "wraps session metadata and game projection" do
      assert {:ok, session} = Session.new(TestGame, "p1")

      assert %{
               phase: :waiting_for_players,
               owner_id: "p1",
               members: %{"p1" => :online},
               game: %{players: ["p1"], started?: false}
             } = Session.projection(session)
    end
  end

  describe "session events" do
    test "joins are idempotent and forwarded to the game" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} = Session.dispatch(session, :join, %{player_id: "p2"})
      assert session.members["p2"] == :online
      assert session.game.players == ["p1", "p2"]

      assert {:ok, session} = Session.dispatch(session, :join, %{player_id: "p2"})
      assert session.members["p2"] == :online
      assert session.game.players == ["p1", "p2"]
      assert {:error, :invalid_identity} = Session.dispatch(session, :join, %{player_id: ""})
    end

    test "propagates game join capacity errors without adding session members" do
      {:ok, session} = Session.new(QwintoGame, "p1")
      {:ok, session} = Session.dispatch(session, :join, %{player_id: "p2"})
      {:ok, session} = Session.dispatch(session, :join, %{player_id: "p3"})
      {:ok, session} = Session.dispatch(session, :join, %{player_id: "p4"})

      assert {:error, :invalid_player_count} =
               Session.dispatch(session, :join, %{player_id: "p5"})

      assert Enum.sort(Map.keys(session.members)) == ["p1", "p2", "p3", "p4"]
      refute Map.has_key?(session.game.players, "p5")
    end

    test "requires the owner to start the session" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, :join, %{player_id: "p2"})

      assert {:error, :not_owner} = Session.dispatch(session, :start, %{player_id: "p2"})
      assert {:error, :invalid_identity} = Session.dispatch(session, :start, %{player_id: ""})
    end

    test "routes in-progress joins for existing members through the game engine" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, :join, %{player_id: "p2"})
      {:ok, session} = Session.dispatch(session, :leave, %{player_id: "p2"})
      {:ok, session} = Session.dispatch(session, :start, %{player_id: "p1"})

      assert {:ok, session} = Session.dispatch(session, :join, %{player_id: "p2"})
      assert session.members["p2"] == :online
      assert session.game.players == ["p1", "p2"]

      assert {:error, :invalid_phase} = Session.dispatch(session, :join, %{player_id: "p3"})
    end

    test "leaves mark existing members offline and are forwarded to the game" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, :join, %{player_id: "p2"})

      assert {:ok, session} = Session.dispatch(session, :leave, %{player_id: "p2"})
      assert session.members["p2"] == :offline
      assert session.game.left == ["p2"]

      assert {:ok, session} = Session.dispatch(session, :join, %{player_id: "p2"})
      assert session.members["p2"] == :online

      assert {:ok, ^session} = Session.dispatch(session, :leave, %{player_id: "p3"})
    end

    test "keeps owner membership when the owner leaves immediately after creation" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} = Session.dispatch(session, :leave, %{player_id: "p1"})
      assert session.owner_id == "p1"
      assert session.members["p1"] == :offline

      assert {:ok, session} = Session.dispatch(session, :join, %{player_id: "p1"})
      assert session.members["p1"] == :online
    end
  end

  describe "game events" do
    test "starts the hosted game and delegates commands while in progress" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, %Session{phase: :in_progress, game: %{started?: true}} = session} =
               Session.dispatch(session, :start, %{player_id: "p1"})

      assert {:ok, %Session{phase: :in_progress} = session} =
               Session.dispatch(session, :noop, %{})

      assert {:error, :bad_command} = Session.dispatch(session, :fail, %{})
    end

    test "moves to finished when the hosted game becomes finished" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, :start, %{player_id: "p1"})

      assert {:ok, %Session{phase: :finished, game: %{finished?: true}} = session} =
               Session.dispatch(session, :finish, %{})

      assert {:error, :invalid_phase} = Session.dispatch(session, :noop, %{})
      assert {:error, :invalid_phase} = Session.dispatch(session, :join, %{player_id: "p2"})
      assert {:error, :invalid_phase} = Session.dispatch(session, :leave, %{player_id: "p1"})
    end
  end
end
