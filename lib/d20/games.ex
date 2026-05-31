defmodule D20.Games do
  @moduledoc """
  Game metadata boundary.

  This context owns project-level game records. Public functions should describe
  product operations such as fetching game metadata, not upstream parser calls.
  """

  alias D20.Games.Game

  @mock_games %{
    "qwinto" => %{
      external_id: 183_006,
      slug: "qwinto",
      name: "Qwinto",
      alternate_names: [],
      description:
        "A fast roll-and-write dice game where players place sums into colored rows while preserving ascending order.",
      thumbnail_url: nil,
      image_url: nil,
      year_published: 2015,
      min_players: 2,
      max_players: 4,
      playing_time: 15,
      min_play_time: 10,
      max_play_time: 20,
      min_age: 8
    }
  }

  @spec list() :: [Game.t()]
  def list do
    @mock_games
    |> Enum.sort_by(fn {slug, _attrs} -> slug end)
    |> Enum.map(fn {_slug, attrs} -> struct(Game, attrs) end)
  end

  @spec fetch_by_slug(String.t()) :: {:ok, Game.t()} | {:error, :game_not_found}
  def fetch_by_slug(slug) when is_binary(slug) do
    case Map.fetch(@mock_games, slug) do
      {:ok, attrs} -> {:ok, struct(Game, attrs)}
      :error -> {:error, :game_not_found}
    end
  end
end
