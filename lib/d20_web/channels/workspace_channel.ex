defmodule D20Web.WorkspaceChannel do
  use D20Web, :channel

  alias D20.Accounts.Scope
  alias D20Web.Workspace

  @impl true
  def join(
        "workspace",
        _payload,
        %{assigns: %{scope: %Scope{actor: %{id: actor_id}} = scope, request_uri: %URI{}}} = socket
      )
      when is_binary(actor_id) do
    :ok = Workspace.subscribe(scope)

    {sessions, runtime_pids} = Workspace.sessions(socket)
    socket = sync_monitors(socket, runtime_pids)

    {:ok, %{sessions: sessions}, socket}
  end

  def join("workspace", _payload, _socket), do: {:error, %{reason: "forbidden"}}

  @impl true
  def handle_in(
        "close_session",
        %{"id" => session_id},
        %{assigns: %{scope: %Scope{actor: %{id: _actor_id}} = scope}} = socket
      )
      when is_binary(session_id) do
    case Workspace.close_session_for_actor(scope, session_id) do
      :ok -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: format_reason(reason)}}, socket}
    end
  end

  def handle_in(_event, _payload, socket) do
    {:reply, {:error, %{reason: "unsupported_event"}}, socket}
  end

  @impl true
  def handle_info({:sessions_changed, actor_id}, %{assigns: %{scope: scope}} = socket)
      when actor_id == scope.actor.id do
    {:noreply, refresh(socket)}
  end

  def handle_info({:close_session, actor_id, _session_id}, %{assigns: %{scope: scope}} = socket)
      when actor_id == scope.actor.id do
    {:noreply, refresh(socket)}
  end

  def handle_info({:DOWN, reference, :process, pid, _reason}, socket) do
    case socket.assigns.monitors do
      %{^pid => ^reference} ->
        socket = assign(socket, :monitors, Map.delete(socket.assigns.monitors, pid))
        {:noreply, refresh(socket)}

      _monitors ->
        {:noreply, socket}
    end
  end

  defp refresh(socket) do
    {sessions, runtime_pids} = Workspace.sessions(socket)
    socket = sync_monitors(socket, runtime_pids)
    push(socket, "snapshot", %{sessions: sessions})
    socket
  end

  defp sync_monitors(socket, runtime_pids) do
    current = Map.get(socket.assigns, :monitors, %{})
    current_pids = Map.keys(current) |> MapSet.new()

    current
    |> Map.take(MapSet.to_list(MapSet.difference(current_pids, runtime_pids)))
    |> Enum.each(fn {_pid, reference} -> Process.demonitor(reference, [:flush]) end)

    monitors =
      current
      |> Map.take(MapSet.to_list(runtime_pids))
      |> Map.merge(
        runtime_pids
        |> MapSet.difference(current_pids)
        |> Map.new(fn pid -> {pid, Process.monitor(pid)} end)
      )

    assign(socket, :monitors, monitors)
  end

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(reason), do: inspect(reason)
end
