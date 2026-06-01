defmodule D20.Module.Token do
  @moduledoc """
  Signs short-lived iframe module access claims.
  """

  @type actor :: %{required(:id) => String.t(), required(:type) => D20.Actors.Actor.type()}

  @type claims :: %{
          required(:endpoint) => String.t(),
          required(:slug) => String.t(),
          required(:topic) => String.t(),
          required(:actor) => actor()
        }

  @type context :: Phoenix.Token.context()

  defguardp valid_claims?(claims)
            when is_map(claims) and is_binary(claims.endpoint) and is_binary(claims.slug) and
                   is_binary(claims.topic) and is_binary(claims.actor.id) and
                   claims.actor.type in [:user, :anonymous]

  @spec sign(context(), claims()) :: String.t()
  def sign(context, claims) when is_map(claims) do
    Phoenix.Token.sign(context, salt(), claims)
  end

  @spec verify(context(), String.t()) :: {:ok, claims()} | {:error, term()}
  def verify(context, token) when is_binary(token) do
    case Phoenix.Token.verify(context, salt(), token, max_age: max_age()) do
      {:ok, claims} when valid_claims?(claims) -> {:ok, claims}
      {:ok, _claims} -> {:error, :invalid_claims}
      {:error, reason} -> {:error, reason}
    end
  end

  defp salt, do: config!(:salt)
  defp max_age, do: config!(:max_age)

  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
