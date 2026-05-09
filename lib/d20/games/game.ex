defmodule D20.Games.Game do
  @moduledoc """
  Product-owned game metadata.

  This schema describes a game record in this project. It is separate from
  `D20.Game`, which is a runtime behaviour for session engines.
  """

  use Ecto.Schema

  @primary_key false

  embedded_schema do
    field :external_id, :integer
    field :slug, :string
    field :name, :string
    field :alternate_names, {:array, :string}, default: []
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
  end

  @type t :: %__MODULE__{
          external_id: integer() | nil,
          slug: String.t() | nil,
          name: String.t() | nil,
          alternate_names: [String.t()],
          description: String.t() | nil,
          thumbnail_url: String.t() | nil,
          image_url: String.t() | nil,
          year_published: integer() | nil,
          min_players: integer() | nil,
          max_players: integer() | nil,
          playing_time: integer() | nil,
          min_play_time: integer() | nil,
          max_play_time: integer() | nil,
          min_age: integer() | nil
        }
end
