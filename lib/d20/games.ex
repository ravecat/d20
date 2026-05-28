defmodule D20.Games do
  @moduledoc """
  Game metadata boundary.

  This context owns project-level game records. Public functions should describe
  product operations such as fetching game metadata, not upstream parser calls.
  """

  alias D20.Games.Game
  alias D20.Module.Manifest

  @typedoc """
  Server-side context required to display and run a game.

  Fields:

  - `:game` - product metadata for the game page.
  - `:manifest` - iframe module manifest used by the web shell.
  - `:engine` - runtime game engine module used by sessions.
  """
  @type context :: %{
          required(:game) => Game.t(),
          required(:manifest) => Manifest.entry(),
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

  @spec list() :: [Game.t()]
  def list do
    @mock_games
    |> Enum.sort_by(fn {slug, _attrs} -> slug end)
    |> Enum.map(fn {_slug, attrs} -> struct(Game, attrs) end)
  end

  @spec fetch_by_slug(String.t()) :: {:ok, Game.t()} | {:error, :not_found}
  def fetch_by_slug(slug) when is_binary(slug) do
    case Map.fetch(@mock_games, slug) do
      {:ok, attrs} -> {:ok, struct(Game, attrs)}
      :error -> {:error, :not_found}
    end
  end

  @doc """
  Fetches the server-side context for a game slug.

  The context joins project game metadata, the matching iframe module manifest
  entry, and the runtime engine module. It is a server API shape, not a client
  page payload.
  """
  @spec fetch_context_by_slug(String.t()) ::
          {:ok, context()}
          | {:error, :game_not_found | :module_not_found | :engine_not_found}
  def fetch_context_by_slug(slug) when is_binary(slug) do
    with {:ok, %Game{} = game} <- fetch_by_slug(slug),
         {:ok, manifest} <- Manifest.fetch(game.slug),
         {:ok, engine} <- Manifest.fetch_engine(game.slug) do
      {:ok, %{game: game, manifest: manifest, engine: engine}}
    else
      {:error, :not_found} -> {:error, :game_not_found}
      {:error, reason} -> {:error, reason}
    end
  end
end
