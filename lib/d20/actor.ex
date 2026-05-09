defmodule D20.Actor do
  @moduledoc """
  Caller identity used by runtime sessions, channels, presence, and module tokens.
  """

  alias D20.Accounts.User

  @enforce_keys [:id, :type]
  defstruct [:id, :type]

  @type type :: :user | :anonymous
  @type t :: %__MODULE__{id: String.t(), type: type()}

  @spec new() :: t()
  def new, do: new(generate_id())

  @spec new(String.t() | %User{}) :: t()
  def new(id) when is_binary(id) do
    %__MODULE__{id: id, type: :anonymous}
  end

  def new(%User{id: id}) do
    %__MODULE__{id: to_string(id), type: :user}
  end

  defp generate_id, do: Ecto.UUID.generate()
end
