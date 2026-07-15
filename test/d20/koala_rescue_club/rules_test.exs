defmodule D20.KoalaRescueClub.RulesTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Rules

  describe "caller turn analysis" do
    test "returns domain options and stored selection details without wire field names" do
      {:ok, game} = D20.Game.init(Game, %{"sheet" => "dharug"})
      {:ok, game} = dispatch(game, "join", "p1")
      {:ok, game} = dispatch(game, "start", "p1")
      {:ok, game} = dispatch(game, "roll", nil)

      value = game.roll.value
      options = Rules.turn_options(game, "p1")

      assert Map.keys(options) |> Enum.sort() == Enum.to_list(1..6)
      assert %{volunteer_cost: 0, actions: actions} = options[value]
      assert %{available_cells: [target | _rest]} = actions["plant_trees"]

      assert {:ok, game} =
               dispatch(game, "select", "p1", %{
                 "action" => "plant_trees",
                 "die_value" => value,
                 "volunteers_used" => 0,
                 "target_cell" => target
               })

      assert %{
               action: "plant_trees",
               value: ^value,
               volunteers: 0,
               cells: [^target],
               required_cells: required_cells,
               available_cells: available_cells,
               complete: false,
               bonus_options: []
             } = details = Rules.selection_details(game, "p1")

      assert required_cells in 2..4
      assert available_cells != []
      refute Map.has_key?(details, :die_value)
      refute Map.has_key?(details, :volunteers_used)
      refute Map.has_key?(details, :selected_cells)
    end

    test "returns no private selection outside the actionable caller context" do
      {:ok, game} = D20.Game.init(Game)
      {:ok, game} = dispatch(game, "join", "p1")

      assert Rules.turn_options(game, "p1") == %{}
      assert Rules.selection_details(game, "p1") == nil
      assert Rules.selection_details(game, "missing") == nil
    end
  end

  defp dispatch(game, event, actor_id, attrs \\ %{}) do
    Game.dispatch(game, %Command{event: event, actor_id: actor_id, attrs: attrs})
  end
end
