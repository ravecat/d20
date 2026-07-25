defmodule D20Web.WorkspaceChannel do
  use D20Web, :channel

  alias D20.Accounts.Scope
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.Workspace

  @channel_topic "workspace"

  @impl true
  def join(
        @channel_topic,
        _payload,
        %{assigns: %{scope: %Scope{actor: %{id: actor_id}}, request_uri: %URI{}}} = socket
      )
      when is_binary(actor_id) do
    :ok = Workspace.subscribe(actor_id)

    {snapshot, runtimes} = Workspace.snapshot(socket)
    socket = sync_monitors(socket, runtimes)

    {:ok, snapshot, socket}
  end

  def join(@channel_topic, _payload, _socket), do: {:error, %{reason: "forbidden"}}

  @impl true
  def handle_in(
        "close",
        %{"id" => session_id},
        %{assigns: %{scope: %Scope{actor: %{id: actor_id}} = scope}} = socket
      ) do
    with {:ok, {%Session{members: members}, slug}} <- Sessions.get(session_id),
         true <- Map.has_key?(members, actor_id),
         scope = scope |> Scope.put_session(session_id) |> Scope.put_game(slug),
         {:ok, _session} <- Sessions.remove_member(scope) do
      {:reply, :ok, socket}
    else
      false -> {:reply, {:error, %{reason: "forbidden"}}, socket}
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
    {snapshot, runtimes} = Workspace.snapshot(socket)
    socket = sync_monitors(socket, runtimes)
    push(socket, "snapshot", snapshot)
    socket
  end

  defp sync_monitors(socket, runtimes) do
    current = Map.get(socket.assigns, :monitors, %{})
    current_pids = Map.keys(current) |> MapSet.new()
    runtime_pids = Map.keys(runtimes) |> MapSet.new()

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
