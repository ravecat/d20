defmodule D20.Module.Token do
  @moduledoc """
  Signs short-lived iframe module access claims.
  """

  @type claims :: %{
          required(:actor_id) => String.t(),
          required(:actor_type) => D20.Actors.Actor.type(),
          required(:module_id) => String.t(),
          required(:session_id) => String.t()
        }

  @type context :: Phoenix.Token.context()

  defguardp valid_claims?(claims)
            when is_map(claims) and is_binary(claims.actor_id) and
                   claims.actor_type in [:user, :anonymous] and is_binary(claims.module_id) and
                   is_binary(claims.session_id)

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
