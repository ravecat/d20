defmodule D20.Sessions.Server do
  @moduledoc """
  Process wrapper that owns one `D20.Sessions.Session` state.
  """

  use GenServer, restart: :temporary

  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel

  @type id :: Session.id()
  @type start_opts :: [session: Session.t()]
  @type state :: Session.t()

  @spec start_link(start_opts()) :: GenServer.on_start()
  def start_link(opts) do
    session = Keyword.fetch!(opts, :session)

    GenServer.start_link(__MODULE__, session, name: via(session.id))
  end

  @impl true
  @spec init(Session.t()) :: {:ok, state()} | {:stop, term()}
  def init(%Session{} = session) do
    case Presence.subscribe(SessionChannel.topic(session.id)) do
      :ok -> {:ok, session}
      {:error, reason} -> {:stop, reason}
    end
  end

  def init(_session) do
    {:stop, :badarg}
  end

  @spec get(GenServer.server()) :: {:ok, state()}
  def get(server) do
    GenServer.call(server, :get)
  end

  @spec dispatch(GenServer.server(), Session.event(), term()) ::
          {:ok, Session.t()} | {:error, Session.reason()}
  def dispatch(server, event, attrs) do
    GenServer.call(server, {:dispatch, event, attrs})
  end

  @impl true
  def handle_call(:get, _from, session) do
    {:reply, {:ok, session}, session}
  end

  def handle_call({:dispatch, event, attrs}, _from, session) do
    case dispatch_to_session(session, event, attrs) do
      {:ok, session} ->
        broadcast_state(session)
        {:reply, {:ok, session}, session}

      {:error, reason} ->
        {:reply, {:error, reason}, session}
    end
  end

  @impl true
  def handle_info({:join, actor_id, member_attrs}, session) do
    handle_presence_event(session, :join, actor_id, member_attrs)
  end

  def handle_info({:left, actor_id}, session) do
    handle_presence_event(session, :leave, actor_id, %{})
  end

  @spec handle_presence_event(state(), :join | :leave, Session.player_id(), map()) ::
          {:noreply, state()}
  defp handle_presence_event(session, event, actor_id, member_attrs) do
    attrs = Map.put(member_attrs, :player_id, actor_id)

    case dispatch_to_session(session, event, attrs) do
      {:ok, session} ->
        broadcast_state(session)
        {:noreply, session}

      {:error, _reason} ->
        {:noreply, session}
    end
  end

  @spec dispatch_to_session(state(), Session.event(), term()) ::
          {:ok, state()} | {:error, Session.reason()}
  defp dispatch_to_session(%Session{} = session, event, attrs) do
    Session.dispatch(session, event, attrs)
  end

  @spec broadcast_state(state()) :: :ok
  defp broadcast_state(session) do
    Phoenix.PubSub.local_broadcast(
      D20.PubSub,
      SessionChannel.topic(session.id),
      {:session, session}
    )
  end

  defp via(id) do
    {:via, Registry, {D20.Registry, {:session, id}}}
  end
end
