defmodule D20.Game do
  @moduledoc """
  Behaviour for game modules hosted by `D20.Sessions.Session`.

  The session owns table lifecycle. A game module owns setup validation,
  game-specific state, and internal transitions.

  Games can choose a process wrapper with:

      use D20.Game, server: D20.KoalaRescueClub.Server

  Without `:server`, sessions use `D20.Sessions.Server`.
  """

  @type engine :: module()
  @type attrs :: map()

  defmacro __using__(opts) do
    server = opts |> Keyword.get(:server, D20.Sessions.Server) |> Macro.expand(__CALLER__)

    unless is_atom(server) do
      raise ArgumentError, "expected :server to be a module, got: #{inspect(server)}"
    end

    quote do
      @behaviour D20.Game

      @impl D20.Game
      def server, do: unquote(server)

      defoverridable server: 0
    end
  end

  @callback changeset(map()) :: Ecto.Changeset.t()
  @callback init(attrs()) :: {:ok, term()} | {:error, term()}
  @callback dispatch(term(), D20.Command.t()) :: {:ok, term()} | {:error, term()}
  @callback finished?(term()) :: boolean()
  @callback server() :: module()

  @optional_callbacks server: 0

  @spec changeset(engine(), map()) :: Ecto.Changeset.t()
  def changeset(engine, params \\ %{}) do
    engine.changeset(params)
  end

  @spec init(term(), map()) ::
          {:ok, term()}
          | {:error, :invalid_engine | Ecto.Changeset.t() | term()}
  def init(engine, params \\ %{}) do
    with {:ok, engine} <- ensure_engine(engine),
         {:ok, attrs} <-
           engine |> changeset(params) |> Ecto.Changeset.apply_action(:create_session) do
      engine.init(attrs)
    end
  end

  @spec server(engine()) :: module()
  def server(engine) do
    if function_exported?(engine, :server, 0) do
      engine.server()
    else
      D20.Sessions.Server
    end
  end

  @spec ensure_engine(term()) :: {:ok, engine()} | {:error, :invalid_engine}
  def ensure_engine(engine) when is_atom(engine) do
    optional_callbacks = __MODULE__.behaviour_info(:optional_callbacks)
    required_callbacks = __MODULE__.behaviour_info(:callbacks) -- optional_callbacks

    if Code.ensure_loaded?(engine) and
         Enum.all?(required_callbacks, fn {name, arity} ->
           function_exported?(engine, name, arity)
         end) do
      {:ok, engine}
    else
      {:error, :invalid_engine}
    end
  end

  def ensure_engine(_engine), do: {:error, :invalid_engine}
end
