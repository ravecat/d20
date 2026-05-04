defmodule D20.Game do
  @moduledoc """
  Behaviour for game modules hosted by `D20.Session`.

  The session owns table lifecycle. A game module owns setup validation,
  game-specific state, and internal transitions.
  """

  @type command_kind :: atom()
  @type command_attrs :: map()

  @callback init() :: {:ok, term()} | {:error, term()}
  @callback dispatch(term(), command_kind(), command_attrs()) :: {:ok, term()} | {:error, term()}
  @callback finished?(term()) :: boolean()
end
