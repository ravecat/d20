defmodule Ecto.Ksuid do
  @moduledoc """
  Ecto type for KSUID string primary keys.

  Values are stored as strings and generated with `Ksuid.generate/0`.
  """

  @behaviour Ecto.Type

  @type t :: String.t()

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(ksuid) when is_binary(ksuid) do
    if valid?(ksuid), do: {:ok, ksuid}, else: :error
  end

  def cast(_value), do: :error

  @impl Ecto.Type
  def load(ksuid) when is_binary(ksuid), do: cast(ksuid)
  def load(_value), do: :error

  @impl Ecto.Type
  def dump(ksuid) when is_binary(ksuid), do: cast(ksuid)
  def dump(_value), do: :error

  @impl Ecto.Type
  def embed_as(_format), do: :self

  @impl Ecto.Type
  def equal?(left, right), do: left == right

  @impl Ecto.Type
  @doc false
  @spec autogenerate() :: t()
  def autogenerate, do: Ksuid.generate()

  defp valid?(ksuid) do
    match?({:ok, _datetime, _payload}, Ksuid.parse(ksuid))
  rescue
    _error -> false
  end
end
