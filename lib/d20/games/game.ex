defmodule D20.Games.Game do
  @moduledoc """
  Persisted, operator-managed catalog game record.

  This schema owns only the stable local identity and operational bindings:
  the BoardGameGeek metadata binding (`bgg_id`), `stage`,
  the independent launch `enabled` flag, and the optional permanent engine
  mapping. It deliberately never persists provider-derived presentation fields
  or public slugs; those stay runtime-only in `D20.Games.Metadata`.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "game"}

  @type id :: TypeID.t()
  @type t :: %__MODULE__{
          id: id(),
          bgg_id: pos_integer(),
          stage: :planned | :in_development | :released,
          enabled: boolean(),
          engine: D20.Game.engine() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "games" do
    field :bgg_id, :integer

    field :stage, Ecto.Enum,
      values: [:planned, :in_development, :released],
      default: :planned

    field :enabled, :boolean, default: true

    # Permanent integer-backed engine mapping. The atoms are loaded engine
    # modules; the integers are never reordered, reused, or renumbered.
    field :engine, Ecto.Enum,
      values: [
        {D20.Fliptown.Game, 1},
        {D20.KoalaRescueClub.Game, 2},
        {D20.NextStationLondon.Game, 3},
        {D20.Qwinto.Game, 4}
      ]

    timestamps type: :utc_datetime
  end

  @doc """
  Returns the deployed game engines in enum order.
  """
  @spec engines() :: [D20.Game.engine()]
  def engines, do: Ecto.Enum.values(__MODULE__, :engine)

  @doc false
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t()
  def changeset(game_or_changeset, attrs) do
    game_or_changeset
    |> cast(attrs, [:bgg_id, :stage, :enabled, :engine])
    |> validate_required([:bgg_id, :stage, :enabled])
    |> validate_number(:bgg_id, greater_than: 0)
    |> validate_inclusion(:stage, [:planned, :in_development, :released])
    |> validate_engine_for_stage()
    |> unique_constraint(:bgg_id, name: :games_bgg_id_index)
    |> check_constraint(:bgg_id, name: :games_bgg_id_positive)
    |> check_constraint(:stage, name: :games_stage_domain)
    |> check_constraint(:engine, name: :games_engine_domain)
    |> check_constraint(:stage, name: :games_launch_stage_requires_engine)
  end

  defp validate_engine_for_stage(changeset) do
    stage = get_field(changeset, :stage)
    engine = get_field(changeset, :engine)

    if stage in [:in_development, :released] and is_nil(engine) do
      add_error(changeset, :engine, "is required")
    else
      changeset
    end
  end
end
