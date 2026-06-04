defmodule D20.Command do
  @moduledoc """
  Trusted runtime command envelope for session and game-engine dispatch.
  """

  @type event :: String.t()
  @type actor_id :: String.t()
  @type attrs :: map()
  @type t :: %__MODULE__{event: event(), actor_id: actor_id(), attrs: attrs()}

  @enforce_keys [:event, :actor_id]
  defstruct [:event, :actor_id, attrs: %{}]
end
