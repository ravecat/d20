defmodule D20.Games do
  @moduledoc """
  Persisted game catalog boundary.

  This context owns project-level game records. Local games carry a stable
  environment-local `games.id` TypeID for internal boundaries and a required
  immutable external `games.slug` for public navigation. Presentation metadata
  is resolved at runtime from BoardGameGeek using each row's current `bgg_id`
  and is never persisted.
  """

  require Logger

  alias D20.Games.Game
  alias D20.Games.Metadata
  alias D20.Games.Sources.BoardGameGeek
  alias D20.Repo

  import Ecto.Query, warn: false

  @type catalog_entry :: %{
          id: Game.id(),
          slug: String.t(),
          stage: :planned | :in_development | :released,
          metadata: Metadata.t()
        }

  @stage_order %{released: 0, in_development: 1, planned: 2}

  @doc """
  Lists the catalog in release-stage order (released, in_development, planned)
  and by local id within each stage, enriched with runtime BGG
  metadata.
  """
  @spec list() :: {:ok, [catalog_entry()]} | {:error, term()}
  def list do
    games = Repo.all(from game in Game, order_by: [asc: game.stage, asc: game.id])

    games = Enum.sort_by(games, fn game -> {Map.fetch!(@stage_order, game.stage), game.id} end)

    {metadata_by_bgg_id, metadata_status} = fetch_catalog_metadata(games)

    entries =
      Enum.map(games, fn game ->
        metadata = catalog_metadata(game, metadata_by_bgg_id, metadata_status)

        %{id: game.id, slug: game.slug, stage: game.stage, metadata: metadata}
      end)

    {:ok, entries}
  end

  @doc """
  Loads one persisted catalog game by stable local id, resolving runtime
  metadata from its current `bgg_id`.
  """
  @spec fetch_by_id(term()) :: {:ok, {Game.t(), Metadata.t()}} | {:error, term()}
  def fetch_by_id(id) do
    case Repo.get(Game, id) do
      %Game{} = game -> {:ok, {game, fetch_game_metadata(game)}}
      nil -> {:error, :game_not_found}
    end
  end

  @doc """
  Loads one persisted catalog game by stable local id without enriching metadata.
  """
  @spec get(term()) :: {:ok, Game.t()} | {:error, term()}
  def get(id) do
    case Repo.get(Game, id) do
      %Game{} = game -> {:ok, game}
      nil -> {:error, :game_not_found}
    end
  end

  @doc """
  Loads one persisted catalog game by required external slug, resolving runtime
  metadata from its current `bgg_id`.
  """
  @spec fetch_by_slug(String.t()) :: {:ok, {Game.t(), Metadata.t()}} | {:error, term()}
  def fetch_by_slug(slug) when is_binary(slug) do
    case Repo.get_by(Game, slug: slug) do
      %Game{} = game -> {:ok, {game, fetch_game_metadata(game)}}
      nil -> {:error, :game_not_found}
    end
  end

  @doc """
  Loads one persisted catalog game by required external slug without enriching
  metadata.
  """
  @spec get_by_slug(String.t()) :: {:ok, Game.t()} | {:error, term()}
  def get_by_slug(slug) when is_binary(slug) do
    case Repo.get_by(Game, slug: slug) do
      %Game{} = game -> {:ok, game}
      nil -> {:error, :game_not_found}
    end
  end

  @doc """
  Returns whether a new Session may be created for the persisted game.
  """
  @spec session_launch_available?(Game.t()) :: boolean()
  def session_launch_available?(%Game{enabled: false}), do: false

  def session_launch_available?(%Game{stage: :released} = game),
    do: engine_resolves?(game)

  def session_launch_available?(%Game{stage: :in_development} = game),
    do: allow_launch_in_development?() and engine_resolves?(game)

  def session_launch_available?(%Game{}), do: false

  @doc """
  Resolves and validates the engine module for a persisted game.
  """
  @spec engine(Game.t()) :: {:ok, D20.Game.engine()} | {:error, term()}
  def engine(%Game{engine: nil}), do: {:error, :invalid_engine}

  def engine(%Game{engine: engine}) do
    D20.Game.ensure_engine(engine)
  end

  @doc """
  Builds a changeset for an existing persisted game.
  """
  @spec changeset(Game.t(), map()) :: Ecto.Changeset.t()
  def changeset(%Game{} = game, attrs), do: Game.changeset(game, attrs)

  @doc """
  Updates a persisted game record.
  """
  @spec update(Game.t(), map()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def update(%Game{} = game, attrs) do
    game
    |> changeset(attrs)
    |> Repo.update()
  end

  defp engine_resolves?(%Game{engine: engine}) when not is_nil(engine) do
    match?({:ok, _}, D20.Game.ensure_engine(engine))
  end

  defp engine_resolves?(%Game{}), do: false

  defp allow_launch_in_development? do
    Application.fetch_env!(:d20, :allow_launch_in_development)
  end

  defp fetch_catalog_metadata(games) do
    bgg_ids = Enum.map(games, & &1.bgg_id)

    case BoardGameGeek.fetch_games_details(bgg_ids) do
      {:ok, metadata} ->
        {Map.new(metadata, &{&1.bgg_id, &1}), :available}

      {:error, reason} ->
        log_metadata_fallback(:catalog, reason)
        {%{}, :unavailable}
    end
  end

  defp catalog_metadata(game, metadata_by_bgg_id, :available) do
    with {:ok, attrs} <- Map.fetch(metadata_by_bgg_id, game.bgg_id),
         {:ok, metadata} <- Metadata.new(attrs) do
      metadata
    else
      :error ->
        log_metadata_fallback({:game, game.id}, :game_not_found)
        Metadata.empty()

      {:error, reason} ->
        log_metadata_fallback({:game, game.id}, reason)
        Metadata.empty()
    end
  end

  defp catalog_metadata(_game, _metadata_by_bgg_id, :unavailable), do: Metadata.empty()

  defp fetch_game_metadata(game) do
    with {:ok, attrs} <- BoardGameGeek.fetch_game_details(game.bgg_id),
         {:ok, metadata} <- Metadata.new(attrs) do
      metadata
    else
      {:error, reason} ->
        log_metadata_fallback({:game, game.id}, reason)
        Metadata.empty()
    end
  end

  defp log_metadata_fallback(scope, reason) do
    # Production logger metadata is outside this tooling-only change.
    # credo:disable-for-next-line Credo.Check.Warning.MissedMetadataKeyInLoggerConfig
    Logger.warning("Failed to enrich game metadata; using local fallback",
      source: :board_game_geek,
      scope: scope,
      reason: reason
    )
  end
end
