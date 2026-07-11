defmodule D20.Games do
  @moduledoc """
  Game catalog boundary.

  This context owns project-level game records. Public functions should describe
  product operations such as listing playable games, not upstream parser calls.
  """

  alias D20.Games.Game
  alias D20.Games.Registry
  alias D20.Games.Sources.BoardGameGeek

  @type catalog_game :: %{slug: String.t(), status: :active | :in_progress | nil, game: Game.t()}

  @spec list() :: {:ok, [catalog_game()]} | {:error, term()}
  def list do
    status_order = %{nil => 2, active: 0, in_progress: 1}
    entries = Enum.sort_by(Registry.list(), &Map.fetch!(status_order, &1.status))

    with {:ok, attrs} <- entries |> Enum.map(& &1.bgg_id) |> BoardGameGeek.fetch_games_details(),
         games_by_bgg_id = Map.new(attrs, &{&1.bgg_id, &1}),
         {:ok, games} <-
           Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, games} ->
             with {:ok, game_attrs} <- Map.fetch(games_by_bgg_id, entry.bgg_id),
                  {:ok, game} <- Game.new(game_attrs) do
               {:cont, {:ok, [%{slug: entry.slug, status: entry.status, game: game} | games]}}
             else
               :error ->
                 {:halt, {:error, {:game_metadata_unavailable, entry.slug, :game_not_found}}}

               {:error, reason} ->
                 {:halt, {:error, {:game_metadata_unavailable, entry.slug, reason}}}
             end
           end) do
      {:ok, Enum.reverse(games)}
    end
  end

  @spec fetch_by_slug(String.t()) :: {:ok, Game.t()} | {:error, term()}
  def fetch_by_slug(slug) when is_binary(slug) do
    with {:ok, entry} <- Registry.fetch(slug),
         {:ok, attrs} <- BoardGameGeek.fetch_game_details(entry.bgg_id),
         {:ok, game} <- Game.new(attrs) do
      {:ok, game}
    end
  end

  @spec session_launch_available?(Registry.Entry.t()) :: boolean()
  def session_launch_available?(%Registry.Entry{status: status}) do
    Application.fetch_env!(:d20, :game_session_launch_enabled) and
      status in [:active, :in_progress]
  end
end
