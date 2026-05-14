defmodule D20Web.Presence do
  @moduledoc """
  Tracks actors connected to Phoenix channel topics.
  """

  use Phoenix.Presence,
    otp_app: :d20,
    pubsub_server: D20.PubSub

  @presence_prefix "presence:"

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {actor_id, presence} <- joins do
      %{metas: [member_attrs | _]} = presence

      Phoenix.PubSub.local_broadcast(
        D20.PubSub,
        presence_topic(topic),
        {:join, actor_id, member_attrs}
      )
    end

    for {actor_id, _} <- leaves, not present?(presences, actor_id) do
      Phoenix.PubSub.local_broadcast(
        D20.PubSub,
        presence_topic(topic),
        {:left, actor_id}
      )
    end

    {:ok, state}
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(D20.PubSub, presence_topic(topic))
  end

  defp present?(presences, actor_id) do
    case Map.get(presences, actor_id) do
      %{metas: [_ | _]} -> true
      _ -> false
    end
  end

  defp presence_topic(topic), do: @presence_prefix <> topic
end
