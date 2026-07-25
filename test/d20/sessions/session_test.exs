defmodule D20.Sessions.SessionTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Game, as: KoalaGame
  alias D20.Qwinto.Game, as: QwintoGame
  alias D20.Sessions.Session

  defmodule TestGame do
    use D20.Game

    @impl D20.Game
    def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    @impl D20.Game
    def init(_attrs), do: {:ok, %{players: [], left: [], started?: false, finished?: false}}

    @impl D20.Game
    def dispatch(state, %Command{event: "join", actor_id: actor_id}) do
      if actor_id in state.players do
        {:ok, state}
      else
        {:ok, update_in(state.players, &(&1 ++ [actor_id]))}
      end
    end

    def dispatch(state, %Command{event: "left", actor_id: actor_id}) do
      {:ok, update_in(state.left, &Enum.uniq(&1 ++ [actor_id]))}
    end

    def dispatch(state, %Command{event: "start"}) when length(state.players) in 1..2 do
      {:ok, %{state | started?: true}}
    end

    def dispatch(_state, %Command{event: "start"}), do: {:error, :invalid_player_count}
    def dispatch(state, %Command{event: "finish"}), do: {:ok, %{state | finished?: true}}
    def dispatch(state, %Command{event: "noop"}), do: {:ok, state}
    def dispatch(_state, %Command{event: "fail"}), do: {:error, :invalid_command}
    def dispatch(_state, %Command{}), do: {:error, :invalid_command}

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
                game: %{players: []}
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

    test "initializes games with creation attrs before the session starts" do
      assert {:ok, %Session{game: %KoalaGame{sheet: :yugambeh}}} =
               Session.new(KoalaGame, "p1", %{"sheet" => "yugambeh"})

      assert {:error, %Ecto.Changeset{valid?: false}} =
               Session.new(KoalaGame, "p1", %{"sheet" => "missing"})

      assert {:ok, %Session{game: %{players: []}}} =
               Session.new(TestGame, "p1", %{"sheet" => "dharug"})
    end
  end

  describe "session events" do
    test "game joins are independent from session membership" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} =
               Session.dispatch(
                 session,
                 TestGame,
                 command("join", "p2", %{
                   display_name: "First name",
                   avatar: "first-avatar",
                   online_at: 10,
                   phx_ref: "connection-ref"
                 })
               )

      assert session.members == %{}
      assert session.game.players == ["p2"]
      assert {:ok, session} = Session.online(session, "p2", %{online_at: 20})

      assert {:ok, session} =
               Session.dispatch(
                 session,
                 TestGame,
                 command("join", "p2", %{display_name: "Updated name", avatar: nil, online_at: 11})
               )

      assert session.members["p2"] == %{status: :online, online_at: 20}
      assert session.game.players == ["p2"]

      assert {:ok, session} = Session.dispatch(session, TestGame, command("join", "p3"))
      refute Map.has_key?(session.members, "p3")
      assert session.game.players == ["p2", "p3"]
    end

    test "propagates game join capacity errors without adding session members" do
      {:ok, session} = Session.new(QwintoGame, "p1")

      {:ok, session} =
        Session.dispatch(session, QwintoGame, command("join", "p1", %{online_at: 10}))

      {:ok, session} =
        Session.dispatch(session, QwintoGame, command("join", "p2", %{online_at: 20}))

      {:ok, session} =
        Session.dispatch(session, QwintoGame, command("join", "p3", %{online_at: 30}))

      {:ok, session} =
        Session.dispatch(session, QwintoGame, command("join", "p4", %{online_at: 40}))

      assert {:error, :invalid_player_count} =
               Session.dispatch(session, QwintoGame, command("join", "p5", %{online_at: 50}))

      assert session.members == %{}
      refute Map.has_key?(session.game.players, "p5")
    end

    test "requires the owner to start the session" do
      {:ok, session} = Session.new(TestGame, "p1")

      {:ok, session} =
        Session.dispatch(session, TestGame, command("join", "p2", %{online_at: 10}))

      assert {:error, :not_owner} = Session.dispatch(session, TestGame, command("start", "p2"))

      assert {:error, :invalid_identity} =
               Session.dispatch(session, TestGame, command("start", ""))
    end

    test "does not pre-validate command payloads" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} = Session.dispatch(session, TestGame, command("join", "p2", []))

      assert session.members == %{}
      assert session.game.players == ["p2"]
    end

    test "accepts string event names" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} =
               Session.dispatch(session, TestGame, command("join", "p2", %{online_at: 10}))

      assert session.members == %{}
      assert session.game.players == ["p2"]
    end

    test "delegates game event names to the game engine" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:error, :invalid_phase} =
               Session.dispatch(session, TestGame, command("not_a_command", "p1"))
    end

    test "routes in-progress joins through the game engine" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, TestGame, command("join", "p1"))
      {:ok, session} = Session.dispatch(session, TestGame, command("start", "p1"))

      assert {:ok, session} =
               Session.dispatch(session, TestGame, command("join", "p3", %{online_at: 13}))

      refute Map.has_key?(session.members, "p3")
      assert session.game.players == ["p1", "p3"]
    end

    test "game leaves retain session members" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.online(session, "p2", %{online_at: 10})

      {:ok, session} =
        Session.dispatch(session, TestGame, command("join", "p2", %{online_at: 10}))

      assert {:ok, session} = Session.dispatch(session, TestGame, command("left", "p2"))
      assert session.members["p2"] == %{status: :online, online_at: 10}
      assert session.game.left == ["p2"]

      assert {:ok, session} =
               Session.dispatch(session, TestGame, command("join", "p2", %{online_at: 12}))

      assert session.members["p2"] == %{status: :online, online_at: 10}

      assert {:ok, session} = Session.dispatch(session, TestGame, command("left", "p3"))
      assert session.game.left == ["p2", "p3"]
    end

    test "keeps owner identity independent from game joins and leaves" do
      {:ok, session} = Session.new(TestGame, "p1")

      assert {:ok, session} = Session.dispatch(session, TestGame, command("left", "p1"))
      assert session.owner_id == "p1"
      assert session.members == %{}
      assert session.game.left == ["p1"]

      assert {:ok, session} =
               Session.dispatch(session, TestGame, command("join", "p1", %{online_at: 14}))

      assert session.members == %{}

      assert {:ok, session} = Session.dispatch(session, TestGame, command("left", "p1"))
      assert session.owner_id == "p1"
      assert session.game.left == ["p1"]
    end

    test "Presence updates membership without reaching the game" do
      {:ok, session} = Session.new(TestGame, "p1")
      game = session.game

      assert {:ok, session} =
               Session.online(session, "p1", %{
                 online_at: 10,
                 display_name: "Forged name",
                 avatar: "forged-avatar",
                 phx_ref: "connection-ref",
                 phx_ref_prev: "previous-ref"
               })

      assert session.members["p1"] == %{
               status: :online,
               online_at: 10,
               display_name: "Forged name",
               avatar: "forged-avatar"
             }

      assert session.game == game

      assert {:ok, session} = Session.offline(session, "p1")
      assert session.members["p1"].status == :offline
      assert session.game == game

      assert {:ok, session} = Session.dispatch(session, TestGame, command("left", "p1"))
      assert session.members["p1"].status == :offline
      assert {:ok, session} = Session.online(session, "p1", %{online_at: 11})
      assert session.members["p1"].status == :online
      assert {:ok, session} = Session.remove_member(session, "p1")
      assert session.members == %{}
      assert {:ok, ^session} = Session.offline(session, "p1")
    end
  end

  describe "game events" do
    test "starts Koala Rescue Club from game players after a pre-start leave" do
      {:ok, session} = Session.new(KoalaGame, "p1", %{"sheet" => "dharug"})
      {:ok, session} = Session.dispatch(session, KoalaGame, command("join", "p1"))
      {:ok, session} = Session.dispatch(session, KoalaGame, command("join", "p2"))

      assert {:ok,
              %Session{
                phase: :waiting_for_players,
                members: %{},
                game: %KoalaGame{phase: :ready, mode: nil, players: %{"p1" => _player}}
              } = session} = Session.dispatch(session, KoalaGame, command("left", "p2"))

      assert {:ok,
              %Session{
                phase: :in_progress,
                game: %KoalaGame{phase: :roll, mode: :solo, players: %{"p1" => _player}}
              }} = Session.dispatch(session, KoalaGame, command("start", "p1"))
    end

    test "starts the hosted game and delegates commands while in progress" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, TestGame, command("join", "p1"))

      assert {:ok, %Session{phase: :in_progress, game: %{started?: true}} = session} =
               Session.dispatch(session, TestGame, command("start", "p1"))

      assert {:ok, %Session{phase: :in_progress} = session} =
               Session.dispatch(session, TestGame, command("noop", "p1"))

      assert {:error, :invalid_command} =
               Session.dispatch(session, TestGame, command("fail", "p1"))
    end

    test "runs Koala Rescue Club through the generic session lifecycle" do
      {:ok, session} = Session.new(KoalaGame, "p1", %{"sheet" => "dharug"})
      {:ok, session} = Session.dispatch(session, KoalaGame, command("join", "p1"))

      assert {:ok,
              %Session{phase: :in_progress, game: %KoalaGame{phase: :roll, mode: :solo}} = session} =
               Session.dispatch(session, KoalaGame, command("start", "p1"))

      assert {:ok,
              %Session{phase: :in_progress, game: %KoalaGame{phase: :submit, mode: :solo}} =
                session} = Session.dispatch(session, KoalaGame, %Command{event: "roll"})

      value = session.game.roll.value

      assert {:ok,
              %Session{phase: :in_progress, game: %KoalaGame{phase: :roll, mode: :solo, turn: 2}}} =
               Session.dispatch(
                 session,
                 KoalaGame,
                 command("circle_tree", "p1", %{
                   "die_value" => value,
                   "volunteers_used" => 0,
                   "target_cell" => %{"area" => "a", "row" => 0, "column" => 0}
                 })
               )
    end

    test "moves to finished when the hosted game becomes finished" do
      {:ok, session} = Session.new(TestGame, "p1")
      {:ok, session} = Session.dispatch(session, TestGame, command("join", "p1"))
      {:ok, session} = Session.dispatch(session, TestGame, command("start", "p1"))

      assert {:ok, %Session{phase: :finished, game: %{finished?: true}} = session} =
               Session.dispatch(session, TestGame, command("finish", "p1"))

      assert {:error, :invalid_phase} = Session.dispatch(session, TestGame, command("noop", "p1"))

      assert {:error, :invalid_phase} = Session.dispatch(session, TestGame, command("join", "p2"))

      assert {:error, :invalid_phase} = Session.dispatch(session, TestGame, command("left", "p1"))
    end
  end

  defp command(event, actor_id, attrs \\ %{}) do
    %Command{event: event, actor_id: actor_id, attrs: attrs}
  end
end
