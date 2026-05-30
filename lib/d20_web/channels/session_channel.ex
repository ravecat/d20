defmodule D20Web.SessionChannel do
  use D20Web, :channel

  alias D20.Sessions
  alias D20Web.Presence

  def topic(session_id), do: "session:#{session_id}"

  @impl true
  def join("session:" <> session_id, _payload, socket) do
    with :ok <- authorize_topic(socket, session_id),
         {:ok, ref, session} <- session_context(socket, session_id) do
      send(self(), :after_join)

      socket = assign(socket, :session_ref, ref)

      {:ok, session, socket}
    else
      {:error, :forbidden} -> {:error, %{reason: "forbidden"}}
      {:error, :session_not_found} -> {:error, %{reason: "session_not_found"}}
      {:error, reason} when is_atom(reason) -> {:error, %{reason: Atom.to_string(reason)}}
      {:error, reason} -> {:error, %{reason: inspect(reason)}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.actor.id, %{online_at: System.system_time(:second)})

    {:noreply, socket}
  end

  def handle_info({:session, session}, socket) do
    push(socket, "projection", session)
    {:noreply, socket}
  end

  @impl true
  def handle_in(event, payload, socket) do
    attrs = put_actor_attrs(socket, event, payload)

    case Sessions.dispatch(socket.assigns.session_ref, event, attrs) do
      {:ok, _session} -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: format_reason(reason)}}, socket}
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

  defp authorize_topic(%{assigns: %{module: %{session_id: session_id}}}, session_id) do
    :ok
  end

  defp authorize_topic(%{assigns: %{module: _module}}, _session_id) do
    {:error, :forbidden}
  end

  defp authorize_topic(_socket, _session_id), do: {:error, :forbidden}

  defp session_context(%{assigns: %{module: %{module_id: slug}}}, session_id) do
    ref = {slug, session_id}

    with {:ok, session} <- Sessions.get(ref) do
      {:ok, ref, session}
    end
  end

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(%Ecto.Changeset{}), do: "invalid_command"
  defp format_reason(reason), do: inspect(reason)
end
