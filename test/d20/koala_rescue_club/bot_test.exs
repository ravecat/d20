defmodule D20.KoalaRescueClub.BotTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Bot
  alias D20.KoalaRescueClub.Command, as: KoalaCommand
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Rules
  alias D20.Sessions.Session

  test "uses a session-scoped identity and ordinary member attributes" do
    session = bot_session()
    bot_id = Bot.id(session.id)

    assert bot_id == "bot:#{session.id}"
    assert Bot.enabled?(session)
    assert Bot.joined?(session)

    assert %{
             display_name: "Ranger Bot",
             avatar: nil,
             bot: true,
             bot_difficulty: :normal,
             online_at: online_at
           } = Bot.member_attrs()

    assert is_integer(online_at)

    assert {:ok, %{bot: true}} = Map.fetch(session.members, bot_id)
    assert {:ok, _player} = Game.fetch_player(session.game, bot_id)
  end

  test "derives only commands accepted by the real command and rule validators" do
    session = roll(bot_session())
    bot_id = Bot.id(session.id)
    candidates = Bot.candidates(session.game, bot_id)

    assert candidates != []

    assert Enum.all?(candidates, fn command ->
             with {:ok, command} <- KoalaCommand.validate(command) do
               Rules.validate(session.game, command) == :ok
             else
               {:error, _reason} -> false
             end
           end)

    assert {:ok, %Command{actor_id: ^bot_id} = command} = Bot.next_command(session)
    assert command in Bot.strategy_candidates(session.game, candidates)

    assert {:ok, %Session{} = updated} = Session.dispatch(session, Game, command)
    assert updated.game.players[bot_id].status == :submitted
    assert updated.game.players[bot_id].turns == [command.attrs.die_value]

    assert updated.game.players[bot_id].last_action == %{
             turn: 1,
             action: command.event,
             die_value: command.attrs.die_value,
             target_cells: [command.attrs.target_cell]
           }

    assert updated.game.players["owner"].status == :pending
  end

  test "supports a deterministic injected chooser" do
    session = roll(bot_session())
    candidates = Bot.candidates(session.game, Bot.id(session.id))
    strategy_candidates = Bot.strategy_candidates(session.game, candidates)

    assert length(candidates) > 1
    assert {:ok, command} = Bot.next_command(session, &List.last/1)
    assert command == List.last(strategy_candidates)
  end

  test "difficulty controls the legal strategy pool and every level remains non-deterministic" do
    for {difficulty, expected_size} <- [easy: :all, normal: 8, hard: 2] do
      session = roll(bot_session("dharug", Atom.to_string(difficulty)))
      candidates = Bot.candidates(session.game, Bot.id(session.id))
      strategy_candidates = Bot.strategy_candidates(session.game, candidates)

      assert Bot.difficulty(session) == difficulty
      assert length(strategy_candidates) == pool_size(expected_size, candidates)

      :rand.seed(:exsss, {101, 202, 303})

      choices =
        Enum.map(1..24, fn _index ->
          assert {:ok, command} = Bot.next_command(session)
          command
        end)

      assert choices |> Enum.uniq() |> length() > 1
      assert Enum.all?(choices, &(&1 in strategy_candidates))
    end
  end

  test "contains strategy errors instead of crashing the game process" do
    session = roll(bot_session())

    assert :idle = Bot.next_command(session, fn _candidates -> raise "strategy failed" end)
    assert session.game.players[Bot.id(session.id)].status == :pending
  end

  test "does nothing outside its pending turn or after duplicate triggers" do
    session = bot_session()
    assert :idle = Bot.next_command(session)

    session = roll(session)
    assert {:ok, command} = Bot.next_command(session)
    assert {:ok, submitted} = Session.dispatch(session, Game, command)

    assert :idle = Bot.next_command(submitted)

    finished = %{submitted | phase: :finished, game: %{submitted.game | phase: :finished}}

    assert :idle = Bot.next_command(finished)
  end

  test "every difficulty completes a full game on every sheet" do
    for sheet <- ~w(dharug yugambeh), difficulty <- ~w(easy normal hard) do
      seed = :erlang.phash2({sheet, difficulty})
      :rand.seed(:exsss, {seed, seed + 1, seed + 2})

      final_session = Enum.reduce(1..30, bot_session(sheet, difficulty), &play_turn/2)

      assert final_session.phase == :finished
      assert final_session.game.phase == :finished
      assert final_session.game.turn == 30
      assert map_size(final_session.game.scores) == 2

      assert Enum.all?(final_session.game.players, fn {_id, player} ->
               length(player.turns) == 30
             end)
    end
  end

  defp play_turn(expected_turn, session) do
    assert session.phase == :in_progress
    assert session.game.phase == :roll
    assert session.game.turn == expected_turn

    session = roll(session)

    assert {:ok, bot_command} = Bot.next_command(session)
    assert {:ok, session} = Session.dispatch(session, Game, bot_command)

    human_command = session.game |> Bot.candidates("owner") |> List.first()
    assert %Command{actor_id: "owner"} = human_command
    assert {:ok, session} = Session.dispatch(session, Game, human_command)

    session
  end

  defp bot_session(sheet \\ "dharug", difficulty \\ "normal") do
    assert {:ok, session} =
             Session.new(Game, "owner", %{"sheet" => sheet, "opponent" => "bot_#{difficulty}"})

    bot_id = Bot.id(session.id)

    assert {:ok, session} =
             Session.dispatch(session, Game, %Command{
               event: "join",
               actor_id: "owner",
               attrs: %{display_name: "Owner"}
             })

    assert {:ok, session} =
             Session.dispatch(session, Game, %Command{
               event: "join",
               actor_id: bot_id,
               attrs: difficulty |> String.to_existing_atom() |> Bot.member_attrs()
             })

    assert {:ok, session} =
             Session.dispatch(session, Game, %Command{
               event: "start",
               actor_id: "owner",
               attrs: %{}
             })

    session
  end

  defp roll(session) do
    assert {:ok, session} =
             Session.dispatch(session, Game, %Command{event: "roll", actor_id: nil, attrs: %{}})

    session
  end

  defp pool_size(:all, candidates), do: length(candidates)
  defp pool_size(size, candidates), do: min(size, length(candidates))
end
