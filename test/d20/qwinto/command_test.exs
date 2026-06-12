defmodule D20.Qwinto.CommandTest do
  use ExUnit.Case, async: true

  alias D20.Qwinto.Command

  describe "validate/1" do
    test "passes payload-less commands through unchanged" do
      join = command("join", "p1", %{online_at: 10})
      start = command("start", "p1")
      reroll = command("reroll", "p1")
      pass = command("pass", "p1")
      penalize = command("penalize", "p1")

      assert {:ok, ^join} = Command.validate(join)
      assert {:ok, ^start} = Command.validate(start)
      assert {:ok, ^reroll} = Command.validate(reroll)
      assert {:ok, ^pass} = Command.validate(pass)
      assert {:ok, ^penalize} = Command.validate(penalize)
    end

    test "validates and normalizes roll attrs" do
      assert {:ok,
              %D20.Command{event: "roll", actor_id: "p1", attrs: %{colors: [:orange, :purple]}}} =
               Command.validate(command("roll", "p1", %{"colors" => ["orange", "purple"]}))
    end

    test "rejects malformed roll attrs" do
      assert {:error, changeset} =
               Command.validate(command("roll", "p1", %{"colors" => ["orange", "orange"]}))

      refute changeset.valid?
      assert changeset.action == :roll
      assert Keyword.has_key?(changeset.errors, :colors)
    end

    test "validates and normalizes write attrs" do
      assert {:ok, %D20.Command{event: "write", actor_id: "p1", attrs: %{row: :orange, slot: 0}}} =
               Command.validate(command("write", "p1", %{"row" => "orange", "slot" => 0}))
    end

    test "rejects write slots outside the score-sheet slot range" do
      assert {:error, changeset} =
               Command.validate(command("write", "p1", %{"row" => "orange", "slot" => 9}))

      refute changeset.valid?
      assert changeset.action == :write
      assert Keyword.has_key?(changeset.errors, :slot)
    end

    test "rejects unknown commands" do
      assert {:error, :unknown_command} = Command.validate(command("unknown", "p1"))
    end
  end

  defp command(event, actor_id, attrs \\ %{}) do
    %D20.Command{event: event, actor_id: actor_id, attrs: attrs}
  end
end
