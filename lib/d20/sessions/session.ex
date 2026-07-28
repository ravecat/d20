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
  @type member :: %{
          required(:status) => :online | :offline,
          optional(:online_at) => integer(),
          optional(:display_name) => String.t(),
          optional(:avatar) => String.t() | nil
        }
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
        %Command{event: event, actor_id: actor_id} = command
      )
      when phase in [:waiting_for_players, :in_progress] and event in ["join", "left"] do
    with :ok <- require_identity(actor_id),
         {:ok, game} <- engine.dispatch(session.game, command) do
      {:ok, %{session | game: game}}
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

  @spec preview(t(), D20.Game.engine(), Command.t()) :: {:ok, map()} | {:error, reason()}
  def preview(
        %__MODULE__{phase: :in_progress, game: game},
        engine,
        %Command{actor_id: actor_id} = command
      ) do
    with :ok <- require_identity(actor_id) do
      engine.preview(game, command)
    end
  end

  def preview(%__MODULE__{}, _engine, %Command{}), do: {:error, :invalid_phase}

  @spec online(t(), player_id(), map()) :: {:ok, t()} | {:error, :invalid_identity}
  def online(%__MODULE__{} = session, actor_id, attrs) when is_map(attrs) do
    with :ok <- require_identity(actor_id) do
      member =
        attrs |> Map.take([:display_name, :avatar, :online_at]) |> Map.put(:status, :online)

      members = Map.update(session.members, actor_id, member, &Map.merge(&1, member))

      if members == session.members,
        do: {:ok, session},
        else: {:ok, %{session | members: members}}
    end
  end

  @spec offline(t(), player_id()) :: {:ok, t()} | {:error, :invalid_identity}
  def offline(%__MODULE__{} = session, actor_id) do
    with :ok <- require_identity(actor_id) do
      update_member(session, actor_id, &Map.put(&1, :status, :offline))
    end
  end

  @spec remove_member(t(), player_id()) :: {:ok, t()} | {:error, :invalid_identity}
  def remove_member(%__MODULE__{} = session, actor_id) do
    with :ok <- require_identity(actor_id) do
      members = Map.delete(session.members, actor_id)

      if members == session.members,
        do: {:ok, session},
        else: {:ok, %{session | members: members}}
    end
  end

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

  defp update_member(session, actor_id, update) do
    case Map.fetch(session.members, actor_id) do
      {:ok, member} ->
        updated_member = update.(member)

        if updated_member == member do
          {:ok, session}
        else
          {:ok, %{session | members: Map.put(session.members, actor_id, updated_member)}}
        end

      :error ->
        {:ok, session}
    end
  end
end
