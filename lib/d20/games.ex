defmodule D20.Games do
  @moduledoc """
  Game catalog boundary.

  This context owns project-level game records. Public functions should describe
  product operations such as listing playable games, not upstream parser calls.
  """

  require Logger

  alias D20.Games.Game
  alias D20.Games.Registry
  alias D20.Games.Sources.BoardGameGeek

  @type catalog_game :: %{slug: String.t(), status: :active | :in_progress | nil, game: Game.t()}

  @spec list() :: {:ok, [catalog_game()]} | {:error, term()}
  def list do
    status_order = %{nil => 2, active: 0, in_progress: 1}
    entries = Enum.sort_by(Registry.list(), &Map.fetch!(status_order, &1.status))
    {metadata_by_bgg_id, metadata_status} = fetch_catalog_metadata(entries)

    with {:ok, games} <-
           Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, games} ->
             metadata = catalog_metadata(entry, metadata_by_bgg_id, metadata_status)

             case Game.new(metadata) do
               {:ok, game} ->
                 {:cont, {:ok, [%{slug: entry.slug, status: entry.status, game: game} | games]}}

               {:error, reason} ->
                 {:halt, {:error, {:game_metadata_unavailable, entry.slug, reason}}}
             end
           end) do
      {:ok, Enum.reverse(games)}
    end
  end

  @spec fetch_by_slug(String.t()) :: {:ok, Game.t()} | {:error, term()}
  def fetch_by_slug(slug) when is_binary(slug) do
    with {:ok, entry} <- Registry.fetch(slug) do
      entry
      |> fetch_game_metadata()
      |> Game.new()
    end
  end

  @spec session_launch_available?(Registry.Entry.t()) :: boolean()
  def session_launch_available?(%Registry.Entry{status: :active}), do: true

  def session_launch_available?(%Registry.Entry{status: :in_progress}) do
    Application.fetch_env!(:d20, :allow_launch_in_progress)
  end

  def session_launch_available?(%Registry.Entry{}), do: false

  defp fetch_catalog_metadata(entries) do
    bgg_ids = Enum.map(entries, & &1.bgg_id)

    case BoardGameGeek.fetch_games_details(bgg_ids) do
      {:ok, metadata} ->
        {Map.new(metadata, &{&1.bgg_id, &1}), :available}

      {:error, reason} ->
        log_metadata_fallback(:catalog, reason)
        {%{}, :unavailable}
    end
  end

  defp catalog_metadata(entry, metadata_by_bgg_id, :available) do
    case Map.fetch(metadata_by_bgg_id, entry.bgg_id) do
      {:ok, metadata} ->
        metadata

      :error ->
        log_metadata_fallback({:game, entry.slug}, :game_not_found)
        %{}
    end
  end

  defp catalog_metadata(_entry, _metadata_by_bgg_id, :unavailable), do: %{}

  defp fetch_game_metadata(entry) do
    case BoardGameGeek.fetch_game_details(entry.bgg_id) do
      {:ok, metadata} ->
        metadata

      {:error, reason} ->
        log_metadata_fallback({:game, entry.slug}, reason)
        %{}
    end
  end

  defp log_metadata_fallback(scope, reason) do
    Logger.warning("Failed to enrich game metadata; using local fallback",
      source: :board_game_geek,
      scope: scope,
      reason: reason
    )
  end
end
