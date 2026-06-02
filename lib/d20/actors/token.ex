defmodule D20.Actors.Token do
  @moduledoc """
  Signs actor identity claims for browser socket authentication.
  """

  alias D20.Actors.Actor

  @type context :: Phoenix.Token.context()

  @spec sign(context(), Actor.t()) :: String.t()
  def sign(context, %Actor{id: id, type: type}) do
    Phoenix.Token.sign(context, salt(), %{id: id, type: type})
  end

  @spec verify(context(), String.t()) :: {:ok, Actor.t()} | {:error, term()}
  def verify(context, token) when is_binary(token) do
    case Phoenix.Token.verify(context, salt(), token, max_age: max_age()) do
      {:ok, claims} -> verify_claims(claims)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec salt() :: String.t()
  defp salt do
    config!(:salt)
  end

  @spec max_age() :: pos_integer()
  defp max_age do
    config!(:max_age)
  end

  @spec config!(:salt) :: String.t()
  @spec config!(:max_age) :: pos_integer()
  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end

  defp verify_claims(%{id: id, type: type})
       when is_binary(id) and type in [:user, :anonymous],
       do: {:ok, %Actor{id: id, type: type}}

  defp verify_claims(_claims), do: {:error, :invalid_token}
end
