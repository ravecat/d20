defmodule D20.Sessions.Server do
  @moduledoc """
  Process wrapper that owns one `D20.Sessions.Session` state.
  """

  use GenServer, restart: :temporary

  alias D20.Sessions.Session

  @type id :: Ecto.UUID.t()
  @type start_opts :: [
          id: id(),
          engine: module(),
          owner_id: Session.player_id()
        ]
  @spec start_link(start_opts()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via(Keyword.fetch!(opts, :id)))
  end

  @impl true
  def init(opts) do
    with {:ok, engine} <- Keyword.fetch(opts, :engine),
         {:ok, owner_id} <- Keyword.fetch(opts, :owner_id),
         {:ok, session} <- Session.new(engine, owner_id) do
      {:ok, session}
    else
      :error -> {:stop, :badarg}
      {:error, reason} -> {:stop, reason}
    end
  end

  @spec get(GenServer.server(), timeout()) :: {:ok, Session.t()}
  def get(server, timeout) do
    GenServer.call(server, :get, timeout)
  end

  @spec dispatch(GenServer.server(), atom(), map(), timeout()) ::
          {:ok, Session.t()} | {:error, Session.reason()}
  def dispatch(server, event, attrs, timeout) do
    GenServer.call(server, {:dispatch, event, attrs}, timeout)
  end

  @impl true
  def handle_call(:get, _from, session) do
    {:reply, {:ok, session}, session}
  end

  def handle_call({:dispatch, event, attrs}, _from, session) do
    case Session.dispatch(session, event, attrs) do
      {:ok, session} -> {:reply, {:ok, session}, session}
      {:error, reason} -> {:reply, {:error, reason}, session}
    end
  end

  defp via(id) do
    {:via, Registry, {D20.Registry, {:session, id}}}
  end
end
