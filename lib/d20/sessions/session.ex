defmodule D20.Sessions.Session do
  @moduledoc """
  Generic game-session state machine around a game-specific engine.
  """

  import D20.Guards, only: [is_player_id: 1]

  alias D20.Command

  @derive {Jason.Encoder, only: [:id, :phase, :owner_id, :members, :game]}
  defstruct id: nil,
            phase: :waiting_for_players,
            owner_id: nil,
            members: %{},
            game: nil

  @type id :: Ecto.UUID.t()
  @type phase :: :waiting_for_players | :in_progress | :finished
  @type player_id :: D20.Actors.Actor.id()
  @type member :: map()
  @type members :: %{optional(player_id()) => member()}
  @type event :: String.t()
  @type engine_reason :: term()
  @type reason ::
          :invalid_engine
          | :invalid_creation_attrs
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

  @spec new(D20.Game.engine(), player_id(), map()) :: {:ok, t()} | {:error, reason()}
  def new(engine, owner_id, attrs \\ %{})

  def new(_engine, owner_id, _attrs) when not is_player_id(owner_id),
    do: {:error, :invalid_owner_id}

  def new(engine, owner_id, attrs) do
    with {:ok, engine} <- D20.Game.ensure_engine(engine),
         {:ok, game} <- D20.Game.init(engine, attrs) do
      {:ok, %__MODULE__{id: Ecto.UUID.generate(), owner_id: owner_id, members: %{}, game: game}}
    end
  end

  @spec dispatch(t(), D20.Game.engine(), Command.t()) :: {:ok, t()} | {:error, reason()}
  def dispatch(
        %__MODULE__{phase: phase} = session,
        engine,
        %Command{event: "join", actor_id: actor_id, attrs: attrs} = command
      )
      when phase in [:waiting_for_players, :in_progress] do
    with :ok <- require_identity(actor_id),
         {:ok, game} <- engine.dispatch(session.game, command) do
      members = Map.put(session.members, actor_id, attrs)

      {:ok, %{session | game: game, members: members}}
    end
  end

  def dispatch(
        %__MODULE__{phase: phase} = session,
        engine,
        %Command{event: "leave", actor_id: actor_id} = command
      )
      when phase in [:waiting_for_players, :in_progress] do
    with :ok <- require_identity(actor_id) do
      case Map.fetch(session.members, actor_id) do
        {:ok, _member} ->
          case engine.dispatch(session.game, command) do
            {:ok, game} ->
              members = Map.delete(session.members, actor_id)
              {:ok, %{session | game: game, members: members}}

            {:error, reason} ->
              {:error, reason}
          end

        :error ->
          {:ok, session}
      end
    end
  end

  def dispatch(
        %__MODULE__{phase: :waiting_for_players} = session,
        engine,
        %Command{event: "start", actor_id: actor_id} = command
      ) do
    with :ok <- require_owner(session, actor_id),
         {:ok, game} <- engine.dispatch(session.game, command) do
      {:ok, %{session | phase: :in_progress, game: game}}
    end
  end

  def dispatch(%__MODULE__{phase: :in_progress} = session, engine, %Command{} = command) do
    case engine.dispatch(session.game, command) do
      {:ok, game} -> {:ok, maybe_finish(%{session | game: game}, engine)}
      {:error, reason} -> {:error, reason}
    end
  end

  def dispatch(%__MODULE__{}, _engine, %Command{}), do: {:error, :invalid_phase}

  defp maybe_finish(session, engine) do
    if engine.finished?(session.game) do
      %{session | phase: :finished}
    else
      session
    end
  end

  defp require_identity(player_id) when is_player_id(player_id), do: :ok
  defp require_identity(_player_id), do: {:error, :invalid_identity}

  defp require_owner(_session, player_id) when not is_player_id(player_id),
    do: {:error, :invalid_identity}

  defp require_owner(%__MODULE__{owner_id: player_id}, player_id), do: :ok
  defp require_owner(%__MODULE__{}, _player_id), do: {:error, :not_owner}
end
