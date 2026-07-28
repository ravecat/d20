defmodule D20.KoalaRescueClub.CommandTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Command, as: KoalaCommand

  describe "validate/1" do
    test "accepts lifecycle commands without validating attrs" do
      for event <- ~w(join start roll) do
        command = %Command{event: event, actor_id: "p1", attrs: %{"ignored" => true}}
        assert {:ok, ^command} = KoalaCommand.validate(command)
      end
    end

    test "normalizes a complete draft candidate" do
      assert {:ok,
              %Command{
                event: "draft",
                attrs: %{
                  mark: :tree,
                  die_value: 4,
                  selected_cells: [%{area: :a, row: 1, column: 2}, %{area: :a, row: 1, column: 3}]
                }
              }} =
               KoalaCommand.validate(%Command{
                 event: "draft",
                 actor_id: "p1",
                 attrs: %{
                   "mark" => "tree",
                   "die_value" => 4,
                   "selected_cells" => [
                     %{"area" => "a", "row" => 1, "column" => 2},
                     %{"area" => "a", "row" => 1, "column" => 3}
                   ]
                 }
               })
    end

    test "normalizes complete submit candidates and ordered bonus actions" do
      assert {:ok,
              %Command{
                event: "submit",
                attrs: %{
                  mark: :koala,
                  die_value: 1,
                  selected_cells: [%{area: :a, row: 0, column: 0}],
                  bonus_actions: [
                    %{bonus: %{area: :a, axis: :row, index: 0}, action: %{kind: :volunteer}},
                    %{
                      bonus: %{area: :a, axis: :column, index: 2},
                      action: %{kind: :hospital, hospital_id: "hospital_2"}
                    }
                  ]
                }
              }} =
               KoalaCommand.validate(%Command{
                 event: "submit",
                 actor_id: "p1",
                 attrs: %{
                   "mark" => "koala",
                   "die_value" => 1,
                   "selected_cells" => [%{"area" => "a", "row" => 0, "column" => 0}],
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

    test "keeps structurally valid hospital ids opaque for ruleset resolution" do
      assert {:ok,
              %Command{
                attrs: %{
                  bonus_actions: [
                    %{action: %{kind: :hospital, hospital_id: "sheet_defined_hospital"}}
                  ]
                }
              }} =
               KoalaCommand.validate(
                 submit_command([
                   %{
                     "bonus" => %{"area" => "a", "axis" => "column", "index" => 2},
                     "action" => %{
                       "kind" => "hospital",
                       "hospital_id" => "sheet_defined_hospital"
                     }
                   }
                 ])
               )
    end

    test "rejects missing, empty, malformed, and duplicate candidates with concrete actions" do
      for {event, attrs} <- [
            {"draft", %{}},
            {"draft", candidate([])},
            {"draft", candidate([cell("missing", 0, 0)])},
            {"draft", candidate([cell("a", 0, 0), cell("a", 0, 0)])},
            {"submit", candidate([cell("a", 0, 0)])}
          ] do
        assert {:error, %Ecto.Changeset{action: action}} =
                 KoalaCommand.validate(%Command{event: event, actor_id: "p1", attrs: attrs})

        assert action == String.to_existing_atom(event)
      end
    end

    test "rejects malformed bonuses as submit" do
      command =
        submit_command([
          %{
            "bonus" => %{"area" => "a", "axis" => "row", "index" => 0},
            "action" => %{"kind" => "bad"}
          }
        ])

      assert {:error, %Ecto.Changeset{action: :submit, errors: errors}} =
               KoalaCommand.validate(command)

      assert Keyword.has_key?(errors, :attrs)
    end

    test "rejects malformed hospital identifiers" do
      for hospital_id <- ["", :hospital_2, nil] do
        command =
          submit_command([
            %{
              "bonus" => %{"area" => "a", "axis" => "column", "index" => 2},
              "action" => %{"kind" => "hospital", "hospital_id" => hospital_id}
            }
          ])

        assert {:error, %Ecto.Changeset{action: :submit}} = KoalaCommand.validate(command)
      end
    end

    test "rejects staged, direct, and unknown commands" do
      for event <-
            ~w(select deselect reset plant_trees rehome_koalas circle_tree circle_koala missing) do
        assert {:error, :unknown_command} =
                 KoalaCommand.validate(%Command{event: event, actor_id: "p1", attrs: %{}})
      end
    end
  end

  defp submit_command(bonus_actions) do
    %Command{
      event: "submit",
      actor_id: "p1",
      attrs: candidate([cell("a", 0, 0)]) |> Map.put("bonus_actions", bonus_actions)
    }
  end

  defp candidate(cells) do
    %{"mark" => "tree", "die_value" => 1, "selected_cells" => cells}
  end

  defp cell(area, row, column), do: %{"area" => area, "row" => row, "column" => column}
end
