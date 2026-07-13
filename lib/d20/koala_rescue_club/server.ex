defmodule D20.KoalaRescueClub.Server do
  @moduledoc """
  Game server that owns Koala Rescue Club state transitions and roll scheduling.
  """

  use D20.Game.Server, otp: :gen_statem

  alias D20.Accounts
  alias D20.Command
  alias D20.KoalaRescueClub.Game
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel

  @roll_timeout :timer.seconds(3)

  @typep phase :: :setup | :ready | :roll | :submit | :finished

  @impl :gen_statem
  @spec init(state()) :: :gen_statem.init_result(phase(), state())
  def init({_slug, _engine, %Session{game: %Game{phase: phase}} = session} = data) do
    case Presence.subscribe(SessionChannel.topic(session.id)) do
      :ok -> {:ok, phase, data, [idle()]}
      {:error, reason} -> {:stop, reason}
    end
  end

  def init(_data), do: {:stop, :badarg}

  @impl :gen_statem
  def handle_event(:enter, _old_state, _state, _data), do: :keep_state_and_data

  def handle_event({:call, from}, :get, _state, {slug, _engine, session}) do
    {:keep_state_and_data, [{:reply, from, {:ok, {session, slug}}}, idle()]}
  end

  def handle_event(
        {:call, from},
        {:dispatch, %Command{} = command},
        state,
        {_slug, engine, session} = data
      ) do
    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} -> transition(state, data, updated_session, from)
      {:error, reason} -> {:keep_state_and_data, [{:reply, from, {:error, reason}}, idle()]}
    end
  end

  def handle_event(
        :state_timeout,
        :roll,
        :roll,
        {_slug, engine, %Session{game: %Game{order: [actor_id | _rest]}} = session} = data
      ) do
    command = %Command{event: "roll", actor_id: actor_id, attrs: %{}}

    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} -> transition(:roll, data, updated_session, nil)
      {:error, reason} -> {:stop, {:automatic_roll_failed, reason}, data}
    end
  end

  def handle_event(:state_timeout, :roll, _state, _data) do
    {:keep_state_and_data, [idle()]}
  end

  def handle_event(:info, {:join, actor_id, attrs}, state, data) when is_map(attrs) do
    profile = Accounts.get_user_or_anonymous(actor_id)
    member = Map.merge(attrs, Map.take(profile, [:display_name, :avatar]))

    handle_presence_event(state, data, "join", actor_id, member)
  end

  def handle_event(:info, {:left, actor_id}, state, data) do
    handle_presence_event(state, data, "leave", actor_id, %{})
  end

  def handle_event({:timeout, :idle}, :expire, _state, data) do
    {:stop, :normal, data}
  end

  def handle_event(_event_type, _event_content, _state, _data), do: :keep_state_and_data

  defp transition(state, {slug, engine, _session}, session, from) do
    {session, roll_actions} = schedule_roll(state, session)
    %Session{game: %Game{phase: next_state}} = session

    broadcast(session)

    actions = reply_actions(from, session) ++ roll_actions ++ [idle()]
    data = {slug, engine, session}

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

  defp reply_actions(nil, _session), do: []
  defp reply_actions(from, session), do: [{:reply, from, {:ok, session}}]

  defp handle_presence_event(state, {_slug, engine, session} = data, event, actor_id, attrs) do
    command = %Command{event: event, actor_id: actor_id, attrs: attrs}

    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} -> transition(state, data, updated_session, nil)
      {:error, _reason} -> {:keep_state_and_data, [idle()]}
    end
  end

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
