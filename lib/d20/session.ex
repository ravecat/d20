defmodule D20.Session do
  @moduledoc """
  Generic table-level state machine around a game-specific engine.
  """

  import D20.Guards, only: [is_player_id: 1]

  defstruct phase: :waiting_for_players,
            engine: nil,
            owner_id: nil,
            members: %{},
            game: nil

  @type phase :: :waiting_for_players | :in_progress | :finished
  @type member_status :: :online | :offline
  @type player_id :: String.t()
  @type members :: %{optional(player_id()) => member_status()}
  @type engine_reason :: term()
  @type reason ::
          :invalid_engine
          | :invalid_owner_id
          | :invalid_identity
          | :not_owner
          | :invalid_phase
          | engine_reason()

  @type t :: %__MODULE__{
          phase: phase(),
          engine: module(),
          owner_id: player_id(),
          members: members(),
          game: term()
        }

  @spec new(module(), player_id()) :: {:ok, t()} | {:error, reason()}
  def new(engine, owner_id) when is_player_id(owner_id) do
    with :ok <- require_engine(engine),
         {:ok, game} <- engine.init(),
         {:ok, game} <- engine.dispatch(game, :join, %{player_id: owner_id}) do
      {:ok,
       %__MODULE__{
         engine: engine,
         owner_id: owner_id,
         members: %{owner_id => :online},
         game: game
       }}
    end
  end

  def new(_engine, _owner_id), do: {:error, :invalid_owner_id}

  @spec dispatch(t(), atom(), map()) :: {:ok, t()} | {:error, reason()}
  def dispatch(%__MODULE__{phase: phase} = session, :join, %{player_id: player_id})
      when phase in [:waiting_for_players, :in_progress] and is_player_id(player_id) do
    join(session, player_id)
  end

  def dispatch(%__MODULE__{}, :join, %{player_id: player_id})
      when is_player_id(player_id) do
    {:error, :invalid_phase}
  end

  def dispatch(%__MODULE__{}, :join, _attrs), do: {:error, :invalid_identity}

  def dispatch(%__MODULE__{phase: phase} = session, :leave, %{player_id: player_id})
      when phase in [:waiting_for_players, :in_progress] and is_player_id(player_id) do
    leave(session, player_id)
  end

  def dispatch(%__MODULE__{}, :leave, %{player_id: player_id})
      when is_player_id(player_id) do
    {:error, :invalid_phase}
  end

  def dispatch(%__MODULE__{}, :leave, _attrs), do: {:error, :invalid_identity}

  def dispatch(
        %__MODULE__{phase: :waiting_for_players} = session,
        :start,
        %{player_id: player_id} = attrs
      )
      when is_player_id(player_id) do
    with :ok <- require_owner(session, player_id),
         {:ok, game} <- session.engine.dispatch(session.game, :start, attrs) do
      {:ok, maybe_finish(%{session | phase: :in_progress, game: game})}
    end
  end

  def dispatch(%__MODULE__{phase: :waiting_for_players}, :start, _attrs) do
    {:error, :invalid_identity}
  end

  def dispatch(%__MODULE__{}, :start, _attrs), do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: phase} = session, event, attrs)
      when phase in [:waiting_for_players, :in_progress] do
    case session.engine.dispatch(session.game, event, attrs) do
      {:ok, game} -> {:ok, maybe_finish(%{session | game: game})}
      {:error, reason} -> {:error, reason}
    end
  end

  def dispatch(%__MODULE__{}, _event, _attrs), do: {:error, :invalid_phase}

  defp join(%__MODULE__{} = session, player_id) do
    with {:ok, members} <- join_members(session, player_id),
         {:ok, game} <- session.engine.dispatch(session.game, :join, %{player_id: player_id}) do
      {:ok, maybe_finish(%{session | game: game, members: members})}
    end
  end

  defp join_members(%__MODULE__{} = session, player_id) do
    case {session.phase, Map.fetch(session.members, player_id)} do
      {_phase, {:ok, _status}} -> {:ok, %{session.members | player_id => :online}}
      {:waiting_for_players, :error} -> {:ok, Map.put(session.members, player_id, :online)}
      {:in_progress, :error} -> {:error, :invalid_phase}
    end
  end

  defp leave(%__MODULE__{} = session, player_id) do
    case Map.fetch(session.members, player_id) do
      {:ok, _status} ->
        case session.engine.dispatch(session.game, :leave, %{player_id: player_id}) do
          {:ok, game} ->
            members = %{session.members | player_id => :offline}
            {:ok, maybe_finish(%{session | game: game, members: members})}

          {:error, reason} ->
            {:error, reason}
        end

      :error ->
        {:ok, session}
    end
  end

  defp maybe_finish(session) do
    if session.engine.finished?(session.game) do
      %{session | phase: :finished}
    else
      session
    end
  end

  defp require_engine(engine) when is_atom(engine) do
    if Code.ensure_loaded?(engine) and
         Enum.all?(D20.Game.behaviour_info(:callbacks), fn {name, arity} ->
           function_exported?(engine, name, arity)
         end) do
      :ok
    else
      {:error, :invalid_engine}
    end
  end

  defp require_engine(_engine), do: {:error, :invalid_engine}

  defp require_owner(_session, player_id) when not is_player_id(player_id) do
    {:error, :invalid_identity}
  end

  defp require_owner(%__MODULE__{owner_id: player_id}, player_id), do: :ok
  defp require_owner(%__MODULE__{}, _player_id), do: {:error, :not_owner}
end
