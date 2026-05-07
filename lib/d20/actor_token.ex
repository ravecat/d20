defmodule D20.ActorToken do
  def sign(context, actor) when is_map(actor) do
    Phoenix.Token.sign(context, salt(), actor)
  end

  def verify(context, token) when is_binary(token) do
    Phoenix.Token.verify(context, salt(), token, max_age: max_age())
  end

  defp salt do
    config!(:salt)
  end

  defp max_age do
    config!(:max_age)
  end

  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
