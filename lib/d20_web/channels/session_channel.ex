defmodule D20Web.SessionChannel do
  use D20Web, :channel

  alias D20.Sessions

  def topic(session_id), do: "session:#{session_id}"

  @impl true
  def join("session:" <> session_id, _payload, socket) do
    with :ok <- require_claim(socket, :session_id, session_id),
         {:ok, session} <- Sessions.get(session_id),
         :ok <- require_module(socket, session),
         :ok <- Phoenix.PubSub.subscribe(D20.PubSub, socket.topic) do
      {:ok, socket}
    else
      {:error, :session_not_found} -> {:error, %{reason: "session_not_found"}}
      {:error, reason, _context} -> {:error, %{reason: format_reason(reason)}}
      {:error, reason} -> {:error, %{reason: format_reason(reason)}}
    end
  end

  @impl true
  def handle_in("command", %{"kind" => kind, "attrs" => attrs}, socket)
      when is_binary(kind) and is_map(attrs) do
    "session:" <> session_id = socket.topic
    attrs = put_actor_attrs(socket, attrs)

    case Sessions.dispatch(session_id, String.to_existing_atom(kind), attrs) do
      {:ok, _session} ->
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: format_reason(reason)}}, socket}
    end
  rescue
    ArgumentError ->
      {:reply, {:error, %{reason: "unknown_command"}}, socket}
  end

  def handle_in("command", _payload, socket) do
    {:reply, {:error, %{reason: "invalid_command"}}, socket}
  end

  def handle_in(event, _payload, socket) do
    {:reply, {:error, %{reason: "unknown_event", event: event}}, socket}
  end

  defp require_claim(socket, key, expected) do
    case Map.fetch(socket.assigns.module_claims, key) do
      {:ok, ^expected} -> :ok
      _ -> {:error, :invalid_claim, key}
    end
  end

  defp require_module(socket, session) do
    case D20.Module.Manifest.module_id_for_engine(session.engine) do
      nil -> {:error, :invalid_module}
      module_id -> require_claim(socket, :module_id, module_id)
    end
  end

  defp put_actor_attrs(socket, attrs) do
    actor_id = socket.assigns.module_claims.actor_id

    attrs
    |> Map.put("player_id", actor_id)
    |> Map.put(:player_id, actor_id)
  end

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(%Ecto.Changeset{}), do: "invalid_command"
  defp format_reason(reason), do: inspect(reason)
end
