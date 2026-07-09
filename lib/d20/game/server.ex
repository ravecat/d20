defmodule D20.Game.Server do
  @moduledoc """
  Behaviour for processes that own a live `D20.Sessions.Session`.

  Implementations keep the existing `%D20.Sessions.Session{}` as the source of
  truth and decide how incoming commands are routed to `D20.Sessions.Session`.

  Use this module to get the stable server API while choosing the OTP primitive
  that fits the game:

      use D20.Game.Server, otp: :gen_server
      use D20.Game.Server, otp: :gen_statem
  """

  alias D20.Command
  alias D20.Sessions
  alias D20.Sessions.Session

  @type start_opts :: [slug: Sessions.slug(), engine: D20.Game.engine(), session: Session.t()]
  @type state :: {Sessions.slug(), D20.Game.engine(), Session.t()}

  @callback start_link(start_opts()) :: GenServer.on_start()
  @callback get(GenServer.server()) :: {:ok, {Session.t(), Sessions.slug()}}
  @callback dispatch(GenServer.server(), Command.t()) ::
              {:ok, Session.t()} | {:error, Session.reason()}

  defmacro __using__(opts) do
    otp = Keyword.get(opts, :otp, :gen_server)

    quote do
      @behaviour D20.Game.Server

      @type start_opts :: D20.Game.Server.start_opts()
      @type state :: D20.Game.Server.state()

      @spec init_arg(start_opts()) :: state()
      def init_arg(opts) do
        slug = Keyword.fetch!(opts, :slug)
        engine = Keyword.fetch!(opts, :engine)
        session = Keyword.fetch!(opts, :session)

        {slug, engine, session}
      end

      defoverridable init_arg: 1

      unquote(callbacks(otp))
    end
  end

  @spec via(Session.id(), module()) ::
          {:via, Registry, {D20.Registry, {:session, Session.id()}, module()}}
  def via(id, server) when is_binary(id) and is_atom(server) do
    {:via, Registry, {D20.Registry, Sessions.registry_key(id), server}}
  end

  defp callbacks(:gen_server) do
    quote do
      use GenServer, restart: :temporary

      @impl D20.Game.Server
      @spec start_link(start_opts()) :: GenServer.on_start()
      def start_link(opts) do
        session = Keyword.fetch!(opts, :session)

        GenServer.start_link(__MODULE__, init_arg(opts),
          name: D20.Game.Server.via(session.id, __MODULE__)
        )
      end

      @impl D20.Game.Server
      @spec get(GenServer.server()) :: {:ok, {D20.Sessions.Session.t(), D20.Sessions.slug()}}
      def get(server) do
        GenServer.call(server, :get)
      end

      @impl D20.Game.Server
      @spec dispatch(GenServer.server(), D20.Command.t()) ::
              {:ok, D20.Sessions.Session.t()} | {:error, D20.Sessions.Session.reason()}
      def dispatch(server, %D20.Command{} = command) do
        GenServer.call(server, {:dispatch, command})
      end

      defoverridable start_link: 1, get: 1, dispatch: 2
    end
  end

  defp callbacks(:gen_statem) do
    quote do
      @behaviour :gen_statem

      @spec child_spec(start_opts()) :: Supervisor.child_spec()
      def child_spec(opts) do
        session = Keyword.fetch!(opts, :session)

        %{
          id: {__MODULE__, session.id},
          start: {__MODULE__, :start_link, [opts]},
          restart: :temporary
        }
      end

      @impl D20.Game.Server
      @spec start_link(start_opts()) :: GenServer.on_start()
      def start_link(opts) do
        session = Keyword.fetch!(opts, :session)

        :gen_statem.start_link(
          D20.Game.Server.via(session.id, __MODULE__),
          __MODULE__,
          init_arg(opts),
          []
        )
      end

      @impl D20.Game.Server
      @spec get(GenServer.server()) :: {:ok, {D20.Sessions.Session.t(), D20.Sessions.slug()}}
      def get(server) do
        :gen_statem.call(server, :get)
      end

      @impl D20.Game.Server
      @spec dispatch(GenServer.server(), D20.Command.t()) ::
              {:ok, D20.Sessions.Session.t()} | {:error, D20.Sessions.Session.reason()}
      def dispatch(server, %D20.Command{} = command) do
        :gen_statem.call(server, {:dispatch, command})
      end

      @impl :gen_statem
      def callback_mode, do: [:handle_event_function, :state_enter]

      defoverridable child_spec: 1,
                     start_link: 1,
                     get: 1,
                     dispatch: 2,
                     callback_mode: 0
    end
  end

  defp callbacks(other) do
    raise ArgumentError, "expected :gen_server or :gen_statem, got: #{inspect(other)}"
  end
end
