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

      assert {:ok,
              %{
                mark: :tree,
                die_value: 1,
                volunteers_used: 0,
                selected_cells: [^target],
                required_cells: 2,
                available_cells: available_cells,
                submit_ready: true,
                resolution: :single,
                bonus_options: []
              }} = preview(game, "p1", :tree, 1, [target])

      assert available_cells != []
    end

    test "classifies an isolated one-cell fallback without continuations" do
      game = submit_game(1)
      rulesheet = Ruleset.sheet!(:dharug)
      target = cell(:a, 0, 0)
      occupied = rulesheet |> Ruleset.area_cells(:a) |> List.delete(target)
      game = put_in(game.players["p1"].sheet.trees, occupied)

      assert {:ok, %{submit_ready: true, resolution: :single, available_cells: []}} =
               preview(game, "p1", :tree, 1, [target])
    end

    test "classifies shape prefixes and complete shapes" do
      game = submit_game(3)
      first = cell(:a, 0, 0)
      second = cell(:a, 0, 1)
      third = cell(:a, 0, 2)

      assert {:ok, %{submit_ready: false, resolution: nil, available_cells: available_cells}} =
               preview(game, "p1", :tree, 3, [first, second])

      assert third in available_cells

      assert {:ok, %{submit_ready: true, resolution: :shape, available_cells: []}} =
               preview(game, "p1", :tree, 3, [first, second, third])
    end

    test "rejects an invalid continuation and keeps the aggregate unchanged" do
      game = submit_game(1)

      assert {:error, :no_legal_placement} =
               preview(game, "p1", :tree, 1, [cell(:a, 0, 0), cell(:b, 0, 0)])

      refute Map.has_key?(game.players["p1"], :selection)
      assert game.players["p1"].sheet.trees == []
    end

    test "derives volunteer cost without storing or spending it" do
      game = submit_game(1)

      assert {:ok, %{volunteers_used: 1}} = preview(game, "p1", :tree, 2, [cell(:a, 0, 0)])

      assert game.players["p1"].sheet.volunteers == available_volunteers()
      refute Map.has_key?(game.players["p1"], :selection)
    end

    test "rejects preview outside the actionable caller context" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")

      assert Rules.turn_options(game, "p1") == %{}
      assert {:error, :invalid_phase} = preview(game, "p1", :tree, 1, [cell(:a, 0, 0)])
      assert {:error, :invalid_phase} = preview(game, "missing", :tree, 1, [cell(:a, 0, 0)])
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
        players: Map.new(game.players, fn {id, player} -> {id, %{player | status: :pending}} end)
    }
  end

  defp available_volunteers do
    [:available, :locked, :locked, :locked, :locked, :locked]
  end

  defp preview(game, actor_id, mark, value, cells) do
    case Game.dispatch(game, %Command{
           event: "draft",
           actor_id: actor_id,
           attrs: %{mark: mark, die_value: value, selected_cells: cells}
         }) do
      {:ok, ^game, {:draft, data}} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  defp cell(area, row, column), do: %{area: area, row: row, column: column}

  defp dispatch(game, event, actor_id, attrs \\ %{}) do
    Game.dispatch(game, %Command{event: event, actor_id: actor_id, attrs: attrs})
  end
end
