defmodule D20.KoalaRescueClub.RulesetTest do
  use ExUnit.Case, async: true

  alias D20.KoalaRescueClub.Ruleset

  describe "player and turn limits" do
    test "accepts supported player range" do
      assert Ruleset.player_count_range() == 1..99
    end

    test "maps turns to rounds and round-end turns" do
      assert {:ok, 1} = Ruleset.round(1)
      assert {:ok, 1} = Ruleset.round(15)
      assert {:ok, 2} = Ruleset.round(16)
      assert {:ok, 2} = Ruleset.round(30)
      assert {:error, :invalid_turn} = Ruleset.round(31)
      assert Ruleset.round_end_turn?(15)
      refute Ruleset.round_end_turn?(16)
      assert Ruleset.final_turn?(30)
    end
  end

  describe "die shapes and volunteers" do
    test "matches die shapes against sheet cells" do
      map = Ruleset.sheet!(:dharug)

      assert Ruleset.shape_match?(
               map,
               [
                 %{area: :a, row: 0, column: 0},
                 %{area: :a, row: 1, column: 0},
                 %{area: :a, row: 0, column: 1}
               ],
               4
             )

      refute Ruleset.shape_match?(
               map,
               [%{area: :a, row: 0, column: 0}, %{area: :a, row: 0, column: 1}],
               4
             )
    end

    test "reports volunteer adjustment cost" do
      assert {:ok, 2} = Ruleset.volunteers_needed(5, 1)
      assert {:ok, 0} = Ruleset.volunteers_needed(4, 4)
      assert {:error, :invalid_die_value} = Ruleset.volunteers_needed(0, 4)
    end
  end

  describe "sheets" do
    test "returns sheet-specific rule differences" do
      assert [:dharug, :yugambeh] = Ruleset.sheets()

      dharug = Ruleset.sheet!(:dharug)
      assert %Ruleset.Sheet{volunteers: 1} = dharug

      assert map_size(dharug.areas) == 5
      assert Map.has_key?(dharug.areas, :a)

      assert dharug.areas.a == %{access: true, rows: [0..3, 0..3, 0..3, 1..3]}

      assert %{axis: :row, index: 0, bonus: %{kind: :skybridge, to: :b}} in dharug.bonuses.a
      assert %{axis: :column, index: 0, bonus: %{kind: :tree}} in dharug.bonuses.a
      assert length(dharug.skybridges) == 4
      assert %{from: :a, to: :b} in dharug.skybridges
      assert map_size(dharug.badges) == 3
      assert Map.has_key?(dharug.badges, :tree_lover)
      refute Map.has_key?(dharug.badges.tree_lover, :id)

      yugambeh = Ruleset.sheet!(:yugambeh)
      assert %Ruleset.Sheet{volunteers: 0} = yugambeh

      assert map_size(yugambeh.areas) == 7
      assert Map.has_key?(yugambeh.areas, :g)
      assert yugambeh.areas.g == %{access: false, rows: [0..3, 0..3]}
      assert %{axis: :row, index: 0, bonus: %{kind: :koala}} in yugambeh.bonuses.g
      assert length(yugambeh.skybridges) == 6
      assert map_size(yugambeh.badges) == 3
      assert Map.has_key?(yugambeh.badges, :tree_lover)

      assert_raise KeyError, fn -> Ruleset.sheet!(:missing) end
    end

    test "returns solo ratings by sheet and score" do
      dharug = Ruleset.sheet!(:dharug)
      yugambeh = Ruleset.sheet!(:yugambeh)

      assert {:ok, %{rank: :junior_club_member}} = Ruleset.solo_rating(dharug, 12)
      assert {:ok, %{rank: :club_secretary}} = Ruleset.solo_rating(dharug, 13)
      assert {:ok, %{rank: :president, range: 25..43}} = Ruleset.solo_rating(dharug, 25)
      assert {:ok, %{rank: :vice_president}} = Ruleset.solo_rating(yugambeh, 27)
      assert {:ok, %{rank: :president, range: 28..55}} = Ruleset.solo_rating(yugambeh, 28)
      assert {:error, :invalid_score} = Ruleset.solo_rating(yugambeh, -1)
    end

    test "returns bonuses separately from their line cells" do
      dharug = Ruleset.sheet!(:dharug)

      assert %{ref: %{area: :a, axis: :row, index: 0}, bonus: %{kind: :skybridge, to: :b}} in Ruleset.bonuses(
               dharug
             )

      refute Enum.any?(Ruleset.bonuses(dharug), &Map.has_key?(&1, :cells))

      missing_line_ref = %{area: :a, axis: :row, index: 99}
      missing_line_bonus = %{axis: :row, index: 99, bonus: %{kind: :tree}}
      dharug = %{dharug | bonuses: Map.update!(dharug.bonuses, :a, &[missing_line_bonus | &1])}

      assert %{ref: missing_line_ref, bonus: %{kind: :tree}} in Ruleset.bonuses(dharug)
      assert Ruleset.line_cells(dharug, missing_line_ref) == []

      assert Ruleset.line_cells(dharug, %{area: :a, axis: :row, index: 3}) == [
               %{area: :a, row: 3, column: 1},
               %{area: :a, row: 3, column: 2},
               %{area: :a, row: 3, column: 3}
             ]

      assert Ruleset.line_cells(dharug, %{area: :a, axis: :column, index: 0}) == [
               %{area: :a, row: 0, column: 0},
               %{area: :a, row: 1, column: 0},
               %{area: :a, row: 2, column: 0}
             ]
    end

    test "returns areas marked accessible on the player sheet" do
      assert Ruleset.accessible_areas(%{areas: %{a: true, b: true, c: false}}) == [:a, :b]
    end
  end

  describe "scoring helpers" do
    test "scores hospitals by penalty attribute" do
      assert {:ok, 0} = Ruleset.score_hospital(%{filled: 2, size: 3, score: 3})
      assert {:ok, 3} = Ruleset.score_hospital(%{filled: 3, size: 3, score: 3})

      assert {:ok, 0} = Ruleset.score_hospital(%{filled: 0, size: 2, score: 2, penalty: -1})

      assert {:ok, 3} = Ruleset.score_hospital(%{filled: 3, size: 3, score: 3, penalty: -2})

      assert {:ok, -3} = Ruleset.score_hospital(%{filled: 3, size: 4, score: 4, penalty: -3})

      assert {:error, :invalid_hospital} =
               Ruleset.score_hospital(%{filled: -1, size: 3, score: 3})
    end
  end
end
