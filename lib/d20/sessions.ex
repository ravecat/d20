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
  @type reason ::
          :forbidden
          | :session_not_found
          | Session.reason()

  @spec via(id(), module()) :: {:via, Registry, {D20.Registry, {:session, id()}, module()}}
  def via(id, server) when is_binary(id) and is_atom(server) do
    {:via, Registry, {D20.Registry, key(id), server}}
  end

  @spec create(slug(), D20.Game.engine(), Session.player_id(), map()) ::
          {:ok, Session.t()} | {:error, reason()}
  def create(slug, engine, owner_id, attrs \\ %{})

  def create(slug, engine, owner_id, attrs) when is_binary(slug) do
    with {:ok, session} <- Session.new(engine, owner_id, attrs),
         {:ok, _pid} <- start_child(slug, engine, session) do
      {:ok, session}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get(id()) :: {:ok, state()} | {:error, reason()}
  def get(id) when is_binary(id) do
    call_if_exists(id, fn server, pid -> server.get(pid) end)
  end

  @spec dispatch(Scope.t(), Session.event(), term()) ::
          {:ok, Session.t()} | {:error, reason()}
  def dispatch(%Scope{session: %{id: id}, actor: %{id: actor_id}}, event, attrs)
      when is_binary(id) and is_binary(actor_id) do
    command = %Command{event: event, actor_id: actor_id, attrs: attrs}

    call_if_exists(id, fn server, pid -> server.dispatch(pid, command) end)
  end

  def dispatch(%Scope{}, _event, _attrs), do: {:error, :forbidden}

  @spec lookup(id()) :: {:ok, pid()} | {:error, :session_not_found}
  def lookup(id) when is_binary(id) do
    case lookup_server(id) do
      {:ok, {pid, _server}} -> {:ok, pid}
      {:error, :session_not_found} -> {:error, :session_not_found}
    end
  end

  @spec stop(id(), term(), timeout()) :: :ok
  def stop(id, reason \\ :normal, timeout \\ :infinity)

  def stop(id, reason, timeout) do
    case lookup(id) do
      {:ok, pid} ->
        try do
          :gen_statem.stop(pid, reason, timeout)
        catch
          :exit, :noproc -> :ok
          :exit, {:noproc, _details} -> :ok
        end

      {:error, :session_not_found} ->
        :ok
    end
  end

  defp call_if_exists(id, fun) do
    with {:ok, {pid, server}} <- lookup_server(id) do
      fun.(server, pid)
    end
  end

  defp lookup_server(id) do
    case Registry.lookup(D20.Registry, key(id)) do
      [{pid, server}] when is_atom(server) -> {:ok, {pid, server}}
      [] -> {:error, :session_not_found}
    end
  end

  defp start_child(slug, engine, session) do
    server = D20.Game.server(engine)
    opts = [slug: slug, engine: engine, session: session]

    DynamicSupervisor.start_child(D20.Sessions.Supervisor, {server, opts})
  end

  @spec key(id()) :: {:session, id()}
  defp key(id) when is_binary(id), do: {:session, id}
end
