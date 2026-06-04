defmodule D20.Sessions.Server do
  @moduledoc """
  Process wrapper that owns one `D20.Sessions.Session` state.
  """

  use GenServer, restart: :temporary

  alias D20.Accounts
  alias D20.Sessions.Command
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel

  @type id :: Session.id()
  @type slug :: String.t()
  @type start_opts :: [slug: slug(), engine: D20.Game.engine(), session: Session.t()]
  @type state :: {slug(), D20.Game.engine(), Session.t()}

  @spec registry_key(id()) :: {:session, id()}
  def registry_key(id) when is_binary(id), do: {:session, id}

  @spec start_link(start_opts()) :: GenServer.on_start()
  def start_link(opts) do
    slug = Keyword.fetch!(opts, :slug)
    engine = Keyword.fetch!(opts, :engine)
    session = Keyword.fetch!(opts, :session)

    GenServer.start_link(__MODULE__, {slug, engine, session}, name: via(session.id))
  end

  @impl true
  @spec init(state()) :: {:ok, state()} | {:stop, term()}
  def init({slug, engine, %Session{} = session}) when is_binary(slug) and is_atom(engine) do
    case Presence.subscribe(SessionChannel.topic(session.id)) do
      :ok -> {:ok, {slug, engine, session}}
      {:error, reason} -> {:stop, reason}
    end
  end

  def init(_state) do
    {:stop, :badarg}
  end

  @spec get(GenServer.server()) :: {:ok, {Session.t(), slug()}}
  def get(server) do
    GenServer.call(server, :get)
  end

  @spec dispatch(GenServer.server(), Command.t()) ::
          {:ok, Session.t()} | {:error, Session.reason()}
  def dispatch(server, %Command{} = command) do
    GenServer.call(server, {:dispatch, command})
  end

  @impl true
  def handle_call(:get, _from, {slug, _engine, session} = state) do
    {:reply, {:ok, {session, slug}}, state}
  end

  def handle_call({:dispatch, %Command{} = command}, _from, {slug, engine, session} = state) do
    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} ->
        broadcast_state(updated_session)
        {:reply, {:ok, updated_session}, {slug, engine, updated_session}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
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
          {:noreply, state()}
  defp handle_presence_event({slug, engine, session} = state, event, actor_id, attrs) do
    command = %Command{event: event, actor_id: actor_id, attrs: attrs}

    case Session.dispatch(session, engine, command) do
      {:ok, updated_session} ->
        broadcast_state(updated_session)
        {:noreply, {slug, engine, updated_session}}

      {:error, _reason} ->
        {:noreply, state}
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

  defp via(id) do
    {:via, Registry, {D20.Registry, registry_key(id)}}
  end
end
