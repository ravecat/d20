defmodule D20.KoalaRescueClub.Ruleset.Yugambeh do
  @moduledoc """
  Static Koala Rescue Club Yugambeh map ruleset data.
  """

  @behaviour D20.KoalaRescueClub.Ruleset.Sheet

  alias D20.KoalaRescueClub.Ruleset.Sheet

  @solo_ratings [
    junior_club_member: 0..15,
    club_secretary: 16..19,
    club_treasurer: 20..23,
    vice_president: 24..27,
    president: 28..55
  ]

  @areas [
    a: %{access: true, rows: [0..3, 0..3, 1..3, 2..3]},
    b: %{rows: [0..3, 0..3]},
    c: %{rows: [0..3, 0..3]},
    d: %{rows: [0..3, 0..3]},
    e: %{rows: [0..3, 0..3, 1..3]},
    f: %{rows: [0..5]},
    g: %{rows: [0..3, 0..3]}
  ]

  @bonuses %{
    a: [
      %{axis: :row, index: 0, bonus: %{kind: :skybridge, to: :b}},
      %{axis: :row, index: 1, bonus: %{kind: :tree}},
      %{axis: :row, index: 2, bonus: %{kind: :skybridge, to: :c}},
      %{axis: :row, index: 3, bonus: %{kind: :skybridge, to: :d}},
      %{axis: :column, index: 0, bonus: %{kind: :tree}},
      %{axis: :column, index: 1, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 2, bonus: %{kind: :hospital}},
      %{axis: :column, index: 3, bonus: %{kind: :koala}}
    ],
    b: [
      %{axis: :row, index: 0, bonus: %{kind: :koala}},
      %{axis: :row, index: 1, bonus: %{kind: :skybridge, to: :e}},
      %{axis: :column, index: 0, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 1, bonus: %{kind: :tree}},
      %{axis: :column, index: 2, bonus: %{kind: :tree}},
      %{axis: :column, index: 3, bonus: %{kind: :tree}}
    ],
    c: [
      %{axis: :row, index: 0, bonus: %{kind: :hospital}},
      %{axis: :row, index: 1, bonus: %{kind: :skybridge, to: :f}},
      %{axis: :column, index: 0, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 1, bonus: %{kind: :koala}},
      %{axis: :column, index: 2, bonus: %{kind: :tree}},
      %{axis: :column, index: 3, bonus: %{kind: :tree}}
    ],
    d: [
      %{axis: :row, index: 0, bonus: %{kind: :hospital}},
      %{axis: :row, index: 1, bonus: %{kind: :skybridge, to: :g}},
      %{axis: :column, index: 0, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 1, bonus: %{kind: :tree}},
      %{axis: :column, index: 2, bonus: %{kind: :tree}},
      %{axis: :column, index: 3, bonus: %{kind: :koala}}
    ],
    e: [
      %{axis: :row, index: 0, bonus: %{kind: :hospital}},
      %{axis: :row, index: 1, bonus: %{kind: :hospital}},
      %{axis: :row, index: 2, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 0, bonus: %{kind: :tree}},
      %{axis: :column, index: 1, bonus: %{kind: :hospital}},
      %{axis: :column, index: 2, bonus: %{kind: :tree}},
      %{axis: :column, index: 3, bonus: %{kind: :tree}}
    ],
    f: [],
    g: [
      %{axis: :row, index: 0, bonus: %{kind: :koala}},
      %{axis: :row, index: 1, bonus: %{kind: :hospital}},
      %{axis: :column, index: 0, bonus: %{kind: :volunteer}},
      %{axis: :column, index: 1, bonus: %{kind: :tree}},
      %{axis: :column, index: 2, bonus: %{kind: :koala}},
      %{axis: :column, index: 3, bonus: %{kind: :koala}}
    ]
  }

  @hospitals %{
    hospital_4: %{size: 4, score: 4, penalty: -3},
    hospital_3: %{size: 3, score: 3, penalty: -2},
    hospital_2: %{size: 2, score: 2, penalty: -1}
  }

  @skybridges [
    %{from: :a, to: :b},
    %{from: :a, to: :c},
    %{from: :a, to: :d},
    %{from: :b, to: :e},
    %{from: :c, to: :f},
    %{from: :d, to: :g}
  ]

  @badges %{
    tree_lover: %{
      awards: %{large: 3, small: 2},
      requirement: %{complete: %{area: :b, mark: :trees}}
    },
    koala_carer: %{
      awards: %{large: 3, small: 2},
      requirement: %{complete: %{area: :f, mark: :koalas}}
    },
    people_person: %{
      awards: %{large: 3, small: 2},
      requirement: %{count: %{field: :volunteers, at_least: 6}}
    }
  }

  @impl true
  @spec init() :: Sheet.source()
  def init do
    %{
      volunteers: 0,
      solo_ratings: @solo_ratings,
      areas: @areas,
      bonuses: @bonuses,
      hospitals: @hospitals,
      skybridges: @skybridges,
      badges: @badges
    }
  end
end
