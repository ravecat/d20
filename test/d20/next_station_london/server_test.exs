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
    assert {:ok, _game} = D20.Games.update(game_fixture(353_545), %{stage: :released})
    game_id = game_id(353_545)

    assert {:ok, %Session{} = session} =
             Sessions.create(game_id, Game, "owner", %{"objectives" => true, "powers" => true})

    on_exit(fn -> Sessions.stop(session.id) end)

    assert [{pid, Server}] = Registry.lookup(D20.Registry, {:session, session.id})
    assert :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(session.id))

    send(pid, {:online, "owner", %{online_at: 1}})

    assert_receive {:session, %Session{game: %Game{phase: :setup}} = joined}

    %{pid: pid, session: joined, game_id: game_id}
  end

  test "uses the game phase as state and automatically reveals exactly one instruction", %{
    pid: pid,
    session: session,
    game_id: game_id
  } do
    assert {:setup, {^game_id, Game, ^session}} = :sys.get_state(pid)

    assert {:ok, %Session{game: %Game{phase: :reveal}} = started} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, ^started}

    assert_receive {:session,
                    %Session{
                      game: %Game{phase: :turn, objectives: objectives, powers: powers} = game
                    } = prepared}

    assert Enum.count_until(objectives, 3) == 2
    assert MapSet.new(Map.keys(powers)) == MapSet.new(Ruleset.colors())
    assert MapSet.new(Map.values(powers)) == MapSet.new(Ruleset.power_ids())
    assert game.players["owner"].pencil_offset == 0
    assert game.players["owner"].status == :pending
    assert MapSet.new(game.pencil_cycle) == MapSet.new(Ruleset.colors())
    assert {:ok, List.first(game.pencil_cycle)} == Rules.current_color(game, "owner")

    prepared_cards = Enum.flat_map(game.draws, & &1.cards) ++ game.remaining_deck
    assert Ruleset.valid_deck_permutation?(prepared_cards)

    assert {:turn, {^game_id, Game, ^prepared}} = :sys.get_state(pid)
    assert {:ok, {^prepared, ^game_id}} = Sessions.get(session.id)
    refute_receive {:session, %Session{game: %Game{phase: :turn}}}, 100
  end

  test "keeps client reveal actor-bound and does not replace the committed setup", %{
    session: session
  } do
    assert {:ok, %Session{game: %Game{phase: :reveal}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, %Session{game: %Game{phase: :reveal}}}
    assert_receive {:session, %Session{game: %Game{phase: :turn}} = prepared}

    attrs = Server.reveal_command(prepared.game).attrs

    assert {:error, :invalid_phase} = Sessions.dispatch(scope(session.id), "reveal", attrs)

    assert {:ok, {^prepared, _game_id}} = Sessions.get(session.id)
    refute_receive {:session, _updated}, 100
  end

  test "terminates an invalid internally generated setup with an observable reason" do
    player = Game.initial_player()

    game = %Game{phase: :reveal, round: 1, players: %{"owner" => player}}

    session = %Session{
      id: Ecto.UUID.generate(),
      phase: :in_progress,
      owner_id: "owner",
      game: game
    }

    data = {game_id(353_545), Game, session}
    invalid = %Command{event: "reveal", attrs: %{deck: []}}

    assert {:stop, {:invalid_random_setup, :invalid_system_setup}, ^data} =
             Server.handle_event(:state_timeout, {:reveal, invalid}, :reveal, data)
  end

  test "preserves idle expiration alongside automatic preparation", %{pid: pid, session: session} do
    original_timeout = Application.fetch_env!(:d20, :session_idle_timeout)
    on_exit(fn -> Application.put_env(:d20, :session_idle_timeout, original_timeout) end)
    Application.put_env(:d20, :session_idle_timeout, 300)

    assert {:ok, %Session{game: %Game{phase: :reveal}}} =
             Sessions.dispatch(scope(session.id), "start", %{})

    assert_receive {:session, %Session{game: %Game{phase: :reveal}}}
    assert_receive {:session, %Session{game: %Game{phase: :turn}}}

    monitor_ref = Process.monitor(pid)
    refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 150

    assert {:ok, {%Session{game: %Game{phase: :turn}}, _game_id}} = Sessions.get(session.id)

    refute_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 175
    assert_receive {:DOWN, ^monitor_ref, :process, ^pid, :normal}, 300
  end

  defp scope(session_id) do
    %Actor{id: "owner", type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game(game_id(353_545))
  end
end
