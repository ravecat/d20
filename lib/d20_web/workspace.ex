defmodule D20Web.Workspace do
  @moduledoc """
  Discovers and invalidates actor-specific workspace sessions.
  """

  alias D20.Accounts.Scope
  alias D20.Games.Registry
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.Module

  @type descriptor :: %{
          required(:id) => Sessions.id(),
          required(:slug) => Sessions.slug(),
          required(:phase) => Session.phase(),
          required(:module) => Module.entry(),
          required(:connection) => Module.connection()
        }

  @spec subscribe(Scope.t()) :: :ok | {:error, term()}
  def subscribe(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(D20.PubSub, topic(Scope.actor_id(scope)))
  end

  @spec close_session_for_actor(Scope.t(), Sessions.id()) :: :ok | {:error, term()}
  def close_session_for_actor(%Scope{actor: %{id: actor_id}} = scope, session_id)
      when is_binary(actor_id) and is_binary(session_id) do
    with :ok <- Sessions.detach(scope, session_id) do
      Phoenix.PubSub.broadcast(
        D20.PubSub,
        topic(actor_id),
        {:close_session, actor_id, session_id}
      )
    end
  end

  @spec publish_sessions_changed(Session.player_id()) :: :ok | {:error, term()}
  def publish_sessions_changed(actor_id) when is_binary(actor_id) do
    Phoenix.PubSub.local_broadcast(D20.PubSub, topic(actor_id), {:sessions_changed, actor_id})
  end

  @spec publish_session_changes(Session.t(), Session.t()) :: :ok
  def publish_session_changes(%Session{} = previous, %Session{} = current) do
    if changed?(previous, current) do
      previous.members
      |> Map.keys()
      |> Kernel.++(Map.keys(current.members))
      |> Enum.uniq()
      |> Enum.each(&publish_sessions_changed/1)
    end

    :ok
  end

  @spec sessions(Phoenix.Socket.t()) :: {[descriptor()], MapSet.t(pid())}
  def sessions(socket) do
    entries =
      socket.assigns.scope
      |> Sessions.list()
      |> Enum.flat_map(fn
        {pid, {%Session{id: id, phase: phase}, slug}} when phase in [:in_progress, :finished] ->
          case Registry.fetch(slug) do
            {:ok, %Registry.Entry{} = entry} -> [{descriptor(socket, entry, id, phase), pid}]
            {:error, :game_not_found} -> []
          end

        {_pid, {%Session{}, _slug}} ->
          []
      end)
      |> Enum.sort_by(fn {%{id: id}, _pid} -> id end)

    descriptors = Enum.map(entries, fn {descriptor, _pid} -> descriptor end)
    runtime_pids = MapSet.new(entries, fn {_descriptor, pid} -> pid end)

    {descriptors, runtime_pids}
  end

  @spec descriptor(Phoenix.Socket.t(), Registry.Entry.t(), Sessions.id(), Session.phase()) ::
          descriptor()
  defp descriptor(socket, %Registry.Entry{slug: slug} = entry, id, phase) do
    %{
      id: id,
      slug: slug,
      phase: phase,
      module: Module.entry(socket, entry),
      connection: Module.connection(socket, slug, id)
    }
  end

  defp changed?(previous, session) do
    previous.phase != session.phase or
      MapSet.new(Map.keys(previous.members)) != MapSet.new(Map.keys(session.members))
  end

  defp topic(actor_id), do: "workspace:actor:" <> actor_id
end
