defmodule D20.Sessions do
  @moduledoc """
  Runtime boundary for dynamically created game session processes.
  """

  alias D20.Sessions.Server
  alias D20.Sessions.Session

  @default_timeout 5_000

  @type session_id :: Server.id()
  @type create_result :: %{
          required(:id) => session_id(),
          required(:session) => Session.t()
        }
  @type reason ::
          :session_not_found
          | Session.reason()

  @spec create(module(), Session.player_id()) ::
          {:ok, create_result()} | {:error, reason()}
  def create(engine, owner_id) do
    id = generate_id()

    with {:ok, _pid} <- start_child(id: id, engine: engine, owner_id: owner_id),
         {:ok, session} <- get(id) do
      {:ok, %{id: id, session: session}}
    end
  end

  @spec get(session_id(), timeout()) :: {:ok, Session.t()} | {:error, reason()}
  def get(id, timeout \\ @default_timeout) do
    call_if_exists(id, &Server.get(&1, timeout))
  end

  @spec dispatch(session_id(), atom(), map(), timeout()) ::
          {:ok, Session.t()} | {:error, reason()}
  def dispatch(id, event, attrs, timeout \\ @default_timeout) do
    call_if_exists(id, &Server.dispatch(&1, event, attrs, timeout))
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

  defp start_child(opts) do
    DynamicSupervisor.start_child(
      D20.Sessions.Supervisor,
      {Server, opts}
    )
  end

  defp generate_id do
    Ecto.UUID.generate()
  end
end
