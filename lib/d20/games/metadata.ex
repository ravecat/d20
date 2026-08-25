defmodule D20.Games.Metadata do
  @moduledoc """
  Runtime-only BoardGameGeek presentation metadata for a persisted game.

  This embedded schema is never persisted to the `games` table. It is built at
  runtime from the row's current `bgg_id` binding so provider names, images,
  descriptions, player counts, and ratings remain non-authoritative.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  @fields [
    :name,
    :alternate_names,
    :categories,
    :mechanics,
    :description,
    :thumbnail_url,
    :image_url,
    :year_published,
    :min_players,
    :max_players,
    :playing_time,
    :min_play_time,
    :max_play_time,
    :min_age,
    :complexity,
    :rating
  ]

  embedded_schema do
    field :name, :string
    field :alternate_names, {:array, :string}, default: []
    field :categories, {:array, :string}, default: []
    field :mechanics, {:array, :string}, default: []
    field :description, :string
    field :thumbnail_url, :string
    field :image_url, :string
    field :year_published, :integer
    field :min_players, :integer
    field :max_players, :integer
    field :playing_time, :integer
    field :min_play_time, :integer
    field :max_play_time, :integer
    field :min_age, :integer
    field :complexity, :float
    field :rating, :float
  end

  @type t :: %__MODULE__{
          name: String.t() | nil,
          alternate_names: [String.t()],
          categories: [String.t()],
          mechanics: [String.t()],
          description: String.t() | nil,
          thumbnail_url: String.t() | nil,
          image_url: String.t() | nil,
          year_published: integer() | nil,
          min_players: integer() | nil,
          max_players: integer() | nil,
          playing_time: integer() | nil,
          min_play_time: integer() | nil,
          max_play_time: integer() | nil,
          min_age: integer() | nil,
          complexity: float() | nil,
          rating: float() | nil
        }

  @spec empty() :: t()
  def empty, do: %__MODULE__{}

  @spec new(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def new(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(metadata, attrs) do
    cast(metadata, attrs, @fields)
  end
end
