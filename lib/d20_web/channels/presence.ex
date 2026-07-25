defmodule D20Web.Presence do
  @moduledoc """
  Tracks actors connected to Phoenix channel topics.
  """

  use Phoenix.Presence,
    otp_app: :d20,
    pubsub_server: D20.PubSub

  alias D20Web.SessionChannel

  @spec subscribe(D20.Sessions.id()) :: :ok | {:error, term()}
  def subscribe(session_id) when is_binary(session_id) do
    Phoenix.PubSub.subscribe(D20.PubSub, topic(SessionChannel.topic(session_id)))
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {actor_id, presence} <- joins do
      %{metas: [attrs | _]} = presence

      Phoenix.PubSub.local_broadcast(D20.PubSub, topic(topic), {:online, actor_id, attrs})
    end

    for {actor_id, _presence} <- leaves, not actor_present?(presences, actor_id) do
      Phoenix.PubSub.local_broadcast(D20.PubSub, topic(topic), {:offline, actor_id})
    end

    {:ok, state}
  end

  defp actor_present?(presences, actor_id) do
    case Map.get(presences, actor_id) do
      %{metas: [_ | _]} -> true
      _ -> false
    end
  end

  defp topic(topic), do: "presence:#{topic}"
end
