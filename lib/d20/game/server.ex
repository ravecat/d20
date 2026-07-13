defmodule D20.Game.Server do
  @moduledoc """
  Default game-session server and `:gen_statem` adapter for custom servers.

  The module is the fallback process for engines without a custom server.
  Custom servers inherit the default Presence, session, publication, and idle
  behavior and override standard `:gen_statem` callbacks when required:

      use D20.Game.Server

  Custom `handle_event/4` clauses run before an automatically generated
  fallback to the default implementation.
  """

  @behaviour :gen_statem

  alias D20.Accounts
  alias D20.Command
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel

  @type opts :: [slug: Sessions.slug(), engine: D20.Game.engine(), session: Session.t()]
  @type state :: {Sessions.slug(), D20.Game.engine(), Session.t()}

  @callback start_link(opts()) :: :gen_statem.start_ret()
  @callback get(:gen_statem.server_ref()) :: {:ok, {Session.t(), Sessions.slug()}}
  @callback dispatch(:gen_statem.server_ref(), Command.t()) ::
              {:ok, Session.t()} | {:error, Session.reason()}

  defmacro __using__([]) do
    quote do
      @behaviour D20.Game.Server
      @behaviour :gen_statem
      @before_compile D20.Game.Server

      @type opts :: D20.Game.Server.opts()
      @type state :: D20.Game.Server.state()

      @spec child_spec(opts()) :: Supervisor.child_spec()
      def child_spec(opts), do: D20.Game.Server.child_spec(__MODULE__, opts)

      @impl D20.Game.Server
      @spec start_link(opts()) :: :gen_statem.start_ret()
      def start_link(opts), do: D20.Game.Server.start_link(__MODULE__, opts)

      @impl D20.Game.Server
      @spec get(:gen_statem.server_ref()) ::
              {:ok, {D20.Sessions.Session.t(), D20.Sessions.slug()}}
      def get(server), do: D20.Game.Server.get(server)

      @impl D20.Game.Server
      @spec dispatch(:gen_statem.server_ref(), D20.Command.t()) ::
              {:ok, D20.Sessions.Session.t()} | {:error, D20.Sessions.Session.reason()}
      def dispatch(server, %D20.Command{} = command) do
        D20.Game.Server.dispatch(server, command)
      end

      @impl :gen_statem
      def callback_mode, do: :handle_event_function

      defoverridable child_spec: 1,
                     start_link: 1,
                     get: 1,
                     dispatch: 2,
                     callback_mode: 0
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @impl :gen_statem
      @spec init(state()) :: :gen_statem.init_result(D20.Sessions.Session.phase(), state())
      def init(data), do: D20.Game.Server.init(data)

      @impl :gen_statem
      @spec handle_event(:gen_statem.event_type(), term(), term(), state()) ::
              :gen_statem.event_handler_result(term(), state())
      def handle_event(event_type, event_content, state, data) do
        D20.Game.Server.handle_event(event_type, event_content, state, data)
      end
    end
  end

  @spec child_spec(opts()) :: Supervisor.child_spec()
  def child_spec(opts), do: child_spec(__MODULE__, opts)

  @doc false
  @spec child_spec(module(), opts()) :: Supervisor.child_spec()
  def child_spec(server, opts) do
    %{id: server, start: {server, :start_link, [opts]}, restart: :temporary}
  end

  @spec start_link(opts()) :: :gen_statem.start_ret()
  def start_link(opts), do: start_link(__MODULE__, opts)

  @doc false
  @spec start_link(module(), opts()) :: :gen_statem.start_ret()
  def start_link(server, opts) do
    slug = Keyword.fetch!(opts, :slug)
    engine = Keyword.fetch!(opts, :engine)
    session = Keyword.fetch!(opts, :session)

    :gen_statem.start_link(Sessions.via(session.id, server), server, {slug, engine, session}, [])
  end

  @impl :gen_statem
  @spec init(state()) :: :gen_statem.init_result(Session.phase(), state())
  def init({slug, engine, %Session{phase: phase}} = data)
      when is_binary(slug) and is_atom(engine) do
    {:ok, phase, data}
  end

  def init(_data), do: {:stop, :badarg}

  @spec get(:gen_statem.server_ref()) :: {:ok, {Session.t(), Sessions.slug()}}
  def get(server), do: :gen_statem.call(server, :get)

  @spec dispatch(:gen_statem.server_ref(), Command.t()) ::
          {:ok, Session.t()} | {:error, Session.reason()}
  def dispatch(server, %Command{} = command) do
    :gen_statem.call(server, {:dispatch, command})
  end

  @impl :gen_statem
  def callback_mode, do: :handle_event_function

  @impl :gen_statem
  def handle_event({:call, from}, :get, _state, {slug, _engine, session}) do
    {:keep_state_and_data, [{:reply, from, {:ok, {session, slug}}}, idle()]}
  end

  def handle_event(:info, :presence, _state, {_slug, _engine, session} = data) do
    case Presence.subscribe(SessionChannel.topic(session.id)) do
      :ok -> {:keep_state_and_data, [idle()]}
      {:error, reason} -> {:stop, reason, data}
    end
  end

  def handle_event(
        {:call, from},
        {:dispatch, %Command{} = command},
        state,
        {slug, engine, session}
      ) do
    case Session.dispatch(session, engine, command) do
      {:ok, %Session{phase: next_state} = updated_session} ->
        broadcast(updated_session)

        data = {slug, engine, updated_session}

        actions = [{:reply, from, {:ok, updated_session}}, idle()]

        if next_state == state do
          {:keep_state, data, actions}
        else
          {:next_state, next_state, data, actions}
        end

      {:error, reason} ->
        {:keep_state_and_data, [{:reply, from, {:error, reason}}, idle()]}
    end
  end

  def handle_event(:internal, {:dispatch, %Command{} = command}, state, {slug, engine, session}) do
    case Session.dispatch(session, engine, command) do
      {:ok, %Session{phase: next_state} = updated_session} ->
        broadcast(updated_session)

        data = {slug, engine, updated_session}

        if next_state == state do
          {:keep_state, data, [idle()]}
        else
          {:next_state, next_state, data, [idle()]}
        end

      {:error, _reason} ->
        {:keep_state_and_data, [idle()]}
    end
  end

  def handle_event(:info, {:join, actor_id, attrs}, _state, _data) when is_map(attrs) do
    profile = Accounts.get_user_or_anonymous(actor_id)
    member = Map.merge(attrs, Map.take(profile, [:display_name, :avatar]))
    command = %Command{event: "join", actor_id: actor_id, attrs: member}

    {:keep_state_and_data, [{:next_event, :internal, {:dispatch, command}}]}
  end

  def handle_event(:info, {:left, actor_id}, _state, _data) do
    command = %Command{event: "leave", actor_id: actor_id, attrs: %{}}

    {:keep_state_and_data, [{:next_event, :internal, {:dispatch, command}}]}
  end

  def handle_event({:timeout, :idle}, :expire, _state, data) do
    {:stop, :normal, data}
  end

  def handle_event(_event_type, _event_content, _state, _data), do: :keep_state_and_data

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
