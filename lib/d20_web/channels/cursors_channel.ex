defmodule D20Web.CursorsChannel do
  use D20Web, :channel

  alias D20Web.Presence

  @impl true
  def join("cursors", _payload, socket) do
    :ok = Presence.subscribe(socket.topic)

    send(self(), :after_join)

    {:ok, %{cursors: cursor_projection(socket)}, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, actor_id(socket), %{online_at: System.system_time(:second)})

    {:noreply, socket}
  end

  @impl true
  def handle_info(:projection, socket) do
    push(socket, "projection", %{cursors: cursor_projection(socket)})
    {:noreply, socket}
  end

  def handle_info({:join, _actor_id, _member_attrs}, socket) do
    push(socket, "projection", %{cursors: cursor_projection(socket)})
    {:noreply, socket}
  end

  def handle_info({:left, _actor_id}, socket) do
    push(socket, "projection", %{cursors: cursor_projection(socket)})
    {:noreply, socket}
  end

  @impl true
  def handle_in("move", %{"x" => x, "y" => y}, socket) do
    {:ok, _} =
      Presence.update(socket, actor_id(socket), %{
        online_at: System.system_time(:second),
        x: clamp_world_number(x),
        y: clamp_world_number(y)
      })

    Phoenix.PubSub.local_broadcast(D20.PubSub, socket.topic, :projection)

    {:noreply, socket}
  end

  defp cursor_projection(socket) do
    self_id = actor_id(socket)

    socket
    |> Presence.list()
    |> Enum.flat_map(fn
      {^self_id, _presence} ->
        []

      {actor_id, %{metas: metas}} ->
        Enum.find_value(metas, [], fn
          %{x: x, y: y} when is_integer(x) and is_integer(y) -> [%{id: actor_id, x: x, y: y}]
          _meta -> false
        end)
    end)
  end

  defp clamp_world_number(value) when is_integer(value), do: value
  defp clamp_world_number(value) when is_float(value), do: round(value)

  defp actor_id(%{assigns: %{current_scope: %{actor: actor}}}), do: actor.id
end
