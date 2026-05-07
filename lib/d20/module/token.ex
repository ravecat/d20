defmodule D20.Module.Token do
  @moduledoc """
  Signs short-lived iframe module access claims.
  """

  @type actor_type :: :user | :anonymous

  @type claims :: %{
          required(:actor_id) => String.t(),
          required(:actor_type) => actor_type(),
          required(:module_id) => String.t(),
          required(:session_id) => String.t()
        }

  @type context :: module() | Phoenix.Socket.t()

  @spec sign(context(), claims()) :: String.t()
  def sign(context, claims) when is_map(claims) do
    Phoenix.Token.sign(context, salt(), claims)
  end

  @spec verify(context(), String.t()) :: {:ok, claims()} | {:error, term()}
  def verify(context, token) when is_binary(token) do
    case Phoenix.Token.verify(context, salt(), token, max_age: max_age()) do
      {:ok,
       %{
         actor_id: actor_id,
         actor_type: actor_type,
         module_id: module_id,
         session_id: session_id
       } = claims}
      when is_binary(actor_id) and actor_type in [:user, :anonymous] and is_binary(module_id) and
             is_binary(session_id) ->
        {:ok, claims}

      {:ok, _claims} ->
        {:error, :invalid_claims}

      {:error, reason} ->
        {:error, reason}
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
