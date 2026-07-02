defmodule D20.KoalaRescueClub.RulesetTest do
  use ExUnit.Case, async: true

  alias D20.KoalaRescueClub.Ruleset

  describe "player and turn limits" do
    test "accepts supported player range" do
      assert Ruleset.player_count_range() == 1..99
    end

    test "maps turns to rounds and scoring turns" do
      assert Ruleset.turn_range() == 1..30
      assert Ruleset.turns_per_round() == 15
      assert Ruleset.scoring_turns() == [15, 30]
      assert {:ok, 1} = Ruleset.round_for_turn(1)
      assert {:ok, 1} = Ruleset.round_for_turn(15)
      assert {:ok, 2} = Ruleset.round_for_turn(16)
      assert {:ok, 2} = Ruleset.round_for_turn(30)
      assert {:error, :invalid_turn} = Ruleset.round_for_turn(31)
      assert Ruleset.scoring_turn?(15)
      refute Ruleset.scoring_turn?(16)
      assert Ruleset.final_turn?(30)
    end
  end

  describe "die shapes and volunteers" do
    test "returns canonical die shape offsets" do
      assert Ruleset.die_value_range() == 1..6
      assert Ruleset.valid_die_value?(6)
      refute Ruleset.valid_die_value?(7)
      assert {:ok, [{0, 0}, {1, 0}, {0, 1}]} = Ruleset.shape_for(4)
      assert {:error, :invalid_die_value} = Ruleset.shape_for(0)
      assert Ruleset.shape_offsets(6) == [{0, 0}, {1, 0}, {2, 0}, {1, 1}]
      assert Ruleset.shape_size(5) == 4
    end

    test "wraps die adjustments and reports volunteer reachability" do
      assert {:ok, 1} = Ruleset.adjust_die(6, 1)
      assert {:ok, 6} = Ruleset.adjust_die(1, -1)
      assert {:ok, 1} = Ruleset.adjust_die(5, 2)
      assert {:error, :invalid_die_adjustment} = Ruleset.adjust_die(7, 1)
      assert {:ok, 2} = Ruleset.volunteers_needed(5, 1)
      assert {:ok, 0} = Ruleset.volunteers_needed(4, 4)
      assert {:error, :invalid_die_value} = Ruleset.volunteers_needed(0, 4)
      assert {:ok, [5]} = Ruleset.reachable_die_values(5, 0)
      assert {:ok, [1, 3, 4, 5, 6]} = Ruleset.reachable_die_values(5, 2)
      assert {:error, :invalid_volunteers} = Ruleset.reachable_die_values(5, -1)
    end
  end

  describe "scoring metadata" do
    test "exposes badge policy" do
      assert Ruleset.badge_policy() == %{
               multiplayer: :first_players_large_others_small,
               solo: :round_1_large_round_2_small
             }
    end
  end

  describe "sheets" do
    test "returns sheet-specific rule differences" do
      assert [:dharug, :yugambeh] = Ruleset.sheets()

      assert {:ok, %Ruleset.Sheet{volunteers: 1} = dharug} = Ruleset.sheet(:dharug)

      assert Ruleset.valid_geometry?(dharug)
      assert map_size(dharug.areas) == 5
      assert Map.has_key?(dharug.areas, :a)
      assert dharug.cells["a:0:0"].area_id == :a
      assert map_size(dharug.skybridges) == 4
      assert map_size(dharug.badges) == 3
      assert Map.has_key?(dharug.badges, :tree_lover)

      assert {:ok, %Ruleset.Sheet{volunteers: 0} = yugambeh} = Ruleset.sheet("yugambeh")

      assert Ruleset.valid_geometry?(yugambeh)
      assert map_size(yugambeh.areas) == 7
      assert Map.has_key?(yugambeh.areas, :g)
      assert yugambeh.cells["g:0:0"].area_id == :g
      assert map_size(yugambeh.skybridges) == 6
      assert map_size(yugambeh.badges) == 3
      assert Map.has_key?(yugambeh.badges, :tree_lover)

      assert {:error, :unknown_sheet} = Ruleset.sheet("missing")
    end

    test "returns solo ratings by sheet and score" do
      assert {:ok, %{rank: :junior_club_member}} = Ruleset.solo_rating(:dharug, 12)
      assert {:ok, %{rank: :club_secretary}} = Ruleset.solo_rating(:dharug, 13)
      assert {:ok, %{rank: :president, range: 25..43}} = Ruleset.solo_rating(:dharug, 25)
      assert {:ok, %{rank: :vice_president}} = Ruleset.solo_rating(:yugambeh, 27)
      assert {:ok, %{rank: :president, range: 28..55}} = Ruleset.solo_rating(:yugambeh, 28)
      assert {:error, :invalid_score} = Ruleset.solo_rating(:yugambeh, -1)
      assert {:error, :unknown_sheet} = Ruleset.solo_rating(:missing, 10)
    end
  end

  describe "scoring helpers" do
    test "scores complete tree and koala areas" do
      assert Ruleset.score_area(%{trees_complete?: false, koalas_complete?: false}) == 0
      assert Ruleset.score_area(%{trees_complete?: true, koalas_complete?: false}) == 1
      assert Ruleset.score_area(%{trees_complete?: true, koalas_complete?: true}) == 2
    end

    test "scores hospitals by penalty attribute" do
      assert {:ok, 0} = Ruleset.score_hospital(:dharug, %{filled: 2, size: 3, score: 3})
      assert {:ok, 3} = Ruleset.score_hospital(:dharug, %{filled: 3, size: 3, score: 3})

      assert {:ok, 0} =
               Ruleset.score_hospital(:yugambeh, %{filled: 0, size: 2, score: 2, penalty: -1})

      assert {:ok, 3} =
               Ruleset.score_hospital(:yugambeh, %{filled: 3, size: 3, score: 3, penalty: -2})

      assert {:ok, -3} =
               Ruleset.score_hospital(:yugambeh, %{filled: 3, size: 4, score: 4, penalty: -3})

      assert {:error, :invalid_hospital} =
               Ruleset.score_hospital(:dharug, %{filled: -1, size: 3, score: 3})
    end
  end
end
