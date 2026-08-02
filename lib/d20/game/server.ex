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

  alias D20.Command
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel
  alias D20Web.Workspace

  @type opts :: [slug: Sessions.slug(), engine: D20.Game.engine(), session: Session.t()]
  @type state :: {Sessions.slug(), D20.Game.engine(), Session.t()}

  @callback start_link(opts()) :: :gen_statem.start_ret()
  @callback get(:gen_statem.server_ref()) :: {:ok, {Session.t(), Sessions.slug()}}
  @callback attach(:gen_statem.server_ref(), Session.player_id()) :: :ok
  @callback detach(:gen_statem.server_ref(), Session.player_id()) :: :ok
  @callback dispatch(:gen_statem.server_ref(), Command.t()) ::
              {:ok, Session.t()} | {:error, Session.reason()}
  @callback preview(:gen_statem.server_ref(), Command.t()) ::
              {:ok, map()} | {:error, Session.reason()}

  defmacro __using__([]) do
    quote do
      @behaviour D20.Game.Server
      @behaviour :gen_statem
      @before_compile D20.Game.Server

      import D20.Game.Server, only: [broadcast: 2, idle_action: 0]

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
      @spec attach(:gen_statem.server_ref(), D20.Sessions.Session.player_id()) :: :ok
      def attach(server, actor_id), do: D20.Game.Server.attach(server, actor_id)

      @impl D20.Game.Server
      @spec detach(:gen_statem.server_ref(), D20.Sessions.Session.player_id()) :: :ok
      def detach(server, actor_id), do: D20.Game.Server.detach(server, actor_id)

      @impl D20.Game.Server
      @spec dispatch(:gen_statem.server_ref(), D20.Command.t()) ::
              {:ok, D20.Sessions.Session.t()} | {:error, D20.Sessions.Session.reason()}
      def dispatch(server, %D20.Command{} = command) do
        D20.Game.Server.dispatch(server, command)
      end

      @impl D20.Game.Server
      @spec preview(:gen_statem.server_ref(), D20.Command.t()) ::
              {:ok, map()} | {:error, D20.Sessions.Session.reason()}
      def preview(server, %D20.Command{} = command) do
        D20.Game.Server.preview(server, command)
      end

      @impl :gen_statem
      def callback_mode, do: :handle_event_function

      defoverridable child_spec: 1,
                     start_link: 1,
                     get: 1,
                     attach: 2,
                     detach: 2,
                     dispatch: 2,
                     preview: 2,
                     callback_mode: 0
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @impl :gen_statem
      @spec init(state()) :: :gen_statem.init_result(term(), state())
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
  @spec init(state()) :: :gen_statem.init_result(term(), state())
  def init({slug, engine, %Session{} = session} = data)
      when is_binary(slug) and is_atom(engine) do
    {:ok, state(session), data}
  end

  def init(_data), do: {:stop, :badarg}

  @spec get(:gen_statem.server_ref()) :: {:ok, {Session.t(), Sessions.slug()}}
  def get(server), do: :gen_statem.call(server, :get)

  @spec attach(:gen_statem.server_ref(), Session.player_id()) :: :ok
  def attach(server, actor_id), do: :gen_statem.call(server, {:attach, actor_id})

  @spec detach(:gen_statem.server_ref(), Session.player_id()) :: :ok
  def detach(server, actor_id), do: :gen_statem.call(server, {:detach, actor_id})

  @spec dispatch(:gen_statem.server_ref(), Command.t()) ::
          {:ok, Session.t()} | {:error, Session.reason()}
  def dispatch(server, %Command{} = command) do
    :gen_statem.call(server, {:dispatch, command})
  end

  @spec preview(:gen_statem.server_ref(), Command.t()) ::
          {:ok, map()} | {:error, Session.reason()}
  def preview(server, %Command{} = command) do
    :gen_statem.call(server, {:preview, command})
  end

  @impl :gen_statem
  def callback_mode, do: :handle_event_function

  @impl :gen_statem
  def handle_event({:call, from}, :get, _state, {slug, _engine, session}) do
    {:keep_state_and_data, [{:reply, from, {:ok, {session, slug}}}, idle_action()]}
  end

  def handle_event(:info, :presence, _state, {_slug, _engine, session} = data) do
    case Presence.subscribe(session.id) do
      :ok -> {:keep_state_and_data, [idle_action()]}
      {:error, reason} -> {:stop, reason, data}
    end
  end

  def handle_event({:call, from}, {:attach, actor_id}, _state, {_slug, _engine, session}) do
    actor_id
    |> Sessions.Registry.attach(session.id)
    |> publish_attachment(actor_id)

    {:keep_state_and_data, [{:reply, from, :ok}, idle_action()]}
  end

  def handle_event({:call, from}, {:detach, actor_id}, state, {slug, engine, session}) do
    attachment_change = Sessions.Registry.detach(actor_id)

    case Session.offline(session, actor_id) do
      {:ok, ^session} ->
        publish_attachment(attachment_change, actor_id)
        {:keep_state_and_data, [{:reply, from, :ok}, idle_action()]}

      {:ok, %Session{} = updated_session} ->
        broadcast(session, updated_session)
        publish_attachment(attachment_change, actor_id)

        data = {slug, engine, updated_session}
        next_state = state(updated_session)
        actions = [{:reply, from, :ok}, idle_action()]

        if next_state == state do
          {:keep_state, data, actions}
        else
          {:next_state, next_state, data, actions}
        end
    end
  end

  def handle_event(
        {:call, from},
        {:dispatch, %Command{} = command},
        state,
        {slug, engine, session}
      ) do
    case Session.dispatch(session, engine, command) do
      {:ok, ^session} ->
        {:keep_state_and_data, [{:reply, from, {:ok, session}}, idle_action()]}

      {:ok, %Session{} = updated_session} ->
        broadcast(session, updated_session)

        data = {slug, engine, updated_session}
        next_state = state(updated_session)

        actions = [{:reply, from, {:ok, updated_session}}, idle_action()]

        if next_state == state do
          {:keep_state, data, actions}
        else
          {:next_state, next_state, data, actions}
        end

      {:error, reason} ->
        {:keep_state_and_data, [{:reply, from, {:error, reason}}, idle_action()]}
    end
  end

  def handle_event(
        {:call, from},
        {:preview, %Command{} = command},
        _state,
        {_slug, engine, session}
      ) do
    reply = Session.preview(session, engine, command)

    {:keep_state_and_data, [{:reply, from, reply}, idle_action()]}
  end

  def handle_event(:internal, {:dispatch, %Command{} = command}, state, {slug, engine, session}) do
    case Session.dispatch(session, engine, command) do
      {:ok, ^session} ->
        {:keep_state_and_data, [idle_action()]}

      {:ok, %Session{} = updated_session} ->
        broadcast(session, updated_session)

        data = {slug, engine, updated_session}
        next_state = state(updated_session)

        if next_state == state do
          {:keep_state, data, [idle_action()]}
        else
          {:next_state, next_state, data, [idle_action()]}
        end

      {:error, _reason} ->
        {:keep_state_and_data, [idle_action()]}
    end
  end

  def handle_event(:info, {:online, actor_id, attrs}, state, {_slug, engine, _session} = data) do
    update_presence(state, data, fn session ->
      with {:ok, online_session} <- Session.online(session, actor_id, attrs) do
        command = %Command{event: "join", actor_id: actor_id, attrs: attrs}

        case Session.dispatch(online_session, engine, command) do
          {:ok, admitted_session} -> {:ok, admitted_session}
          {:error, _reason} -> {:ok, online_session}
        end
      end
    end)
  end

  def handle_event(:info, {:offline, actor_id}, state, data) do
    update_presence(state, data, &Session.offline(&1, actor_id))
  end

  def handle_event({:timeout, :idle}, :expire, _state, data) do
    {:stop, :normal, data}
  end

  def handle_event(_event_type, _event_content, _state, _data), do: :keep_state_and_data

  @doc false
  @spec broadcast(Session.t(), Session.t()) :: :ok | {:error, term()}
  def broadcast(previous_session, session) do
    with :ok <-
           Phoenix.PubSub.local_broadcast(
             D20.PubSub,
             SessionChannel.topic(session.id),
             {:session, session}
           ) do
      Workspace.publish_session_changes(previous_session, session)
    end
  end

  @doc false
  @spec idle_action() :: :gen_statem.action()
  def idle_action do
    {{:timeout, :idle}, Application.fetch_env!(:d20, :session_idle_timeout), :expire}
  end

  defp state(%Session{game: %{phase: phase}}), do: phase
  defp state(%Session{phase: phase}), do: phase

  defp publish_attachment(change, actor_id) when change in [:attached, :detached] do
    Workspace.publish_sessions_changed(actor_id)
  end

  defp publish_attachment(:unchanged, _actor_id), do: :ok

  defp update_presence(state, {slug, engine, session}, update) do
    case update.(session) do
      {:ok, ^session} ->
        {:keep_state_and_data, [idle_action()]}

      {:ok, %Session{} = updated_session} ->
        broadcast(session, updated_session)

        data = {slug, engine, updated_session}
        next_state = state(updated_session)

        if next_state == state do
          {:keep_state, data, [idle_action()]}
        else
          {:next_state, next_state, data, [idle_action()]}
        end

      {:error, _reason} ->
        {:keep_state_and_data, [idle_action()]}
    end
  end
end
