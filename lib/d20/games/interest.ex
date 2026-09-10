defmodule D20.Games.Interest do
  @moduledoc "One account's request for a BoardGameGeek game's online availability."

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "interest"}
  schema "game_interests" do
    field :user_id, TypeID, prefix: "user"
    field :bgg_id, :integer
    timestamps type: :utc_datetime, updated_at: false
  end

  @type t :: %__MODULE__{
          id: TypeID.t(),
          user_id: TypeID.t(),
          bgg_id: pos_integer(),
          inserted_at: DateTime.t() | nil
        }

  @doc "Validates identities supplied by the authenticated request boundary."
  @spec changeset(TypeID.t(), integer()) :: Ecto.Changeset.t(t())
  def changeset(user_id, bgg_id) do
    %__MODULE__{}
    |> change(user_id: user_id, bgg_id: bgg_id)
    |> validate_required([:user_id, :bgg_id])
    |> validate_number(:bgg_id, greater_than: 0)
    |> foreign_key_constraint(:user_id)
    |> check_constraint(:bgg_id, name: :game_interests_bgg_id_positive)
  end
end
