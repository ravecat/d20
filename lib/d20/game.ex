defmodule D20.Game do
  @moduledoc """
  Behaviour for game modules hosted by `D20.Sessions.Session`.

  The session owns table lifecycle. A game module owns setup validation,
  game-specific state, and internal transitions.
  """

  @type kind :: String.t()
  @type payload :: map()
  @type engine :: module()

  @callback init() :: {:ok, term()} | {:error, term()}
  @callback dispatch(term(), kind(), payload()) :: {:ok, term()} | {:error, term()}
  @callback finished?(term()) :: boolean()

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
