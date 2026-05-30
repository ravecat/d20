defmodule D20.Sessions do
  @moduledoc """
  Runtime boundary for dynamically created game session processes.
  """

  alias D20.Games
  alias D20.Module.Manifest
  alias D20.Sessions.Server
  alias D20.Sessions.Session

  @type slug :: String.t()
  @type session_id :: Server.id()
  @type ref :: {slug(), session_id()}
  @type reason ::
          :session_not_found
          | :game_not_found
          | :module_not_found
          | :engine_not_found
          | Session.reason()
  @type state :: Session.t()

  @spec create(String.t(), Session.player_id()) ::
          {:ok, Session.t()} | {:error, reason()}
  def create(slug, owner_id) when is_binary(slug) do
    with {:ok, game} <- Games.fetch_by_slug(slug),
         {:ok, _manifest} <- Manifest.fetch(game.slug),
         {:ok, engine} <- Manifest.fetch_engine(game.slug),
         {:ok, session} <- Session.new(engine, owner_id),
         {:ok, _pid} <- start_child(game.slug, engine, session) do
      {:ok, session}
    else
      {:error, :not_found} -> {:error, :game_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get(ref()) :: {:ok, state()} | {:error, reason()}
  def get({slug, id} = ref) when is_binary(slug) and is_binary(id) do
    call_if_exists(ref, &Server.get/1)
  end

  @spec dispatch(ref(), Session.event(), term()) ::
          {:ok, Session.t()} | {:error, reason()}
  def dispatch({slug, id} = ref, event, attrs) when is_binary(slug) and is_binary(id) do
    call_if_exists(ref, &Server.dispatch(&1, event, attrs))
  end

  @spec lookup(ref()) :: {:ok, pid()} | {:error, :session_not_found}
  def lookup({slug, id}) when is_binary(slug) and is_binary(id) do
    case Registry.lookup(D20.Registry, {:session, slug, id}) do
      [{pid, _value}] -> {:ok, pid}
      [] -> {:error, :session_not_found}
    end
  end

  @spec stop(ref(), term(), timeout()) :: :ok
  def stop(ref, reason \\ :normal, timeout \\ :infinity)

  def stop(ref, reason, timeout) do
    case lookup(ref) do
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

  defp call_if_exists(ref, fun) do
    with {:ok, pid} <- lookup(ref) do
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
