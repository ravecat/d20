defmodule D20.Game do
  @moduledoc """
  Behaviour for game modules hosted by `D20.Sessions.Session`.

  The session owns table lifecycle. A game module owns setup validation,
  game-specific state, and internal transitions.
  """

  @type engine :: module()
  @type attrs :: map()

  @callback changeset(map()) :: Ecto.Changeset.t()
  @callback init(attrs()) :: {:ok, term()} | {:error, term()}
  @callback dispatch(term(), D20.Command.t()) :: {:ok, term()} | {:error, term()}
  @callback finished?(term()) :: boolean()

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

  @spec ensure_engine(term()) :: {:ok, engine()} | {:error, :invalid_engine}
  def ensure_engine(engine) when is_atom(engine) do
    if Code.ensure_loaded?(engine) and
         Enum.all?(__MODULE__.behaviour_info(:callbacks), fn {name, arity} ->
           function_exported?(engine, name, arity)
         end) do
      {:ok, engine}
    else
      {:error, :invalid_engine}
    end
  end

  def ensure_engine(_engine), do: {:error, :invalid_engine}
end
