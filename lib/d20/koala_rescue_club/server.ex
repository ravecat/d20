defmodule D20.KoalaRescueClub.Server do
  @moduledoc """
  Game server that owns Koala Rescue Club state transitions and roll scheduling.
  """

  use D20.Game.Server

  alias D20.Command
  alias D20.KoalaRescueClub.Game
  alias D20.Sessions.Session
  alias D20Web.SessionChannel

  @roll_timeout :timer.seconds(3)

  @typep phase :: :setup | :ready | :roll | :submit | :finished

  @impl :gen_statem
  @spec init(state()) :: :gen_statem.init_result(phase(), state())
  def init({_slug, _engine, %Session{game: %Game{phase: phase}}} = data) do
    {:ok, phase, data}
  end

  @impl :gen_statem
  def handle_event(
        {:call, from},
        {:dispatch, %Command{} = command},
        state,
        {_slug, engine, session} = data
      ) do
    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} ->
        {session, roll_actions} = schedule_roll(state, updated_session)
        transition(state, data, session, [{:reply, from, {:ok, session}} | roll_actions])

      {:error, reason} ->
        {:keep_state_and_data, [{:reply, from, {:error, reason}}, idle()]}
    end
  end

  def handle_event(
        :internal,
        {:dispatch, %Command{} = command},
        state,
        {_slug, engine, session} = data
      ) do
    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} ->
        {session, roll_actions} = schedule_roll(state, updated_session)
        transition(state, data, session, roll_actions)

      {:error, _reason} ->
        {:keep_state_and_data, [idle()]}
    end
  end

  def handle_event(:state_timeout, :roll, :roll, {_slug, engine, %Session{} = session} = data) do
    command = %Command{event: "roll"}

    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} -> transition(:roll, data, updated_session, [])
      {:error, reason} -> {:stop, {:automatic_roll_failed, reason}, data}
    end
  end

  def handle_event(:state_timeout, :roll, _state, _data) do
    {:keep_state_and_data, [idle()]}
  end

  defp transition(state, {slug, engine, _session}, session, actions) do
    %Session{game: %Game{phase: next_state}} = session

    broadcast(session)

    data = {slug, engine, session}
    actions = actions ++ [idle()]

    if next_state == state do
      {:keep_state, data, actions}
    else
      {:next_state, next_state, data, actions}
    end
  end

  defp schedule_roll(state, %Session{game: %Game{phase: :roll, roll: nil} = game} = session)
       when state != :roll do
    roll_due_at = System.system_time(:millisecond) + @roll_timeout

    {%{session | game: %{game | roll_due_at: roll_due_at}},
     [{:state_timeout, @roll_timeout, :roll}]}
  end

  defp schedule_roll(_state, %Session{} = session), do: {session, []}

  defp broadcast(session) do
    Phoenix.PubSub.local_broadcast(
      D20.PubSub,
      SessionChannel.topic(session.id),
      {:session, session}
    )
  end

  defp idle do
    {{:timeout, :idle}, Application.fetch_env!(:d20, :session_idle_timeout), :expire}
  end
end
