defmodule D20.NextStationLondon.SessionTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.NextStationLondon.Game
  alias D20.Sessions.Session

  test "creates optional modules before runtime and rejects malformed creation attrs" do
    assert {:ok, %Session{game: %Game{objectives: [], powers: %{}}}} =
             Session.new(Game, "owner", %{"objectives" => true, "powers" => true})

    assert {:error, %Ecto.Changeset{valid?: false}} =
             Session.new(Game, "owner", %{"objectives" => "enabled"})
  end

  test "keeps frozen players through membership changes and propagates final game state" do
    {:ok, session} = Session.new(Game, "owner")
    {:ok, session} = Session.dispatch(session, Game, command("join", "owner"))

    {:ok, session} = Session.dispatch(session, Game, command("start", "owner"))

    player = %{session.game.players["owner"] | pencil_offset: 0}

    session = %{
      session
      | game: %{
          session.game
          | round: 4,
            pencil_cycle: [:green, :blue, :pink, :purple],
            players: %{"owner" => player}
        }
    }

    {:ok, session} =
      Session.dispatch(session, Game, %Command{
        event: "prepare_round",
        attrs: %{deck: final_deck()}
      })

    {:ok, session} = Session.dispatch(session, Game, command("leave", "owner"))
    assert session.members == %{}
    assert Map.has_key?(session.game.players, "owner")

    {:ok, session} = Session.dispatch(session, Game, command("join", "spectator"))
    refute Map.has_key?(session.game.players, "spectator")
    assert {:error, :not_joined} = Session.dispatch(session, Game, command("pass", "spectator"))

    session =
      Enum.reduce(1..5, session, fn _turn, session ->
        {:ok, session} = Session.dispatch(session, Game, command("pass", "owner"))
        session
      end)

    assert session.phase == :finished
    assert session.game.phase == :finished
  end

  defp final_deck do
    ~w(
      underground_circle
      underground_square
      underground_triangle
      underground_pentagon
      underground_joker
      street_circle
      street_square
      street_triangle
      street_pentagon
      street_joker
      street_railroad_switch
    )
  end

  defp command(event, actor_id, attrs \\ %{}) do
    %Command{event: event, actor_id: actor_id, attrs: attrs}
  end
end
