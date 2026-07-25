defmodule D20Web.Workspace do
  @moduledoc """
  Builds and invalidates actor-specific workspace snapshots.
  """

  alias D20.Games.Registry
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.Module

  @spec subscribe(Session.player_id()) :: :ok | {:error, term()}
  def subscribe(actor_id) when is_binary(actor_id) do
    Phoenix.PubSub.subscribe(D20.PubSub, topic(actor_id))
  end

  @spec publish_session_changes(Session.t(), Session.t()) :: :ok
  def publish_session_changes(%Session{} = previous, %Session{} = current) do
    if discovery_changed?(previous, current) do
      previous.members
      |> Map.keys()
      |> Kernel.++(Map.keys(current.members))
      |> Enum.uniq()
      |> Enum.each(fn actor_id ->
        Phoenix.PubSub.local_broadcast(D20.PubSub, topic(actor_id), {:sessions_changed, actor_id})
      end)
    end

    :ok
  end

  @spec snapshot(Phoenix.Socket.t()) :: {%{sessions: [map()]}, %{pid() => Sessions.id()}}
  def snapshot(socket) do
    sessions =
      socket.assigns.current_scope
      |> Sessions.list_runtime()
      |> Enum.flat_map(fn
        {pid, {%Session{id: id, phase: :in_progress}, slug}} ->
          case Registry.fetch(slug) do
            {:ok, %Registry.Entry{} = entry} ->
              descriptor = %{
                id: id,
                slug: slug,
                module: Module.entry(socket, entry),
                connection: Module.connection(socket, slug, id)
              }

              [{descriptor, pid}]

            {:error, :game_not_found} ->
              []
          end

        {_pid, {%Session{}, _slug}} ->
          []
      end)
      |> Enum.sort_by(fn {%{id: id}, _pid} -> id end)

    descriptors = Enum.map(sessions, fn {descriptor, _pid} -> descriptor end)
    runtimes = Map.new(sessions, fn {%{id: id}, pid} -> {pid, id} end)

    {%{sessions: descriptors}, runtimes}
  end

  defp discovery_changed?(previous, session) do
    previous.phase != session.phase or
      MapSet.new(Map.keys(previous.members)) != MapSet.new(Map.keys(session.members))
  end

  defp topic(actor_id), do: "workspace:actor:" <> actor_id
end
