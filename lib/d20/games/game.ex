defmodule D20.Games.Game do
  @moduledoc """
  Persisted, operator-managed catalog game record.

  This schema owns the stable local identity (`id` TypeID and external `slug`)
  and the operational bindings: the BoardGameGeek metadata binding (`bgg_id`),
  `stage`, the independent launch `enabled` flag, and the optional permanent
  engine mapping. It deliberately never persists provider-derived presentation
  fields; those stay runtime-only in `D20.Games.Metadata`.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, TypeID, autogenerate: true, prefix: "game"}

  @slug_format ~r/^[a-z0-9]+(-[a-z0-9]+)*$/
  @slug_max_length 63

  @type id :: TypeID.t()
  @type t :: %__MODULE__{
          id: id(),
          slug: String.t(),
          bgg_id: pos_integer(),
          stage: :planned | :in_development | :released,
          enabled: boolean(),
          engine: D20.Game.engine() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "games" do
    field :slug, :string
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

  @doc """
  Builds the changeset that creates a persisted game.

  The operator-assigned external slug and the BGG binding are required at
  creation; the database autogenerates the environment-local `game` TypeID.
  """
  @spec create_changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t()
  def create_changeset(game_or_changeset, attrs) do
    game_or_changeset
    |> cast(attrs, [:slug, :bgg_id, :stage, :enabled, :engine])
    |> validate_required([:slug, :bgg_id, :stage, :enabled])
    |> validate_slug()
    |> shared_validations()
  end

  @doc """
  Builds the ordinary update changeset for an existing persisted game.

  The slug is intentionally not cast: it is the immutable external identity of
  the row and a rename is a separately coordinated data and infrastructure
  migration, not routine catalog editing.
  """
  @spec changeset(t() | Ecto.Changeset.t(t()), map()) :: Ecto.Changeset.t()
  def changeset(game_or_changeset, attrs) do
    game_or_changeset
    |> cast(attrs, [:bgg_id, :stage, :enabled, :engine])
    |> validate_required([:bgg_id, :stage, :enabled])
    |> shared_validations()
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_length(:slug, max: @slug_max_length)
    |> validate_format(:slug, @slug_format)
    |> unique_constraint(:slug, name: :games_slug_index)
  end

  defp shared_validations(changeset) do
    changeset
    |> validate_number(:bgg_id, greater_than: 0)
    |> validate_inclusion(:stage, [:planned, :in_development, :released])
    |> validate_engine_for_stage()
    |> unique_constraint(:bgg_id, name: :games_bgg_id_index)
    |> check_constraint(:bgg_id, name: :games_bgg_id_positive)
    |> check_constraint(:stage, name: :games_stage_domain)
    |> check_constraint(:engine, name: :games_engine_domain)
    |> check_constraint(:stage, name: :games_launch_stage_requires_engine)
    |> check_constraint(:slug, name: :games_slug_format)
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
