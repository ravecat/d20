defmodule D20.Qwinto.RulesetTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Ruleset

  describe "valid_slot?/2" do
    test "accepts existing slots in known rows" do
      assert Ruleset.valid_slot?(:orange, 0)
      assert Ruleset.valid_slot?(:yellow, 8)
      assert Ruleset.valid_slot?(:purple, 4)
    end

    test "rejects slots outside the score-sheet geometry" do
      refute Ruleset.valid_slot?(:orange, -1)
      refute Ruleset.valid_slot?(:yellow, 9)
      refute Ruleset.valid_slot?(:purple, "0")
      refute Ruleset.valid_slot?(:blue, 0)
      refute Ruleset.valid_slot?("orange", 0)
    end
  end
end
