defmodule D20.Sessions do
  @moduledoc """
  Runtime boundary for dynamically created game session processes.
  """

  alias D20.Accounts.Scope
  alias D20.Command
  alias D20.Sessions.Session

  @type slug :: String.t()
  @type id :: Session.id()
  @type state :: {Session.t(), slug()}
  @type runtime_state :: {pid(), state()}
  @type reason ::
          :forbidden
          | :session_not_found
          | Session.reason()

  @spec via(id()) :: {:via, Registry, {D20.Registry, {:session, id()}}}
  def via(id) when is_binary(id) do
    {:via, Registry, {D20.Registry, {:session, id}}}
  end

  @spec via(id(), module()) :: {:via, Registry, {D20.Registry, {:session, id()}, module()}}
  def via(id, server) when is_binary(id) and is_atom(server) do
    {:via, Registry, {D20.Registry, {:session, id}, server}}
  end

  @spec create(slug(), D20.Game.engine(), Session.player_id(), map()) ::
          {:ok, Session.t()} | {:error, reason()}
  def create(slug, engine, owner_id, attrs \\ %{})

  def create(slug, engine, owner_id, attrs) when is_binary(slug) do
    with {:ok, session} <- Session.new(engine, owner_id, attrs),
         {:ok, pid} <- start_child(slug, engine, session) do
      send(pid, :presence)
      {:ok, session}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec list(Scope.t()) :: [state()]
  def list(%Scope{} = scope) do
    Enum.map(list_runtime(scope), fn {_pid, state} -> state end)
  end

  @spec list_runtime(Scope.t()) :: [runtime_state()]
  def list_runtime(%Scope{actor: %{id: actor_id}}) when is_binary(actor_id) do
    D20.Registry
    |> Registry.select([{{{:session, :"$1"}, :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.flat_map(fn {id, pid, _server} ->
      case get(id) do
        {:ok, {%Session{} = session, slug}} ->
          if Map.has_key?(session.members, actor_id), do: [{pid, {session, slug}}], else: []

        {:error, _reason} ->
          []
      end
    end)
  end

  def list_runtime(%Scope{}), do: []

  @spec get(id()) :: {:ok, state()} | {:error, reason()}
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

  @spec remove_member(Scope.t()) :: {:ok, Session.t()} | {:error, reason()}
  def remove_member(%Scope{session: %{id: id}, actor: %{id: actor_id}})
      when is_binary(id) and is_binary(actor_id) do
    call(id, {:remove_member, actor_id})
  end

  def remove_member(%Scope{}), do: {:error, :forbidden}

  @spec stop(id(), term(), timeout()) :: :ok
  def stop(id, reason \\ :normal, timeout \\ :infinity)

  def stop(id, reason, timeout) do
    try do
      :gen_statem.stop(via(id), reason, timeout)
    catch
      :exit, :noproc -> :ok
      :exit, {:noproc, _details} -> :ok
    end
  end

  defp call(id, request) do
    :gen_statem.call(via(id), request)
  catch
    :exit, :noproc -> {:error, :session_not_found}
    :exit, {:noproc, _details} -> {:error, :session_not_found}
  end

  defp start_child(slug, engine, session) do
    server = D20.Game.server(engine)
    opts = [slug: slug, engine: engine, session: session]

    DynamicSupervisor.start_child(D20.Sessions.Supervisor, {server, opts})
  end
end
