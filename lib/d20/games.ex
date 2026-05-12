defmodule D20.Games do
  @moduledoc """
  Game metadata boundary.

  This context owns project-level game records. Public functions should describe
  product operations such as fetching game metadata, not upstream parser calls.
  """

  alias D20.Games.Game
  alias D20.Module.Manifest

  @type playable_context :: %{
          required(:game) => Game.t(),
          required(:module_entry) => Manifest.module_entry(),
          required(:engine) => module()
        }

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

  @spec fetch_by_slug(String.t()) :: {:ok, Game.t()} | {:error, :not_found}
  def fetch_by_slug(slug) when is_binary(slug) do
    case Map.fetch(@mock_games, slug) do
      {:ok, attrs} -> {:ok, struct(Game, attrs)}
      :error -> {:error, :not_found}
    end
  end

  @spec fetch_playable_context_by_slug(String.t()) ::
          {:ok, playable_context()}
          | {:error, :game_not_found | :module_not_found | :engine_not_found}
  def fetch_playable_context_by_slug(slug) when is_binary(slug) do
    with {:ok, %Game{} = game} <- fetch_by_slug(slug),
         {:ok, module_entry} <- Manifest.fetch(game.slug),
         {:ok, engine} <- Manifest.fetch_engine(module_entry.id) do
      {:ok, %{game: game, module_entry: module_entry, engine: engine}}
    else
      {:error, :not_found} -> {:error, :game_not_found}
      {:error, reason} -> {:error, reason}
    end
  end
end
