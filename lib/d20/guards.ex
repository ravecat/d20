defmodule D20.Guards do
  @moduledoc """
  Shared guard macros for public reducers and state machines.
  """

  defguard is_player_id(value) when is_binary(value) and value != ""
end
