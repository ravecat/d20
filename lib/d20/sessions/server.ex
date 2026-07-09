defmodule D20.Sessions.Server do
  @moduledoc """
  Process wrapper that owns one `D20.Sessions.Session` state.
  """

  use D20.Game.Server, otp: :gen_server

  alias D20.Accounts
  alias D20.Command
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel

  @type id :: Session.id()
  @type slug :: String.t()

  @impl true
  @spec init(state()) :: {:ok, state(), timeout()} | {:stop, term()}
  def init({slug, engine, %Session{} = session}) when is_binary(slug) and is_atom(engine) do
    case Presence.subscribe(SessionChannel.topic(session.id)) do
      :ok -> {:ok, {slug, engine, session}, timeout()}
      {:error, reason} -> {:stop, reason}
    end
  end

  def init(_state) do
    {:stop, :badarg}
  end

  @impl true
  def handle_call(:get, _from, {slug, _engine, session} = state) do
    {:reply, {:ok, {session, slug}}, state, timeout()}
  end

  def handle_call({:dispatch, %Command{} = command}, _from, {slug, engine, session} = state) do
    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} ->
        broadcast_state(updated_session)

        {:reply, {:ok, updated_session}, {slug, engine, updated_session}, timeout()}

      {:error, reason} ->
        {:reply, {:error, reason}, state, timeout()}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  def handle_info({:join, actor_id, member_attrs}, state) when is_map(member_attrs) do
    profile = Accounts.get_user_or_anonymous(actor_id)

    member_attrs =
      Map.merge(member_attrs, %{display_name: profile.display_name, avatar: profile.avatar})

    handle_presence_event(state, "join", actor_id, member_attrs)
  end

  def handle_info({:left, actor_id}, state) do
    handle_presence_event(state, "leave", actor_id, %{})
  end

  @spec handle_presence_event(state(), String.t(), Session.player_id(), map()) ::
          {:noreply, state(), timeout()}
  defp handle_presence_event({slug, engine, session} = state, event, actor_id, attrs) do
    command = %Command{event: event, actor_id: actor_id, attrs: attrs}

    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} ->
        broadcast_state(updated_session)
        {:noreply, {slug, engine, updated_session}, timeout()}

      {:error, _reason} ->
        {:noreply, state, timeout()}
    end
  end

  @spec broadcast_state(Session.t()) :: :ok
  defp broadcast_state(session) do
    Phoenix.PubSub.local_broadcast(
      D20.PubSub,
      SessionChannel.topic(session.id),
      {:session, session}
    )
  end

  @spec timeout() :: timeout()
  defp timeout do
    Application.fetch_env!(:d20, :session_idle_timeout)
  end
end
