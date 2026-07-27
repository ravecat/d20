defmodule D20.KoalaRescueClub.CommandTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Command, as: KoalaCommand

  describe "validate/1" do
    test "accepts join and roll commands without validating attrs" do
      assert {:ok, %Command{event: "join"}} =
               KoalaCommand.validate(%Command{event: "join", actor_id: "p1"})

      assert {:ok, %Command{event: "roll", actor_id: nil, attrs: %{}}} =
               KoalaCommand.validate(%Command{event: "roll"})

      command = %Command{event: "roll", actor_id: "p1", attrs: %{"ignored" => true}}

      assert {:ok, ^command} = KoalaCommand.validate(command)
    end

    test "accepts start commands without validating attrs" do
      command = %Command{event: "start", actor_id: "p1", attrs: %{"ignored" => true}}

      assert {:ok, ^command} = KoalaCommand.validate(command)
    end

    test "normalizes ordered bonus actions for submit" do
      assert {:ok,
              %Command{
                event: "submit",
                attrs: %{
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
                 event: "submit",
                 actor_id: "p1",
                 attrs: %{
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

    test "normalizes initial and continuing selection edits" do
      assert {:ok,
              %Command{
                event: "select",
                attrs: %{mark: :tree, die_value: 4, target_cell: %{area: :a, row: 1, column: 2}}
              }} =
               KoalaCommand.validate(%Command{
                 event: "select",
                 actor_id: "p1",
                 attrs: %{
                   "mark" => "tree",
                   "die_value" => 4,
                   "target_cell" => %{"area" => "a", "row" => 1, "column" => 2}
                 }
               })

      assert {:ok, %Command{event: "select", attrs: %{target_cell: cell}}} =
               KoalaCommand.validate(%Command{
                 event: "select",
                 actor_id: "p1",
                 attrs: %{"target_cell" => %{"area" => "a", "row" => 1, "column" => 2}}
               })

      assert cell == %{area: :a, row: 1, column: 2}

      assert {:ok, %Command{event: "deselect", attrs: %{target_cell: ^cell}}} =
               KoalaCommand.validate(%Command{
                 event: "deselect",
                 actor_id: "p1",
                 attrs: %{"target_cell" => %{"area" => "a", "row" => 1, "column" => 2}}
               })

      assert {:ok, %Command{event: "reset", attrs: %{}}} =
               KoalaCommand.validate(%Command{event: "reset", actor_id: "p1", attrs: nil})
    end

    test "normalizes stored-selection submission to bonus decisions only" do
      assert {:ok, %Command{event: "submit", attrs: %{bonus_actions: []}}} =
               KoalaCommand.validate(%Command{
                 event: "submit",
                 actor_id: "p1",
                 attrs: %{"bonus_actions" => []}
               })

      assert {:ok, %Command{attrs: %{bonus_actions: []}}} =
               KoalaCommand.validate(%Command{
                 event: "submit",
                 actor_id: "p1",
                 attrs: %{"ignored_selection" => true, "bonus_actions" => []}
               })

      assert {:error, %Ecto.Changeset{errors: errors}} =
               KoalaCommand.validate(%Command{event: "submit", actor_id: "p1", attrs: %{}})

      assert {:bonus_actions, {"can't be blank", []}} in errors

      assert {:error, :unknown_command} =
               KoalaCommand.validate(%Command{
                 event: "submit_turn_selection",
                 actor_id: "p1",
                 attrs: %{"bonus_actions" => []}
               })
    end

    test "rejects malformed selection edits and removed projection commands" do
      assert {:error, %Ecto.Changeset{}} =
               KoalaCommand.validate(%Command{
                 event: "select",
                 actor_id: "p1",
                 attrs: %{
                   "mark" => "tree",
                   "target_cell" => %{"area" => "a", "row" => 1, "column" => 2}
                 }
               })

      assert {:error, %Ecto.Changeset{errors: errors}} =
               KoalaCommand.validate(%Command{
                 event: "select",
                 actor_id: "p1",
                 attrs: %{
                   "mark" => "tree",
                   "die_value" => 4,
                   "volunteers_used" => 1,
                   "target_cell" => %{"area" => "a", "row" => 1, "column" => 2}
                 }
               })

      assert {:volunteers_used, {"is not accepted", []}} in errors

      assert {:error, %Ecto.Changeset{}} =
               KoalaCommand.validate(%Command{
                 event: "deselect",
                 actor_id: "p1",
                 attrs: %{"target_cell" => %{"area" => "missing", "row" => 0, "column" => 0}}
               })

      assert {:error, %Ecto.Changeset{}} =
               KoalaCommand.validate(%Command{
                 event: "reset",
                 actor_id: "p1",
                 attrs: %{"target_cell" => %{}}
               })

      assert {:error, :unknown_command} =
               KoalaCommand.validate(%Command{
                 event: "project_turn_selection",
                 actor_id: "p1",
                 attrs: %{}
               })
    end

    test "rejects every obsolete primary command" do
      for event <- ~w(plant_trees rehome_koalas circle_tree circle_koala) do
        assert {:error, :unknown_command} =
                 KoalaCommand.validate(%Command{event: event, actor_id: "p1", attrs: %{}})
      end
    end

    test "rejects unknown commands and malformed bonus payloads" do
      assert {:error, :unknown_command} =
               KoalaCommand.validate(%Command{event: "missing", actor_id: "p1"})

      assert {:error, %Ecto.Changeset{action: :turn_selection} = changeset} =
               KoalaCommand.validate(%Command{
                 event: "submit",
                 actor_id: "p1",
                 attrs: %{
                   "bonus_actions" => [
                     %{
                       "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
                       "action" => %{"kind" => "bad"}
                     }
                   ]
                 }
               })

      assert Keyword.has_key?(changeset.errors, :attrs)
    end
  end
end
