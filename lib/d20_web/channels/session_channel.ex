defmodule D20Web.SessionChannel do
  use D20Web, :channel

  alias D20.Accounts.Scope
  alias D20.Sessions
  alias D20Web.Presence

  def topic(session_id), do: "session:#{session_id}"
  def session_id("session:" <> id) when id != "", do: {:ok, id}
  def session_id(_topic), do: {:error, :invalid_topic}

  @impl true
  def join(
        "session:" <> session_id,
        _payload,
        %{
          handler: D20Web.ModuleSocket,
          assigns: %{current_scope: %{session: %{id: session_id}, game: %{slug: slug}}}
        } = socket
      ) do
    with {:ok, {session, ^slug}} <- Sessions.get(session_id) do
      join_session(socket, session)
    else
      {:ok, {_session, _session_slug}} -> join_error({:error, :forbidden})
      {:error, reason} -> join_error({:error, reason})
    end
  end

  def join("session:" <> _session_id, _payload, %{handler: D20Web.ModuleSocket}) do
    join_error({:error, :forbidden})
  end

  def join(
        "session:" <> session_id,
        _payload,
        %{assigns: %{current_scope: %{actor: %{id: actor_id}}}} = socket
      )
      when is_binary(actor_id) do
    with {:ok, {session, slug}} <- Sessions.get(session_id) do
      scope =
        socket.assigns.current_scope |> Scope.put_session(session.id) |> Scope.put_game(slug)

      socket = assign(socket, :current_scope, scope)

      join_session(socket, session)
    else
      {:error, reason} -> join_error({:error, reason})
    end
  end

  def join("session:" <> _session_id, _payload, _socket) do
    join_error({:error, :forbidden})
  end

  @impl true
  def handle_info(:after_join, %{handler: D20Web.ModuleSocket} = socket) do
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, actor_id(socket), %{online_at: System.system_time(:second)})

    {:noreply, socket}
  end

  def handle_info({:session, session}, socket) do
    push(socket, "projection", session)
    {:noreply, socket}
  end

  @impl true
  def handle_in(event, payload, socket) do
    attrs = put_actor(socket, event, payload)

    case Sessions.dispatch(scope_session_id(socket), event, attrs) do
      {:ok, _session} -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: format_reason(reason)}}, socket}
    end
  end

  defp put_actor(socket, event, _payload) when event in ["join", "leave", "start"] do
    %{player_id: actor_id(socket)}
  end

  defp put_actor(socket, _event, attrs) when is_map(attrs) do
    attrs
    |> Map.delete(:player_id)
    |> Map.put("player_id", actor_id(socket))
  end

  defp put_actor(_socket, _event, attrs), do: attrs

  defp actor_id(%{assigns: %{current_scope: %{actor: actor}}}), do: actor.id

  defp scope_session_id(%{assigns: %{current_scope: %{session: %{id: session_id}}}}),
    do: session_id

  defp join_session(socket, session) do
    send(self(), :after_join)

    {:ok, session, socket}
  end

  defp join_error({:error, :forbidden}), do: {:error, %{reason: "forbidden"}}
  defp join_error({:error, :session_not_found}), do: {:error, %{reason: "session_not_found"}}

  defp join_error({:error, reason}) when is_atom(reason),
    do: {:error, %{reason: Atom.to_string(reason)}}

  defp join_error({:error, reason}), do: {:error, %{reason: inspect(reason)}}

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(%Ecto.Changeset{}), do: "invalid_command"
  defp format_reason(reason), do: inspect(reason)
end
