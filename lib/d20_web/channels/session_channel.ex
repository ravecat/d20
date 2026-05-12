defmodule D20Web.SessionChannel do
  use D20Web, :channel

  alias D20.Sessions
  alias D20Web.Presence

  def topic(session_id), do: "session:#{session_id}"

  @impl true
  def join("session:" <> session_id, _payload, socket) do
    with {:ok, session} <- Sessions.get(session_id) do
      send(self(), :after_join)

      {:ok, session, socket}
    else
      {:error, :session_not_found} -> {:error, %{reason: "session_not_found"}}
      {:error, reason} when is_atom(reason) -> {:error, %{reason: Atom.to_string(reason)}}
      {:error, reason} -> {:error, %{reason: inspect(reason)}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.actor.id, %{
        online_at: System.system_time(:second)
      })

    {:noreply, socket}
  end

  def handle_info({:session, session}, socket) do
    push(socket, "projection", session)
    {:noreply, socket}
  end

  @impl true
  def handle_in(event, payload, socket) do
    attrs = put_actor_attrs(socket, event, payload)

    case Sessions.dispatch(session_id(socket), event, attrs) do
      {:ok, _session} ->
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: format_reason(reason)}}, socket}
    end
  end

  defp put_actor_attrs(socket, event, _payload) when event in ["join", "leave", "start"] do
    %{player_id: actor_id(socket)}
  end

  defp put_actor_attrs(socket, _event, attrs) when is_map(attrs) do
    attrs
    |> Map.delete(:player_id)
    |> Map.put("player_id", actor_id(socket))
  end

  defp put_actor_attrs(_socket, _event, attrs), do: attrs

  defp actor_id(%{assigns: %{actor: actor}}), do: actor.id

  defp session_id(socket) do
    "session:" <> session_id = socket.topic
    session_id
  end

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(%Ecto.Changeset{}), do: "invalid_command"
  defp format_reason(reason), do: inspect(reason)
end
