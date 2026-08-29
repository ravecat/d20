defmodule D20.Sessions do
  @moduledoc """
  Runtime boundary for dynamically created game session processes.
  """

  alias D20.Accounts.Scope
  alias D20.Command
  alias D20.Games.Game
  alias D20.Sessions.Session

  @type state :: {pid(), {Session.t(), Game.id()}}
  @type reason ::
          :forbidden
          | :session_not_found
          | Session.reason()

  @spec via(Session.id()) :: {:via, Registry, {D20.Registry, {:session, Session.id()}}}
  def via(id) when is_binary(id) do
    {:via, Registry, {D20.Registry, {:session, id}}}
  end

  @spec via(Session.id(), module()) ::
          {:via, Registry, {D20.Registry, {:session, Session.id()}, module()}}
  def via(id, server) when is_binary(id) and is_atom(server) do
    {:via, Registry, {D20.Registry, {:session, id}, server}}
  end

  @spec create(Game.id(), D20.Game.engine(), Session.player_id(), map()) ::
          {:ok, Session.t()} | {:error, reason()}
  def create(game_id, engine, owner_id, attrs \\ %{})

  def create(game_id, engine, owner_id, attrs) do
    with {:ok, game} <- D20.Games.get(game_id),
         true <- D20.Games.session_launch_available?(game),
         {:ok, session} <- Session.new(engine, owner_id, attrs),
         {:ok, pid} <- start_child(game_id, engine, session) do
      send(pid, :presence)
      {:ok, session}
    else
      false -> {:error, :forbidden}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec list(Scope.t()) :: [state()]
  def list(%Scope{actor: %{id: actor_id}}) do
    actor_id
    |> D20.Sessions.Registry.list()
    |> Enum.flat_map(fn {pid, id} ->
      case state(pid) do
        {:ok, {%Session{id: ^id} = session, game_id}} ->
          if Map.has_key?(session.members, actor_id), do: [{pid, {session, game_id}}], else: []

        {:error, _reason} ->
          []
      end
    end)
  end

  def list(%Scope{}), do: []

  @spec attach(Scope.t()) :: :ok | {:error, reason()}
  def attach(%Scope{session: %{id: id}, actor: %{id: actor_id}})
      when is_binary(id) and is_binary(actor_id) do
    call(id, {:attach, actor_id})
  end

  def attach(%Scope{}), do: {:error, :forbidden}

  @spec detach(Scope.t(), Session.id()) :: :ok | {:error, reason()}
  def detach(%Scope{actor: %{id: actor_id}}, id) when is_binary(actor_id) and is_binary(id) do
    case call(id, {:detach, actor_id}) do
      {:error, :session_not_found} -> :ok
      result -> result
    end
  end

  def detach(%Scope{}, _id), do: {:error, :forbidden}

  @spec get(Session.id()) :: {:ok, {Session.t(), Game.id()}} | {:error, reason()}
  def get(id) when is_binary(id) do
    call(id, :get)
  end

  @spec dispatch(Scope.t(), Session.event(), term()) ::
          {:ok, Session.t()} | {:error, reason()}
  def dispatch(%Scope{session: %{id: id}, actor: %{id: actor_id}}, event, attrs)
      when is_binary(id) and is_binary(actor_id) do
    command = %Command{event: event, actor_id: actor_id, attrs: attrs}

    call(id, {:dispatch, command})
  end

  def dispatch(%Scope{}, _event, _attrs), do: {:error, :forbidden}

  @spec preview(Scope.t(), Session.event(), term()) :: {:ok, map()} | {:error, reason()}
  def preview(%Scope{session: %{id: id}, actor: %{id: actor_id}}, event, attrs)
      when is_binary(id) and is_binary(actor_id) do
    command = %Command{event: event, actor_id: actor_id, attrs: attrs}

    call(id, {:preview, command})
  end

  def preview(%Scope{}, _event, _attrs), do: {:error, :forbidden}

  @spec stop(Session.id(), term(), timeout()) :: :ok
  def stop(id, reason \\ :normal, timeout \\ :infinity)

  def stop(id, reason, timeout) do
    :gen_statem.stop(via(id), reason, timeout)
  catch
    :exit, :noproc -> :ok
    :exit, {:noproc, _details} -> :ok
  end

  defp call(id, request) do
    :gen_statem.call(via(id), request)
  catch
    :exit, :noproc -> {:error, :session_not_found}
    :exit, {:noproc, _details} -> {:error, :session_not_found}
  end

  defp state(pid) do
    :gen_statem.call(pid, :get)
  catch
    :exit, _reason -> {:error, :session_not_found}
  end

  defp start_child(game_id, engine, session) do
    server = D20.Game.server(engine)
    opts = [game_id: game_id, engine: engine, session: session]

    DynamicSupervisor.start_child(D20.Sessions.Supervisor, {server, opts})
  end
end
