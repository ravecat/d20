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
    a: %{
      initial_access: true,
      rows: [0..3, 0..3, 0..3, 1..3],
      column_bonuses: [:tree, :koala, :hospital, :volunteer],
      row_bonuses: [{:skybridge, :b}, :tree, :koala, {:skybridge, :d}]
    },
    b: %{
      rows: [0..3, 0..3, 0..2, 2..3],
      column_bonuses: [:tree, :tree, :hospital, :tree],
      row_bonuses: [:koala, {:skybridge, :c}, :tree, :volunteer]
    },
    c: %{
      rows: [0..3, 0..3, 1..2],
      column_bonuses: [:hospital, :tree, :koala, :tree],
      row_bonuses: [:koala, :koala, :volunteer]
    },
    d: %{
      rows: [0..3, 0..3, 1..3],
      column_bonuses: [:volunteer, :tree, :tree, :volunteer],
      row_bonuses: [:hospital, {:skybridge, :e}, :hospital]
    },
    e: %{
      rows: [0..3, 0..3, 0..3],
      column_bonuses: [:tree, :hospital, :hospital, :tree],
      row_bonuses: [:hospital, :koala, :hospital]
    }
  ]

  @hospitals [
    hospital_3: %{size: 4, score: 3},
    hospital_2: %{size: 3, score: 2},
    hospital_1_left: %{size: 2, score: 1},
    hospital_1_right: %{size: 2, score: 1}
  ]

  @skybridges [%{from: :a, to: :b}, %{from: :a, to: :d}, %{from: :b, to: :c}, %{from: :d, to: :e}]

  @badges [
    koala_carer: %{large_points: 3, small_points: 2, requirement: {:complete_koalas, :a}},
    tree_lover: %{large_points: 3, small_points: 2, requirement: {:complete_trees, :c}},
    bridge_buddy: %{large_points: 3, small_points: 2, requirement: {:skybridges_claimed, 4}}
  ]

  @impl true
  @spec init() :: Sheet.init()
  def init do
    %{
      volunteers: 1,
      solo_ratings: @solo_ratings,
      areas: @areas,
      hospitals: @hospitals,
      skybridges: @skybridges,
      badges: @badges
    }
  end
end
