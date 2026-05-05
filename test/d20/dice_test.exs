defmodule D20.DiceTest do
  use ExUnit.Case, async: true

  alias D20.Dice

  describe "roll/1" do
    test "rolls a single die alias roll set" do
      assert {:ok, %{sum: sum, d10: values}} = Dice.roll(d10: 2)

      assert length(values) == 2
      assert Enum.all?(values, &(&1 in 1..10))
      assert sum == Enum.sum(values)
    end

    test "rolls heterogeneous keyword roll sets" do
      assert {:ok, %{sum: sum, d6: d6_values, d10: d10_values}} =
               Dice.roll(d6: 3, d10: 2)

      assert length(d6_values) == 3
      assert Enum.all?(d6_values, &(&1 in 1..6))
      assert length(d10_values) == 2
      assert Enum.all?(d10_values, &(&1 in 1..10))
      assert sum == Enum.sum(d6_values) + Enum.sum(d10_values)
    end

    test "rejects invalid roll sets, counts, and dice" do
      assert {:error, :invalid_count} = Dice.roll(d6: 0)
      assert {:error, :invalid_die} = Dice.roll(d1: 1)
      assert {:error, :invalid_set} = Dice.roll(%{d6: 1})
      assert {:error, :invalid_set} = Dice.roll(:d6)
      assert {:error, :invalid_set} = Dice.roll(d6: 1, d6: 2)
      assert {:error, :invalid_set} = Dice.roll([])
      assert {:error, :invalid_set} = Dice.roll([:d6])
    end
  end

  describe "roll!/1" do
    test "returns grouped values for keyword roll sets" do
      assert %{sum: sum, d6: d6_values, d20: d20_values} = Dice.roll!(d6: 1, d20: 1)

      assert hd(d6_values) in 1..6
      assert hd(d20_values) in 1..20
      assert sum == hd(d6_values) + hd(d20_values)
    end

    test "raises for invalid input" do
      assert_raise ArgumentError, fn -> Dice.roll!(d6: 0) end
    end
  end
end
