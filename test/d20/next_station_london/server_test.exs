defmodule D20.NextStationLondon.ServerTest do
  use D20.DataCase, async: false

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Command
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Rules
  alias D20.NextStationLondon.Ruleset
  alias D20.NextStationLondon.Server
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.SessionChannel

  setup do
    assert {:ok, %Session{} = session} =
             Sessions.create("next-station-london", Game, "owner", %{
               "objectives" => true,
               "powers" => true
             })

    on_exit(fn -> Sessions.stop(session.id) end)

    assert [{pid, Server}] = Registry.lookup(D20.Registry, {:session, session.id})
    assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(session.id))

    send(pid, {:online, "owner", %{online_at: 1}})

    assert_receive {:session, %Session{game: %Game{phase: :ready}} = joined}

    %{pid: pid, session: joined}
  end

  test "uses the game phase as state and automatically prepares exactly one valid round", %{
    pid: pid,
    session: session
  } do
    assert {:ready, {"next-station-london", Game, ^session}} = :sys.get_state(pid)

    assert {:ok, %Session{game: %Game{phase: :preparing_round}} = started} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, ^started}

    assert_receive {:session,
                    %Session{
                      game: %Game{phase: :build, objectives: objectives, powers: powers} = game
                    } = prepared}

    assert length(objectives) == 2
    assert MapSet.new(Map.keys(powers)) == MapSet.new(Ruleset.colors())
    assert MapSet.new(Map.values(powers)) == MapSet.new(Ruleset.power_ids())
    assert game.players["owner"].pencil_offset == 0
    assert game.players["owner"].status == :pending
    assert MapSet.new(game.pencil_cycle) == MapSet.new(Ruleset.colors())
    assert {:ok, List.first(game.pencil_cycle)} == Rules.current_color(game, "owner")

    prepared_cards = Enum.flat_map(game.draws, & &1.cards) ++ game.remaining_deck
    assert Ruleset.valid_deck_permutation?(prepared_cards)

    assert {:build, {"next-station-london", Game, ^prepared}} = :sys.get_state(pid)
    assert {:ok, {^prepared, "next-station-london"}} = Sessions.get(session.id)
    refute_receive {:session, %Session{game: %Game{phase: :build}}}, 100
  end

  test "keeps client preparation actor-bound and does not replace the committed setup", %{
    session: session
  } do
    assert {:ok, %Session{game: %Game{phase: :preparing_round}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, %Session{game: %Game{phase: :preparing_round}}}
    assert_receive {:session, %Session{game: %Game{phase: :build}} = prepared}

    attrs = Server.prepare_command(prepared.game).attrs

    assert {:error, :invalid_phase} = Sessions.dispatch(scope(session.id), "prepare_round", attrs)

    assert {:ok, {^prepared, "next-station-london"}} = Sessions.get(session.id)
    refute_receive {:session, _updated}, 100
  end

  test "terminates an invalid internally generated setup with an observable reason" do
    player = Game.initial_player()

    game = %Game{phase: :preparing_round, round: 1, players: %{"owner" => player}}

    session = %Session{
      id: Ecto.UUID.generate(),
      phase: :in_progress,
      owner_id: "owner",
      game: game
    }

    data = {"next-station-london", Game, session}
    invalid = %Command{event: "prepare_round", attrs: %{deck: []}}

    assert {:stop, {:invalid_random_setup, :invalid_system_setup}, ^data} =
             Server.handle_event(
               :state_timeout,
               {:prepare_round, invalid},
               :preparing_round,
               data
             )
  end

  test "preserves idle expiration alongside automatic preparation", %{pid: pid, session: session} do
    original_timeout = Application.fetch_env!(:d20, :session_idle_timeout)
    on_exit(fn -> Application.put_env(:d20, :session_idle_timeout, original_timeout) end)
    Application.put_env(:d20, :session_idle_timeout, 300)

    assert {:ok, %Session{game: %Game{phase: :preparing_round}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, %Session{game: %Game{phase: :preparing_round}}}
    assert_receive {:session, %Session{game: %Game{phase: :build}}}

    monitor_ref = Process.monitor(pid)
    refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 150

    assert {:ok, {%Session{game: %Game{phase: :build}}, "next-station-london"}} =
             Sessions.get(session.id)

    refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 175
    assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 300
  end

  defp scope(session_id) do
    %Actor{id: "owner", type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game("next-station-london")
  end
end
