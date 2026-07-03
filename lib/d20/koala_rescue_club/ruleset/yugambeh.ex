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
    a: %{
      access: true,
      rows: [0..3, 0..3, 1..3, 2..3],
      column_bonuses: [:tree, :volunteer, :hospital, :koala],
      row_bonuses: [{:skybridge, :b}, :tree, {:skybridge, :c}, {:skybridge, :d}]
    },
    b: %{
      rows: [0..3, 0..3],
      column_bonuses: [:volunteer, :tree, :tree, :tree],
      row_bonuses: [:koala, {:skybridge, :e}]
    },
    c: %{
      rows: [0..3, 0..3],
      column_bonuses: [:volunteer, :koala, :tree, :tree],
      row_bonuses: [:hospital, {:skybridge, :f}]
    },
    d: %{
      rows: [0..3, 0..3],
      column_bonuses: [:volunteer, :tree, :tree, :koala],
      row_bonuses: [:hospital, {:skybridge, :g}]
    },
    e: %{
      rows: [0..3, 0..3, 1..3],
      column_bonuses: [:tree, :hospital, :tree, :tree],
      row_bonuses: [:hospital, :hospital, :volunteer]
    },
    f: %{rows: [0..5], column_bonuses: [], row_bonuses: []},
    g: %{
      rows: [0..3, 0..3],
      column_bonuses: [:volunteer, :tree, :koala, :koala],
      row_bonuses: [:koala, :hospital]
    }
  ]

  @hospitals [
    hospital_4: %{size: 4, score: 4, penalty: -3},
    hospital_3: %{size: 3, score: 3, penalty: -2},
    hospital_2: %{size: 2, score: 2, penalty: -1}
  ]

  @skybridges [
    %{from: :a, to: :b},
    %{from: :a, to: :c},
    %{from: :a, to: :d},
    %{from: :b, to: :e},
    %{from: :c, to: :f},
    %{from: :d, to: :g}
  ]

  @badges [
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
  ]

  @impl true
  @spec init() :: Sheet.init()
  def init do
    %{
      volunteers: 0,
      solo_ratings: @solo_ratings,
      areas: @areas,
      hospitals: @hospitals,
      skybridges: @skybridges,
      badges: @badges
    }
  end
end
