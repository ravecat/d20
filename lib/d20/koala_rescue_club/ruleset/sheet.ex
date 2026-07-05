defmodule D20.KoalaRescueClub.Ruleset.Sheet do
  @moduledoc """
  Koala Rescue Club sheet contract and geometry builder.
  """

  defstruct [:volunteers, :solo_ratings, :areas, :bonuses, :hospitals, :skybridges, :badges]

  @type t :: %__MODULE__{
          volunteers: non_neg_integer(),
          solo_ratings: keyword(Range.t()),
          areas: %{optional(atom()) => area()},
          bonuses: %{optional(atom()) => [bonus()]},
          hospitals: %{optional(atom()) => map()},
          skybridges: [skybridge()],
          badges: %{optional(atom()) => map()}
        }
  @type bonus_value :: :tree | :koala | :volunteer | :hospital | {:skybridge, atom()}
  @type bonus :: %{
          required(:axis) => :row | :column,
          required(:index) => non_neg_integer(),
          required(:bonus) => bonus_value()
        }
  @type area :: %{required(:access) => boolean(), required(:rows) => [Range.t()]}
  @type area_definition ::
          {atom(),
           %{
             required(:rows) => [Range.t()],
             required(:row_bonuses) => [bonus_value() | nil],
             required(:column_bonuses) => [bonus_value() | nil],
             optional(:access) => boolean()
           }}
  @type badge :: {atom(), map()}
  @type hospital :: {atom(), map()}
  @type skybridge :: %{required(:from) => atom(), required(:to) => atom()}
  @type source :: %{
          required(:volunteers) => non_neg_integer(),
          required(:solo_ratings) => keyword(Range.t()),
          required(:areas) => [area_definition()],
          required(:hospitals) => [hospital()],
          required(:skybridges) => [skybridge()],
          required(:badges) => [badge()]
        }

  @callback init() :: source()

  @spec from_module(module()) :: t()
  def from_module(module) do
    %{
      volunteers: volunteers,
      solo_ratings: solo_ratings,
      areas: areas,
      hospitals: hospitals,
      skybridges: skybridges,
      badges: badges
    } = module.init()

    %__MODULE__{
      areas: Map.new(areas, &area/1),
      bonuses: bonuses(areas),
      volunteers: volunteers,
      solo_ratings: solo_ratings,
      hospitals: Map.new(hospitals),
      skybridges: skybridges,
      badges: Map.new(badges)
    }
  end

  @spec cell_key(atom(), integer(), integer()) :: map()
  def cell_key(area, column, row), do: %{area: area, row: row, column: column}

  defp area({area, spec}) do
    {area, %{access: Map.get(spec, :access, false), rows: spec.rows}}
  end

  defp bonuses(areas) do
    Map.new(areas, fn {area, spec} ->
      bonuses = line_bonuses(:row, spec.row_bonuses) ++ line_bonuses(:column, spec.column_bonuses)

      {area, bonuses}
    end)
  end

  defp line_bonuses(axis, bonuses) do
    bonuses
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {nil, _index} -> []
      {bonus, index} -> [%{axis: axis, index: index, bonus: bonus}]
    end)
  end
end
