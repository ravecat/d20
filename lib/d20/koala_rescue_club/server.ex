defmodule D20.KoalaRescueClub.Server do
  @moduledoc """
  Game server that schedules automatic rolls and optional bot turns.
  """

  use D20.Game.Server

  alias D20.Command
  alias D20.KoalaRescueClub.Bot
  alias D20.Sessions.Session

  @bot_start_timeout 500
  @bot_turn_timeout 700
  @roll_timeout :timer.seconds(1)

  @impl :gen_statem
  def callback_mode, do: [:handle_event_function, :state_enter]

  @impl :gen_statem
  @spec handle_event(:gen_statem.event_type(), term(), term(), state()) ::
          :gen_statem.event_handler_result(term(), state())
  def handle_event(:enter, _old_state, :roll, _data) do
    {:keep_state_and_data, [{:state_timeout, @roll_timeout, :roll}]}
  end

  def handle_event(:enter, _old_state, :ready, {_slug, _engine, %Session{} = session}) do
    cond do
      Bot.enabled?(session) and not Bot.joined?(session) ->
        {:keep_state_and_data, [{:state_timeout, 0, :bot_join}]}

      Bot.enabled?(session) ->
        {:keep_state_and_data, [{:state_timeout, @bot_start_timeout, :bot_start}]}

      true ->
        :keep_state_and_data
    end
  end

  def handle_event(:enter, _old_state, :submit, {_slug, _engine, %Session{} = session}) do
    if Bot.enabled?(session) do
      {:keep_state_and_data, [{:state_timeout, @bot_turn_timeout, :bot_turn}]}
    else
      :keep_state_and_data
    end
  end

  def handle_event(:state_timeout, :bot_join, :ready, {_slug, _engine, %Session{} = session}) do
    command = %Command{
      event: "join",
      actor_id: Bot.id(session.id),
      attrs: Bot.member_attrs(Bot.difficulty(session))
    }

    {:keep_state_and_data,
     [
       {:next_event, :internal, {:dispatch, command}},
       {:state_timeout, @bot_start_timeout, :bot_start}
     ]}
  end

  def handle_event(:state_timeout, :bot_start, :ready, {_slug, _engine, %Session{} = session}) do
    if Bot.enabled?(session) and Bot.joined?(session) do
      command = %Command{event: "start", actor_id: session.owner_id, attrs: %{}}

      {:keep_state_and_data, [{:next_event, :internal, {:dispatch, command}}]}
    else
      :keep_state_and_data
    end
  end

  def handle_event(:state_timeout, :roll, :roll, _data) do
    command = %Command{event: "roll"}

    {:keep_state_and_data, [{:next_event, :internal, {:dispatch, command}}]}
  end

  def handle_event(:state_timeout, :bot_turn, :submit, data) do
    handle_event(:internal, :bot_turn, :submit, data)
  end

  def handle_event(:internal, :bot_turn, :submit, {_slug, _engine, %Session{} = session}) do
    case Bot.next_command(session) do
      {:ok, command} -> {:keep_state_and_data, [{:next_event, :internal, {:dispatch, command}}]}
      :idle -> :keep_state_and_data
    end
  end

  def handle_event(:cast, :bot_turn, _state, _data) do
    {:keep_state_and_data, [{:next_event, :internal, :bot_turn}]}
  end
end
