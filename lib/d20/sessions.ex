defmodule D20.Sessions do
  @moduledoc """
  Runtime boundary for dynamically created game session processes.
  """

  alias D20.Sessions.Server
  alias D20.Sessions.Session

  @type slug :: String.t()
  @type id :: Session.id()
  @type state :: {Session.t(), slug()}
  @type reason ::
          :session_not_found
          | Session.reason()

  @spec create(slug(), D20.Game.engine(), Session.player_id()) ::
          {:ok, Session.t()} | {:error, reason()}
  def create(slug, engine, owner_id) when is_binary(slug) do
    with {:ok, session} <- Session.new(engine, owner_id),
         {:ok, _pid} <- start_child(slug, engine, session) do
      {:ok, session}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get(id()) :: {:ok, state()} | {:error, reason()}
  def get(id) when is_binary(id) do
    call_if_exists(id, &Server.get/1)
  end

  @spec dispatch(id(), Session.event(), term()) ::
          {:ok, Session.t()} | {:error, reason()}
  def dispatch(id, event, attrs) when is_binary(id) do
    call_if_exists(id, &Server.dispatch(&1, event, attrs))
  end

  @spec lookup(id()) :: {:ok, pid()} | {:error, :session_not_found}
  def lookup(id) when is_binary(id) do
    case Registry.lookup(D20.Registry, Server.registry_key(id)) do
      [{pid, _value}] -> {:ok, pid}
      [] -> {:error, :session_not_found}
    end
  end

  @spec stop(id(), term(), timeout()) :: :ok
  def stop(id, reason \\ :normal, timeout \\ :infinity)

  def stop(id, reason, timeout) do
    case lookup(id) do
      {:ok, pid} ->
        try do
          GenServer.stop(pid, reason, timeout)
        catch
          :exit, {:noproc, {GenServer, :stop, _args}} -> :ok
        end

      {:error, :session_not_found} ->
        :ok
    end
  end

  defp call_if_exists(id, fun) do
    with {:ok, pid} <- lookup(id) do
      fun.(pid)
    end
  end

  defp start_child(slug, engine, session) do
    DynamicSupervisor.start_child(
      D20.Sessions.Supervisor,
      {Server, slug: slug, engine: engine, session: session}
    )
  end
end
