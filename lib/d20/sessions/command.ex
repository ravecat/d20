defmodule D20.Sessions.Command do
  @moduledoc """
  Trusted command envelope for runtime session dispatch.
  """

  @type event :: String.t()
  @type actor_id :: String.t()
  @type t :: %__MODULE__{event: event(), actor_id: actor_id(), attrs: term()}

  @enforce_keys [:event, :actor_id]
  defstruct [:event, :actor_id, attrs: %{}]
end
