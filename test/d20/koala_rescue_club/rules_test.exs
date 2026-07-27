defmodule D20.KoalaRescueClub.RulesTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset

  describe "caller turn analysis" do
    test "returns mark-keyed initial targets for reachable adjusted values" do
      game = submit_game(1)
      options = Rules.turn_options(game, "p1")

      assert Map.keys(options) |> Enum.sort() == Enum.to_list(1..6)

      assert %{volunteer_cost: 0, marks: %{tree: %{available_cells: tree_cells}} = marks} =
               options[1]

      assert tree_cells != []
      refute Map.has_key?(marks, :koala)

      target = cell(:a, 0, 0)
      game = put_in(game.players["p1"].sheet.trees, [target])

      assert %{marks: %{koala: %{available_cells: [^target]}}} = Rules.turn_options(game, "p1")[1]
    end

    test "classifies one cell as submit-ready while preserving legal continuations" do
      game = submit_game(1)
      target = cell(:a, 0, 0)

      assert {:ok, game} =
               dispatch(game, "select", "p1", %{
                 "mark" => "tree",
                 "die_value" => 1,
                 "target_cell" => target
               })

      assert %{
               mark: :tree,
               value: 1,
               volunteers: 0,
               cells: [^target],
               required_cells: 2,
               available_cells: available_cells,
               submit_ready: true,
               resolution: :single,
               bonus_options: []
             } = details = Rules.selection_details(game, "p1")

      assert available_cells != []
      refute Map.has_key?(details, :die_value)
      refute Map.has_key?(details, :volunteers_used)
      refute Map.has_key?(details, :selected_cells)
    end

    test "classifies an isolated one-cell fallback as submit-ready without continuations" do
      game = submit_game(1)
      rulesheet = Ruleset.sheet!(:dharug)
      target = cell(:a, 0, 0)
      occupied = rulesheet |> Ruleset.area_cells(:a) |> List.delete(target)
      game = put_in(game.players["p1"].sheet.trees, occupied)

      assert {:ok, game} =
               dispatch(game, "select", "p1", %{
                 "mark" => "tree",
                 "die_value" => 1,
                 "target_cell" => target
               })

      assert %{submit_ready: true, resolution: :single, available_cells: []} =
               Rules.selection_details(game, "p1")
    end

    test "classifies shape prefixes and complete shapes" do
      game = submit_game(3)
      first = cell(:a, 0, 0)
      second = cell(:a, 0, 1)
      third = cell(:a, 0, 2)

      assert {:ok, game} =
               dispatch(game, "select", "p1", %{
                 "mark" => "tree",
                 "die_value" => 3,
                 "target_cell" => first
               })

      assert {:ok, game} = dispatch(game, "select", "p1", %{"target_cell" => second})

      assert %{submit_ready: false, resolution: nil, available_cells: available_cells} =
               Rules.selection_details(game, "p1")

      assert third in available_cells

      assert {:ok, game} = dispatch(game, "select", "p1", %{"target_cell" => third})

      assert %{submit_ready: true, resolution: :shape, available_cells: []} =
               Rules.selection_details(game, "p1")
    end

    test "rejects invalid continuations and preserves the canonical selection" do
      game = submit_game(1)
      first = cell(:a, 0, 0)

      assert {:ok, game} =
               dispatch(game, "select", "p1", %{
                 "mark" => "tree",
                 "die_value" => 1,
                 "target_cell" => first
               })

      selection = game.players["p1"].selection

      assert {:error, :invalid_target} =
               dispatch(game, "select", "p1", %{"target_cell" => cell(:b, 0, 0)})

      assert game.players["p1"].selection == selection
    end

    test "derives volunteer cost without storing or spending it during selection" do
      game = submit_game(1)

      assert {:ok, game} =
               dispatch(game, "select", "p1", %{
                 "mark" => "tree",
                 "die_value" => 2,
                 "target_cell" => cell(:a, 0, 0)
               })

      assert game.players["p1"].selection == %{mark: :tree, value: 2, cells: [cell(:a, 0, 0)]}

      assert %{volunteers: 1} = Rules.selection_details(game, "p1")
      assert game.players["p1"].sheet.volunteers == available_volunteers()
    end

    test "returns no private selection outside the actionable caller context" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")

      assert Rules.turn_options(game, "p1") == %{}
      assert Rules.selection_details(game, "p1") == nil
      assert Rules.selection_details(game, "missing") == nil
    end
  end

  defp submit_game(value) do
    {:ok, game} = D20.Game.init(Game, %{"sheet" => "dharug"})
    {:ok, game} = dispatch(game, "join", "p1")
    {:ok, game} = dispatch(game, "start", "p1")

    %{
      game
      | phase: :submit,
        roll: %{value: value},
        players:
          Map.new(game.players, fn {id, player} ->
            {id, %{player | status: :pending, selection: nil}}
          end)
    }
  end

  defp available_volunteers do
    [:available, :locked, :locked, :locked, :locked, :locked]
  end

  defp cell(area, row, column), do: %{area: area, row: row, column: column}

  defp dispatch(game, event, actor_id, attrs \\ %{}) do
    Game.dispatch(game, %Command{event: event, actor_id: actor_id, attrs: attrs})
  end
end
