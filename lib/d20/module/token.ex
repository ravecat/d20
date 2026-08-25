defmodule D20.Module.Token do
  @moduledoc """
  Signs short-lived iframe module access claims.
  """

  alias D20.Actors.Actor
  alias D20.Games.Game

  @type claims :: %{
          required(:endpoint) => String.t(),
          required(:game_id) => Game.id(),
          required(:topic) => String.t(),
          required(:actor) => Actor.t()
        }

  @type context :: Phoenix.Token.context()

  @spec sign(context(), claims()) :: String.t()
  def sign(context, %{game_id: %TypeID{} = game_id} = claims) do
    claims = Map.put(claims, :game_id, TypeID.to_string(game_id))
    Phoenix.Token.sign(context, salt(), claims)
  end

  @spec verify(context(), String.t()) :: {:ok, claims()} | {:error, term()}
  def verify(context, token) when is_binary(token) do
    with {:ok, claims} <- Phoenix.Token.verify(context, salt(), token, max_age: max_age()),
         {:ok, claims} <- validate_claims(claims) do
      {:ok, claims}
    end
  end

  defp validate_claims(%{
         endpoint: endpoint,
         game_id: game_id,
         topic: topic,
         actor: %Actor{} = actor
       })
       when is_binary(endpoint) and is_binary(game_id) and is_binary(topic) do
    with {:ok, %TypeID{} = game_id} <- TypeID.from_string(game_id),
         "game" <- TypeID.prefix(game_id) do
      {:ok, %{endpoint: endpoint, game_id: game_id, topic: topic, actor: actor}}
    else
      _invalid -> {:error, :invalid_claims}
    end
  end

  defp validate_claims(_claims), do: {:error, :invalid_claims}

  defp salt, do: config!(:salt)
  defp max_age, do: config!(:max_age)

  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
