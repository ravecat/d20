defmodule D20.KoalaRescueClub.RulesetTest do
  use ExUnit.Case, async: true

  alias D20.KoalaRescueClub.Ruleset

  describe "player and turn limits" do
    test "accepts one or more players" do
      assert Ruleset.min_players() == 1
      assert Ruleset.valid_player_count?(1)
      assert Ruleset.valid_player_count?(100)
      refute Ruleset.valid_player_count?(0)
      refute Ruleset.valid_player_count?("1")
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
      assert Ruleset.shape_transforms() == [:rotate, :flip]
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

  describe "actions and bonuses" do
    test "exposes turn, fallback, and bonus action kinds" do
      assert Ruleset.actions() == [:plant_trees, :rehome_koalas]
      assert Ruleset.single_circle_actions() == [:circle_tree, :circle_koala]
      assert Ruleset.bonus_actions() == [:tree, :koala, :volunteer, :hospital, :skybridge]
      assert Ruleset.bonus_action?(:skybridge)
      refute Ruleset.bonus_action?(:plant_trees)

      assert Ruleset.merit_badge_policy() == %{
               multiplayer: :first_players_large_others_small,
               solo: :round_1_large_round_2_small
             }

      assert Ruleset.tie_breakers() == [:most_koalas]
    end
  end

  describe "maps" do
    test "returns map-specific rule differences" do
      assert [:map_1, :map_2] = Ruleset.map_slugs()

      assert {:ok,
              %{
                slug: :map_1,
                title: "Map 1",
                initial_volunteers: 1,
                hospital_scoring: :completed_only,
                sheet_geometry: :not_encoded
              }} = Ruleset.map(:map_1)

      assert {:ok,
              %{
                slug: :map_2,
                title: "Map 2 - Yugambeh",
                initial_volunteers: 0,
                hospital_scoring: :completed_positive_started_incomplete_negative,
                sheet_geometry: :not_encoded
              }} = Ruleset.map("map_2")

      assert {:error, :unknown_map} = Ruleset.map("missing")
    end

    test "returns solo ratings by map and score" do
      assert {:ok, %{rank: :junior_club_member}} = Ruleset.solo_rating(:map_1, 12)
      assert {:ok, %{rank: :club_secretary}} = Ruleset.solo_rating(:map_1, 13)
      assert {:ok, %{rank: :president}} = Ruleset.solo_rating(:map_1, 25)
      assert {:ok, %{rank: :vice_president}} = Ruleset.solo_rating(:map_2, 27)
      assert {:ok, %{rank: :president}} = Ruleset.solo_rating(:map_2, 28)
      assert {:error, :invalid_score} = Ruleset.solo_rating(:map_2, -1)
      assert {:error, :unknown_map} = Ruleset.solo_rating(:missing, 10)
    end
  end

  describe "scoring helpers" do
    test "scores complete tree and koala areas" do
      assert Ruleset.score_area(%{trees_complete?: false, koalas_complete?: false}) == 0
      assert Ruleset.score_area(%{trees_complete?: true, koalas_complete?: false}) == 1
      assert Ruleset.score_area(%{trees_complete?: true, koalas_complete?: true}) == 2
    end

    test "scores hospitals by map policy" do
      assert {:ok, 0} = Ruleset.score_hospital(:map_1, %{filled: 2, size: 3, score: 3})
      assert {:ok, 3} = Ruleset.score_hospital(:map_1, %{filled: 3, size: 3, score: 3})

      assert {:ok, 0} =
               Ruleset.score_hospital(:map_2, %{filled: 0, size: 2, score: 2, penalty: -1})

      assert {:ok, 3} =
               Ruleset.score_hospital(:map_2, %{filled: 3, size: 3, score: 3, penalty: -2})

      assert {:ok, -3} =
               Ruleset.score_hospital(:map_2, %{filled: 3, size: 4, score: 4, penalty: -3})

      assert {:error, :invalid_hospital} =
               Ruleset.score_hospital(:map_1, %{filled: -1, size: 3, score: 3})
    end
  end
end
