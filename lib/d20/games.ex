defmodule D20.Games do
  @moduledoc """
  Local catalog and provider discovery boundary.

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

  @typedoc "Catalog entries use the BoardGameGeek ID as `id`, distinct from the local Game TypeID."
  @type catalog_entry :: %{
          id: pos_integer(),
          slug: String.t(),
          stage: :in_development | :released | nil,
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
  def list(options \\ []), do: list(Game, options)

  defp list(query, options) do
    options =
      [where: [], order_by: [], limit: 32]
      |> Keyword.merge(Keyword.take(options, [:where, :order_by, :limit]))
      |> Keyword.update!(:limit, fn
        limit when is_integer(limit) -> limit |> max(0) |> min(100)
        _limit -> 32
      end)

    games =
      query
      |> where(^options[:where])
      |> order_by(^options[:order_by])
      |> limit(^options[:limit])
      |> Repo.all()

    bgg_ids = Enum.map(games, & &1.bgg_id)

    metadata_by_bgg_id =
      case BoardGameGeek.fetch_games(bgg_ids) do
        {:ok, attrs} ->
          Map.new(attrs, &{&1.bgg_id, &1})

        {:error, reason} ->
          log_metadata_fallback(:catalog, reason)
          Map.new(games, &{&1.bgg_id, %{}})
      end

    entries =
      Enum.map(games, fn game ->
        metadata =
          case Map.fetch(metadata_by_bgg_id, game.bgg_id) do
            {:ok, attrs} ->
              metadata_from_attrs(attrs, {:game, game.id})

            :error ->
              log_metadata_fallback({:game, game.id}, :game_not_found)
              Metadata.empty()
          end

        %{id: game.bgg_id, slug: game.slug, stage: game.stage, metadata: metadata}
      end)

    {:ok, entries}
  end

  @doc """
  Lists enabled games with visible stages and implemented engines.

  Accepts the same options and defaults as `list/1`. Caller conditions further
  narrow the playable scope; no order is requested unless supplied.
  """
  @spec list_playable() :: {:ok, [catalog_entry()]} | {:error, term()}
  @spec list_playable(
          where: keyword() | Ecto.Query.dynamic_expr(),
          order_by: atom() | [atom()] | keyword(),
          limit: term()
        ) :: {:ok, [catalog_entry()]} | {:error, term()}
  def list_playable(options \\ []) do
    stages = Application.fetch_env!(:d20, :visible_game_stages)
    engines = Game.engines()

    Game
    |> where([game], game.enabled == true and game.stage in ^stages and game.engine in ^engines)
    |> list(options)
  end

  @doc """
  Lists a random selection of BGG Hot games with optional visible local fields.

  Only `limit` is supported. Missing, nonpositive, or non-integer values use 32;
  positive integers are capped at 100.
  Unknown options are ignored. Provider membership does not require a local row.
  """
  @spec list_by_provider() :: {:ok, [catalog_entry()]} | {:error, term()}
  @spec list_by_provider(limit: term()) :: {:ok, [catalog_entry()]} | {:error, term()}
  def list_by_provider(options \\ []) do
    with {:ok, attrs} <- BoardGameGeek.fetch_hot_games(Keyword.take(options, [:limit])) do
      bgg_ids = Enum.map(attrs, & &1.bgg_id)
      stages = Application.fetch_env!(:d20, :visible_game_stages)

      entries_by_bgg_id =
        Game
        |> where([game], game.bgg_id in ^bgg_ids and game.stage in ^stages)
        |> Repo.all()
        |> Map.new(&{&1.bgg_id, &1})

      entries =
        Enum.map(attrs, fn attrs ->
          entry = Map.get(entries_by_bgg_id, attrs.bgg_id)

          %{
            id: attrs.bgg_id,
            slug: if(entry, do: entry.slug, else: Integer.to_string(attrs.bgg_id)),
            stage: entry && entry.stage,
            metadata: metadata_from_attrs(attrs, {:bgg_game, attrs.bgg_id})
          }
        end)

      {:ok, entries}
    end
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
  Resolves a detail route by exact local slug, then asks BGG using the raw slug.

  Provider-only details have no persisted entry. Their route slug is normalized
  to a decimal string, and provider or Metadata errors are preserved.
  """
  @spec fetch_by_slug(String.t()) ::
          {:ok,
           %{
             entry: Game.t() | nil,
             slug: String.t(),
             bgg_id: pos_integer(),
             metadata: Metadata.t()
           }}
          | {:error, term()}
  def fetch_by_slug(slug) when is_binary(slug) do
    case Repo.get_by(Game, slug: slug) do
      %Game{} = game ->
        {:ok,
         %{entry: game, slug: game.slug, bgg_id: game.bgg_id, metadata: fetch_game_metadata(game)}}

      nil ->
        with {:ok, attrs} <- BoardGameGeek.fetch_game(slug),
             {:ok, metadata} <- Metadata.new(attrs) do
          {:ok,
           %{
             entry: nil,
             slug: Integer.to_string(attrs.bgg_id),
             bgg_id: attrs.bgg_id,
             metadata: metadata
           }}
        end
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

  @doc "Returns whether the game's stage is visible under the configured stage policy."
  @spec visible?(Game.t()) :: boolean()
  def visible?(%Game{stage: stage}) do
    stage in Application.fetch_env!(:d20, :visible_game_stages)
  end

  @doc """
  Returns whether a new Session may be created for the persisted game.
  """
  @spec session_launch_available?(Game.t()) :: boolean()
  def session_launch_available?(%Game{enabled: true} = game) do
    visible?(game) and match?({:ok, _engine}, engine(game))
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

  defp metadata_from_attrs(attrs, scope) do
    case Metadata.new(attrs) do
      {:ok, metadata} ->
        metadata

      {:error, reason} ->
        log_metadata_fallback(scope, reason)
        Metadata.empty()
    end
  end

  defp fetch_game_metadata(game) do
    with {:ok, attrs} <- BoardGameGeek.fetch_game(game.bgg_id),
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
