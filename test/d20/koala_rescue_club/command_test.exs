defmodule D20.KoalaRescueClub.CommandTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Command, as: KoalaCommand

  describe "validate/1" do
    test "accepts join and payload-free roll commands" do
      assert {:ok, %Command{event: "join"}} =
               KoalaCommand.validate(%Command{event: "join", actor_id: "p1"})

      assert {:ok, %Command{event: "roll", actor_id: nil, attrs: %{}}} =
               KoalaCommand.validate(%Command{event: "roll"})
    end

    test "accepts payload-free start commands" do
      assert {:ok, %Command{attrs: %{}}} =
               KoalaCommand.validate(%Command{event: "start", actor_id: "p1", attrs: %{}})
    end

    test "normalizes turn action payload" do
      assert {:ok,
              %Command{
                event: "circle_tree",
                attrs: %{
                  die_value: 1,
                  volunteers_used: 0,
                  target_cell: %{area: :a, row: 0, column: 0},
                  bonus_actions: [
                    %{bonus: %{area: :a, axis: :row, index: 0}, action: %{kind: :volunteer}},
                    %{
                      bonus: %{area: :a, axis: :column, index: 2},
                      action: %{kind: :hospital, hospital_id: :hospital_2}
                    }
                  ]
                }
              }} =
               KoalaCommand.validate(%Command{
                 event: "circle_tree",
                 actor_id: "p1",
                 attrs: %{
                   "die_value" => 1,
                   "volunteers_used" => 0,
                   "target_cell" => %{"area" => "a", "row" => 0, "column" => 0},
                   "bonus_actions" => [
                     %{
                       "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
                       "action" => %{"kind" => "volunteer"}
                     },
                     %{
                       "bonus" => %{"area" => "a", "axis" => "column", "index" => 2},
                       "action" => %{"kind" => "hospital", "hospital_id" => "hospital_2"}
                     }
                   ]
                 }
               })
    end

    test "rejects unknown commands and malformed payloads" do
      assert {:error, :unknown_command} =
               KoalaCommand.validate(%Command{event: "missing", actor_id: "p1"})

      assert {:error, :invalid_command} =
               KoalaCommand.validate(%Command{
                 event: "start",
                 actor_id: "p1",
                 attrs: %{"sheet" => "missing"}
               })

      assert {:error, :invalid_command} =
               KoalaCommand.validate(%Command{
                 event: "circle_tree",
                 actor_id: "p1",
                 attrs: %{
                   "die_value" => 1,
                   "volunteers_used" => 0,
                   "target_cell" => %{"area" => "a", "row" => 0, "column" => 0},
                   "bonus_actions" => [
                     %{
                       "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
                       "action" => %{"kind" => "bad"}
                     }
                   ]
                 }
               })
    end
  end
end
