defmodule D20.Sessions.Session do
  @moduledoc """
  Generic game-session state machine around a game-specific engine.
  """

  import D20.Guards, only: [is_player_id: 1]

  @derive {Jason.Encoder, only: [:id, :phase, :owner_id, :members, :game]}
  defstruct id: nil,
            phase: :waiting_for_players,
            owner_id: nil,
            members: %{},
            game: nil

  @type id :: Ecto.UUID.t()
  @type phase :: :waiting_for_players | :in_progress | :finished
  @type player_id :: String.t()
  @type member :: %{
          required(:online_at) => non_neg_integer(),
          optional(:display_name) => String.t(),
          optional(:avatar) => String.t() | nil
        }
  @type members :: %{optional(player_id()) => member()}
  @type event :: String.t()
  @type engine_reason :: term()
  @type reason ::
          :invalid_engine
          | :invalid_owner_id
          | :invalid_command
          | :invalid_identity
          | :not_owner
          | :invalid_phase
          | engine_reason()

  @type t :: %__MODULE__{
          id: id(),
          phase: phase(),
          owner_id: player_id(),
          members: members(),
          game: term()
        }

  @spec new(D20.Game.engine(), player_id()) :: {:ok, t()} | {:error, reason()}
  def new(engine, owner_id) when is_player_id(owner_id) do
    with {:ok, engine} <- D20.Game.ensure_engine(engine),
         {:ok, game} <- engine.init(),
         {:ok, game} <- engine.dispatch(game, "join", %{player_id: owner_id}) do
      {:ok, %__MODULE__{id: Ecto.UUID.generate(), owner_id: owner_id, members: %{}, game: game}}
    end
  end

  def new(_engine, _owner_id), do: {:error, :invalid_owner_id}

  @spec dispatch(t(), D20.Game.engine(), event(), term()) :: {:ok, t()} | {:error, reason()}
  def dispatch(%__MODULE__{}, _engine, _event, attrs) when not is_map(attrs) do
    {:error, :invalid_command}
  end

  def dispatch(%__MODULE__{}, _engine, event, _attrs) when not is_binary(event) do
    {:error, :invalid_command}
  end

  def dispatch(
        %__MODULE__{phase: phase} = session,
        engine,
        "join",
        %{player_id: player_id, online_at: _online_at} = attrs
      )
      when phase in [:waiting_for_players, :in_progress] do
    with {:ok, game} <- engine.dispatch(session.game, "join", %{player_id: player_id}) do
      member = Map.delete(attrs, :player_id)
      members = Map.put(session.members, player_id, member)

      {:ok, maybe_finish(%{session | game: game, members: members}, engine)}
    end
  end

  def dispatch(%__MODULE__{phase: phase}, _engine, "join", %{player_id: player_id})
      when phase in [:waiting_for_players, :in_progress] and is_player_id(player_id) do
    {:error, :invalid_command}
  end

  def dispatch(%__MODULE__{}, _engine, "join", %{player_id: player_id})
      when is_player_id(player_id) do
    {:error, :invalid_phase}
  end

  def dispatch(%__MODULE__{}, _engine, "join", _attrs), do: {:error, :invalid_identity}

  def dispatch(%__MODULE__{phase: phase} = session, engine, "leave", %{player_id: player_id})
      when phase in [:waiting_for_players, :in_progress] and is_player_id(player_id) do
    leave(session, engine, player_id)
  end

  def dispatch(%__MODULE__{}, _engine, "leave", %{player_id: player_id})
      when is_player_id(player_id) do
    {:error, :invalid_phase}
  end

  def dispatch(%__MODULE__{}, _engine, "leave", _attrs), do: {:error, :invalid_identity}

  def dispatch(
        %__MODULE__{phase: :waiting_for_players} = session,
        engine,
        "start",
        %{player_id: player_id} = attrs
      )
      when is_player_id(player_id) do
    with :ok <- require_owner(session, player_id),
         {:ok, game} <- engine.dispatch(session.game, "start", attrs) do
      {:ok, maybe_finish(%{session | phase: :in_progress, game: game}, engine)}
    end
  end

  def dispatch(%__MODULE__{phase: :waiting_for_players}, _engine, "start", _attrs) do
    {:error, :invalid_identity}
  end

  def dispatch(%__MODULE__{}, _engine, "start", _attrs), do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: phase} = session, engine, event, attrs)
      when phase in [:waiting_for_players, :in_progress] do
    case engine.dispatch(session.game, event, attrs) do
      {:ok, game} -> {:ok, maybe_finish(%{session | game: game}, engine)}
      {:error, reason} -> {:error, reason}
    end
  end

  def dispatch(%__MODULE__{}, _engine, _event, _attrs), do: {:error, :invalid_phase}

  defp leave(%__MODULE__{} = session, engine, player_id) do
    case Map.fetch(session.members, player_id) do
      {:ok, _member} ->
        case engine.dispatch(session.game, "leave", %{player_id: player_id}) do
          {:ok, game} ->
            members = Map.delete(session.members, player_id)
            {:ok, maybe_finish(%{session | game: game, members: members}, engine)}

          {:error, reason} ->
            {:error, reason}
        end

      :error ->
        {:ok, session}
    end
  end

  defp maybe_finish(session, engine) do
    if engine.finished?(session.game) do
      %{session | phase: :finished}
    else
      session
    end
  end

  defp require_owner(_session, player_id) when not is_player_id(player_id) do
    {:error, :invalid_identity}
  end

  defp require_owner(%__MODULE__{owner_id: player_id}, player_id), do: :ok
  defp require_owner(%__MODULE__{}, _player_id), do: {:error, :not_owner}
end
