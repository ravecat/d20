defmodule D20.Games do
  @moduledoc """
  Game catalog boundary.

  This context owns project-level game records. Public functions should describe
  product operations such as listing playable games, not upstream parser calls.
  """

  alias D20.Games.Game
  alias D20.Games.Registry
  alias D20.Games.Sources.BoardGameGeek

  @type playable_game :: %{slug: String.t(), game: Game.t()}
  @type list_error :: {:game_metadata_unavailable, String.t(), term()}

  @spec list() :: {:ok, [playable_game()]} | {:error, list_error()}
  def list do
    Enum.reduce_while(Registry.list(), {:ok, []}, fn entry, {:ok, games} ->
      case fetch_by_slug(entry.slug) do
        {:ok, game} -> {:cont, {:ok, games ++ [%{slug: entry.slug, game: game}]}}
        {:error, reason} -> {:halt, {:error, {:game_metadata_unavailable, entry.slug, reason}}}
      end
    end)
  end

  @spec fetch_by_slug(String.t()) :: {:ok, Game.t()} | {:error, term()}
  def fetch_by_slug(slug) when is_binary(slug) do
    with {:ok, entry} <- Registry.fetch(slug),
         {:ok, attrs} <- BoardGameGeek.fetch_game_details(entry.bgg_id),
         {:ok, game} <- Game.new(attrs) do
      {:ok, game}
    end
  end
end
