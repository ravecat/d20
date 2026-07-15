defmodule D20.KoalaRescueClub.Ruleset.Dharug do
  @moduledoc """
  Static Koala Rescue Club Dharug map ruleset data.
  """

  @behaviour D20.KoalaRescueClub.Ruleset.Sheet

  alias D20.KoalaRescueClub.Ruleset.Sheet

  @solo_ratings [
    junior_club_member: 0..12,
    club_secretary: 13..16,
    club_treasurer: 17..20,
    vice_president: 21..24,
    president: 25..43
  ]

  @areas [
    a: %{access: true, rows: [0..3, 0..3, 0..3, 1..3]},
    b: %{rows: [0..3, 0..3, 1..3, 2..3]},
    c: %{rows: [0..3, 0..3, 2..3]},
    d: %{rows: [0..3, 0..3, 1..3]},
    e: %{rows: [0..3, 0..3, 0..3]}
  ]

  @bonuses %{
    a: [
      %{axis: :row, index: 0, bonus: %{kind: :skybridge, to: :b}},
      %{axis: :row, index: 1, bonus: %{kind: :tree}},
      %{axis: :row, index: 2, bonus: %{kind: :koala}},
      %{axis: :row, index: 3, bonus: %{kind: :skybridge, to: :d}},
      %{axis: :column, index: 0, bonus: %{kind: :tree}},
      %{axis: :column, index: 1, bonus: %{kind: :koala}},
      %{axis: :column, index: 2, bonus: %{kind: :hospital}},
      %{axis: :column, index: 3, bonus: %{kind: :volunteer}}
    ],
    b: [
      %{axis: :row, index: 0, bonus: %{kind: :koala}},
      %{axis: :row, index: 1, bonus: %{kind: :skybridge, to: :c}},
      %{axis: :row, index: 2, bonus: %{kind: :tree}},
      %{axis: :row, index: 3, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 0, bonus: %{kind: :tree}},
      %{axis: :column, index: 1, bonus: %{kind: :tree}},
      %{axis: :column, index: 2, bonus: %{kind: :hospital}},
      %{axis: :column, index: 3, bonus: %{kind: :tree}}
    ],
    c: [
      %{axis: :row, index: 0, bonus: %{kind: :koala}},
      %{axis: :row, index: 1, bonus: %{kind: :koala}},
      %{axis: :row, index: 2, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 0, bonus: %{kind: :hospital}},
      %{axis: :column, index: 1, bonus: %{kind: :tree}},
      %{axis: :column, index: 2, bonus: %{kind: :koala}},
      %{axis: :column, index: 3, bonus: %{kind: :tree}}
    ],
    d: [
      %{axis: :row, index: 0, bonus: %{kind: :hospital}},
      %{axis: :row, index: 1, bonus: %{kind: :skybridge, to: :e}},
      %{axis: :row, index: 2, bonus: %{kind: :hospital}},
      %{axis: :column, index: 0, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 1, bonus: %{kind: :tree}},
      %{axis: :column, index: 2, bonus: %{kind: :tree}},
      %{axis: :column, index: 3, bonus: %{kind: :volunteer}}
    ],
    e: [
      %{axis: :row, index: 0, bonus: %{kind: :hospital}},
      %{axis: :row, index: 1, bonus: %{kind: :koala}},
      %{axis: :row, index: 2, bonus: %{kind: :hospital}},
      %{axis: :column, index: 0, bonus: %{kind: :tree}},
      %{axis: :column, index: 1, bonus: %{kind: :hospital}},
      %{axis: :column, index: 2, bonus: %{kind: :hospital}},
      %{axis: :column, index: 3, bonus: %{kind: :tree}}
    ]
  }

  @hospitals %{
    hospital_3: %{size: 4, score: 3},
    hospital_2: %{size: 3, score: 2},
    hospital_1_left: %{size: 2, score: 1},
    hospital_1_right: %{size: 2, score: 1}
  }

  @skybridges [%{from: :a, to: :b}, %{from: :a, to: :d}, %{from: :b, to: :c}, %{from: :d, to: :e}]

  @badges %{
    koala_carer: %{
      awards: %{large: 3, small: 2},
      requirement: %{complete: %{area: :a, mark: :koalas}}
    },
    tree_lover: %{
      awards: %{large: 3, small: 2},
      requirement: %{complete: %{area: :c, mark: :trees}}
    },
    bridge_buddy: %{
      awards: %{large: 3, small: 2},
      requirement: %{count: %{field: :skybridges, at_least: 4}}
    }
  }

  @impl true
  @spec init() :: Sheet.source()
  def init do
    %{
      volunteers: 1,
      solo_ratings: @solo_ratings,
      areas: @areas,
      bonuses: @bonuses,
      hospitals: @hospitals,
      skybridges: @skybridges,
      badges: @badges
    }
  end
end
