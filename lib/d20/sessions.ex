defmodule D20.Sessions do
  @moduledoc """
  Runtime boundary for dynamically created game session processes.
  """

  alias D20.Games
  alias D20.Sessions.Server
  alias D20.Sessions.Session

  @type session_id :: Server.id()
  @type reason ::
          :session_not_found
          | :game_not_found
          | :module_not_found
          | :engine_not_found
          | Session.reason()
  @type state :: Server.state()

  @spec create(String.t(), Session.player_id()) ::
          {:ok, Session.t()} | {:error, reason()}
  def create(game_slug, owner_id) when is_binary(game_slug) do
    with {:ok, %{engine: engine}} <- Games.fetch_context_by_slug(game_slug),
         {:ok, session} <- Session.new(engine, owner_id),
         {:ok, _pid} <- start_child(session) do
      {:ok, session}
    end
  end

  @spec get(session_id()) :: {:ok, state()} | {:error, reason()}
  def get(id) do
    call_if_exists(id, &Server.get/1)
  end

  @spec dispatch(session_id(), Session.event(), term()) ::
          {:ok, Session.t()} | {:error, reason()}
  def dispatch(id, event, attrs) do
    call_if_exists(id, &Server.dispatch(&1, event, attrs))
  end

  @spec lookup(session_id()) :: {:ok, pid()} | {:error, :session_not_found}
  def lookup(id) do
    case Registry.lookup(D20.Registry, {:session, id}) do
      [{pid, _value}] when is_pid(pid) -> lookup_alive(pid)
      [] -> {:error, :session_not_found}
    end
  end

  @spec stop(session_id(), term(), timeout()) :: :ok
  def stop(id, reason \\ :normal, timeout \\ :infinity)

  def stop(id, reason, timeout) do
    case lookup(id) do
      {:ok, pid} -> GenServer.stop(pid, reason, timeout)
      {:error, :session_not_found} -> :ok
    end
  end

  defp call_if_exists(id, fun) do
    with {:ok, pid} <- lookup(id) do
      fun.(pid)
    end
  end

  defp lookup_alive(pid) do
    if Process.alive?(pid) do
      {:ok, pid}
    else
      {:error, :session_not_found}
    end
  end

  defp start_child(session) do
    DynamicSupervisor.start_child(D20.Sessions.Supervisor, {Server, session: session})
  end
end
