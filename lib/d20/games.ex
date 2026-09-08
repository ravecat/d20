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
          stage: :in_development | :released,
          metadata: Metadata.t()
        }

  @doc """
  Lists persisted games, enriched with runtime BGG metadata; defaults to 32 records.

  By default, all games are eligible and no order is requested. Options compose
  in the Ecto query before records are loaded and metadata is fetched:

  * `where` - Ecto keyword conditions or a dynamic expression; defaults to `[]`
  * `order_by` - Ecto fields and directions; defaults to `[]`
  * `limit` - integers are clamped to 0..100; missing or non-integer values use 32

  Conditions use schema fields directly without implicit launch policy.
  Unknown options are ignored. Ecto validates supplied query expressions.
  """
  @spec list() :: {:ok, [catalog_entry()]} | {:error, term()}
  @spec list(
          where: keyword() | Ecto.Query.dynamic_expr(),
          order_by: atom() | [atom()] | keyword(),
          limit: term()
        ) :: {:ok, [catalog_entry()]} | {:error, term()}
  def list(options \\ []) do
    options =
      [where: [], order_by: [], limit: 32]
      |> Keyword.merge(Keyword.take(options, [:where, :order_by, :limit]))
      |> Keyword.update!(:limit, fn
        limit when is_integer(limit) -> limit |> max(0) |> min(100)
        _limit -> 32
      end)

    games =
      Game
      |> where(^options[:where])
      |> order_by(^options[:order_by])
      |> limit(^options[:limit])
      |> Repo.all()

    bgg_ids = Enum.map(games, & &1.bgg_id)

    metadata_by_bgg_id =
      case BoardGameGeek.fetch_games_details(bgg_ids) do
        {:ok, attrs} ->
          Map.new(attrs, &{&1.bgg_id, &1})

        {:error, reason} ->
          log_metadata_fallback(:catalog, reason)
          Map.new(games, &{&1.bgg_id, %{}})
      end

    entries =
      Enum.map(games, fn game ->
        metadata =
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

        %{id: game.id, slug: game.slug, stage: game.stage, metadata: metadata}
      end)

    {:ok, entries}
  end

  @doc """
  Lists up to the requested limit of launchable games in stage and id order.
  """
  @spec list_playable(term()) :: {:ok, [catalog_entry()]} | {:error, term()}
  def list_playable(limit) do
    stages = Application.fetch_env!(:d20, :visible_game_stages)
    engines = Game.engines()

    list(
      where:
        dynamic(
          [game],
          game.enabled == true and game.stage in ^stages and game.engine in ^engines
        ),
      limit: limit,
      order_by: [desc: :stage, asc: :id]
    )
  end

  @doc """
  Lists up to 32 visible games excluding the supplied ids, without requesting an order.
  """
  @spec list_browsable([Game.id()]) :: {:ok, [catalog_entry()]} | {:error, term()}
  def list_browsable(excluded_ids) do
    stages = Application.fetch_env!(:d20, :visible_game_stages)
    list(where: dynamic([game], game.stage in ^stages and game.id not in ^excluded_ids))
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
  def session_launch_available?(%Game{enabled: true} = game) do
    game.stage in Application.fetch_env!(:d20, :visible_game_stages) and
      match?({:ok, _engine}, engine(game))
  end

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
