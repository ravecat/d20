defmodule D20.Games.Favorite do
  @moduledoc "Private account membership for a BoardGameGeek game."

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  @type t :: %__MODULE__{}

  schema "game_favorites" do
    field :user_id, TypeID, primary_key: true, prefix: "user"
    field :bgg_id, :integer, primary_key: true
    timestamps type: :utc_datetime, updated_at: false
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(favorite, attrs) do
    favorite
    |> cast(attrs, [:bgg_id])
    |> validate_required([:user_id, :bgg_id])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :bgg_id], name: :game_favorites_pkey)
  end
end
