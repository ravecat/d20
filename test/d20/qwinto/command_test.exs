defmodule D20.Qwinto.CommandTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Command

  describe "build/2" do
    test "builds a join command from raw attrs" do
      assert {:ok, %Command.Join{player_id: "p1"}} = Command.build(:join, %{"player_id" => "p1"})
    end

    test "rejects malformed join commands" do
      assert {:error, changeset} = Command.build(:join, %{})

      refute changeset.valid?
      assert changeset.action == :join
      assert Keyword.has_key?(changeset.errors, :player_id)
    end

    test "builds a start command from raw attrs" do
      assert {:ok, %Command.Start{}} = Command.build(:start, %{})
      assert {:ok, %Command.Start{}} = Command.build(:start, %{"player_id" => "p1"})
    end

    test "builds a roll command from raw attrs" do
      assert {:ok, %Command.Roll{player_id: "p1", colors: [:orange, :purple]}} =
               Command.build(:roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "purple"],
                 "values" => [4, 5]
               })
    end

    test "rejects malformed roll commands" do
      assert {:error, changeset} =
               Command.build(:roll, %{
                 "player_id" => "p1",
                 "colors" => ["orange", "orange"],
                 "values" => [4]
               })

      refute changeset.valid?
      assert changeset.action == :roll
      assert Keyword.has_key?(changeset.errors, :colors)
    end

    test "builds keep, reroll, write, and skip commands from raw attrs" do
      assert {:ok, %Command.Keep{player_id: "p1"}} = Command.build(:keep, %{"player_id" => "p1"})

      assert {:ok, %Command.Reroll{player_id: "p1"}} =
               Command.build(:reroll, %{"player_id" => "p1"})

      assert {:ok, %Command.Write{player_id: "p1", row: :orange, slot: 0}} =
               Command.build(:write, %{"player_id" => "p1", "row" => "orange", "slot" => 0})

      assert {:ok, %Command.Skip{player_id: "p1"}} = Command.build(:skip, %{"player_id" => "p1"})
    end

    test "rejects write slots outside the score-sheet slot range" do
      assert {:error, changeset} =
               Command.build(:write, %{"player_id" => "p1", "row" => "orange", "slot" => 9})

      refute changeset.valid?
      assert changeset.action == :write
      assert Keyword.has_key?(changeset.errors, :slot)
    end
  end
end
