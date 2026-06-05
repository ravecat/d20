defmodule D20.Actors.Actor do
  @moduledoc """
  Caller identity used by runtime sessions, channels, presence, and module tokens.
  """

  alias D20.Accounts.Anonymous
  alias D20.Accounts.User

  @enforce_keys [:id, :type]
  defstruct [:id, :type]

  @typedoc """
  Runtime actor id string derived from either a user id or an anonymous id.
  """
  @type id :: String.t()
  @type type :: :user | :anonymous
  @type t :: %__MODULE__{id: id(), type: type()}

  @spec new(Anonymous.t() | %User{}) :: t()
  def new(%Anonymous{id: id}) do
    %__MODULE__{id: id, type: :anonymous}
  end

  def new(%User{id: id}) do
    %__MODULE__{id: to_string(id), type: :user}
  end
end
