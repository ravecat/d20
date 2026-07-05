defmodule D20.KoalaRescueClub.Ruleset.Sheet do
  @moduledoc """
  Koala Rescue Club sheet contract and geometry builder.
  """

  defstruct [:volunteers, :solo_ratings, :areas, :bonuses, :hospitals, :skybridges, :badges]

  @type t :: %__MODULE__{
          volunteers: non_neg_integer(),
          solo_ratings: keyword(Range.t()),
          areas: %{optional(atom()) => area()},
          bonuses: bonuses(),
          hospitals: hospitals(),
          skybridges: [skybridge()],
          badges: badges()
        }
  @type bonus_value ::
          %{
            required(:kind) => :tree | :koala | :volunteer | :hospital | :skybridge,
            optional(:to) => atom()
          }
  @type bonus :: %{
          required(:axis) => :row | :column,
          required(:index) => non_neg_integer(),
          required(:bonus) => bonus_value()
        }
  @type bonuses :: %{optional(atom()) => [bonus()]}
  @type area :: %{required(:access) => boolean(), required(:rows) => [Range.t()]}
  @type area_definition ::
          {atom(), %{required(:rows) => [Range.t()], optional(:access) => boolean()}}
  @type badges :: %{optional(atom()) => map()}
  @type hospitals :: %{optional(atom()) => map()}
  @type skybridge :: %{required(:from) => atom(), required(:to) => atom()}
  @type source :: %{
          required(:volunteers) => non_neg_integer(),
          required(:solo_ratings) => keyword(Range.t()),
          required(:areas) => [area_definition()],
          required(:bonuses) => bonuses(),
          required(:hospitals) => hospitals(),
          required(:skybridges) => [skybridge()],
          required(:badges) => badges()
        }

  @callback init() :: source()

  @spec from_module(module()) :: t()
  def from_module(module) do
    %{
      volunteers: volunteers,
      solo_ratings: solo_ratings,
      areas: areas,
      bonuses: bonuses,
      hospitals: hospitals,
      skybridges: skybridges,
      badges: badges
    } = module.init()

    %__MODULE__{
      areas: Map.new(areas, &area/1),
      bonuses: bonuses,
      volunteers: volunteers,
      solo_ratings: solo_ratings,
      hospitals: hospitals,
      skybridges: skybridges,
      badges: badges
    }
  end

  defp area({area, spec}) do
    {area, %{access: Map.get(spec, :access, false), rows: spec.rows}}
  end
end
