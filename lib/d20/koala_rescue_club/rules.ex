defmodule D20.KoalaRescueClub.Rules do
  @moduledoc """
  State-dependent Koala Rescue Club command checks and turn resolution.
  """

  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Ruleset

  @type reason ::
          :invalid_player_count
          | :invalid_phase
          | :invalid_sheet
          | :not_joined
          | :unknown_player
          | :already_submitted
          | :roll_already_exists
          | :missing_roll
          | :invalid_die_value
          | :insufficient_volunteers
          | :invalid_action
          | :mixed_action
          | :invalid_shape
          | :invalid_target
          | :invalid_area
          | :inaccessible_area
          | :occupied
          | :koala_requires_tree
          | :bonus_not_unlocked
          | :bonus_already_resolved
          | :invalid_bonus
          | :invalid_hospital
          | :invalid_skybridge
          | :invalid_badge

  @spec validate(Game.t(), D20.Command.t()) :: :ok | {:error, reason()}
  def validate(game, %D20.Command{event: "join", actor_id: actor_id}) do
    with :ok <- require_phase(game, [:setup, :ready]),
         :ok <- require_player_count_in_range(game, actor_id) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "start"}) do
    with :ok <- require_phase(game, :ready),
         :ok <- require_player_count_in_range(game) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "roll", actor_id: actor_id}) do
    with :ok <- require_phase(game, :roll),
         :ok <- require_player(game, actor_id),
         :ok <- require_missing_roll(game) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: event} = command)
      when event in ["plant_trees", "rehome_koalas", "circle_tree", "circle_koala"] do
    case resolve_turn(game, command) do
      {:ok, _player} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def validate(%Game{}, %D20.Command{}), do: {:error, :invalid_phase}

  @spec ready_to_start?(Game.t()) :: boolean()
  def ready_to_start?(%Game{order: player_ids}) do
    length(player_ids) in Ruleset.player_count_range()
  end

  @spec roll_allowed?(Game.t(), Game.player_id()) :: boolean()
  def roll_allowed?(%Game{} = game, player_id) do
    validate(game, %D20.Command{event: "roll", actor_id: player_id}) == :ok
  end

  @spec submit_allowed?(Game.t(), Game.player_id()) :: boolean()
  def submit_allowed?(%Game{} = game, player_id) do
    with :ok <- require_phase(game, :submit),
         :ok <- require_player_status(game, player_id, :pending),
         :ok <- require_roll(game) do
      true
    else
      {:error, _reason} -> false
    end
  end

  @spec turn_complete?(Game.t()) :: boolean()
  def turn_complete?(%Game{} = game) do
    Enum.all?(game.players, fn {_player_id, player} -> player.status == :submitted end)
  end

  @spec resolve_turn(Game.t(), D20.Command.t()) ::
          {:ok, Game.player()} | {:error, reason()}
  def resolve_turn(%Game{} = game, %D20.Command{event: event, actor_id: actor_id, attrs: attrs})
      when event in ["plant_trees", "rehome_koalas", "circle_tree", "circle_koala"] do
    with :ok <- require_phase(game, :submit),
         :ok <- require_roll(game),
         :ok <- require_player_status(game, actor_id, :pending),
         {:ok, map} <- fetch_sheet(game.sheet),
         player <- Map.fetch!(game.players, actor_id),
         {:ok, sheet} <- spend_volunteers(player.sheet, game.roll.value, attrs),
         {:ok, sheet} <- apply_turn_action(map, sheet, event, attrs, attrs.die_value),
         {:ok, sheet} <- apply_bonus_actions(map, sheet, attrs.bonus_actions) do
      {:ok, %{player | sheet: sheet, status: :submitted}}
    end
  end

  def resolve_turn(%Game{}, %D20.Command{}), do: {:error, :invalid_phase}

  @spec badge_satisfied?(map(), map(), map()) :: boolean()
  def badge_satisfied?(map, sheet, %{requirement: %{complete: %{area: area, mark: :trees}}}) do
    Ruleset.trees_complete?(map, sheet, area)
  end

  def badge_satisfied?(map, sheet, %{requirement: %{complete: %{area: area, mark: :koalas}}}) do
    Ruleset.koalas_complete?(map, sheet, area)
  end

  def badge_satisfied?(_map, sheet, %{
        requirement: %{count: %{field: :skybridges, at_least: at_least}}
      }) do
    length(sheet.skybridges) >= at_least
  end

  def badge_satisfied?(_map, sheet, %{
        requirement: %{count: %{field: :volunteers, at_least: at_least}}
      }) do
    claimed_volunteers(sheet) >= at_least
  end

  def badge_satisfied?(map, sheet, %{requirement: %{filled: %{hospital: hospital_id}}}) do
    case Map.fetch(map.hospitals, hospital_id) do
      {:ok, hospital} -> Map.get(sheet.hospitals, hospital_id, 0) >= hospital.size
      :error -> false
    end
  end

  def badge_satisfied?(_map, _sheet, _badge), do: false

  defp require_phase(%{phase: phase}, expected) when is_list(expected) do
    if phase in expected, do: :ok, else: {:error, :invalid_phase}
  end

  defp require_phase(%{phase: phase}, phase), do: :ok
  defp require_phase(%{phase: _phase}, _expected), do: {:error, :invalid_phase}

  defp require_player_count_in_range(%{order: player_ids, players: players}, player_id \\ nil) do
    count =
      cond do
        is_nil(player_id) -> length(player_ids)
        Map.has_key?(players, player_id) -> length(player_ids)
        true -> length(player_ids) + 1
      end

    if count in Ruleset.player_count_range(),
      do: :ok,
      else: {:error, :invalid_player_count}
  end

  defp require_player(game, player_id) do
    if Map.has_key?(game.players, player_id), do: :ok, else: {:error, :not_joined}
  end

  defp require_player_status(game, player_id, status) do
    with :ok <- require_player(game, player_id) do
      case game.players[player_id].status do
        ^status -> :ok
        :submitted -> {:error, :already_submitted}
        _status -> {:error, :invalid_phase}
      end
    end
  end

  defp require_missing_roll(%{roll: nil}), do: :ok
  defp require_missing_roll(%{roll: _roll}), do: {:error, :roll_already_exists}

  defp require_roll(%{roll: nil}), do: {:error, :missing_roll}
  defp require_roll(%{roll: %{value: value}}) when value in 1..6, do: :ok
  defp require_roll(%{roll: _roll}), do: {:error, :missing_roll}

  defp fetch_sheet(sheet) do
    case Ruleset.sheet(sheet) do
      {:ok, map} -> {:ok, map}
      {:error, :unknown_sheet} -> {:error, :invalid_sheet}
    end
  end

  defp spend_volunteers(sheet, value, %{die_value: die_value, volunteers_used: volunteers_used}) do
    with {:ok, needed} <- Ruleset.volunteers_needed(value, die_value),
         true <- needed == volunteers_used,
         {:ok, volunteers} <- spend_volunteer_slots(sheet.volunteers, volunteers_used) do
      {:ok, %{sheet | volunteers: volunteers}}
    else
      {:error, :invalid_die_value} -> {:error, :invalid_die_value}
      {:error, :insufficient_volunteers} -> {:error, :insufficient_volunteers}
      false -> {:error, :insufficient_volunteers}
    end
  end

  defp spend_volunteer_slots(volunteers, count) do
    if Enum.count(volunteers, &(&1 == :available)) >= count do
      {volunteers, _remaining} =
        Enum.map_reduce(volunteers, count, fn
          :available, remaining when remaining > 0 -> {:used, remaining - 1}
          status, remaining -> {status, remaining}
        end)

      {:ok, volunteers}
    else
      {:error, :insufficient_volunteers}
    end
  end

  defp claimed_volunteers(sheet) do
    Enum.count(sheet.volunteers, &(&1 != :locked))
  end

  defp apply_turn_action(map, sheet, event, %{target_cells: cells}, die_value)
       when event in ["plant_trees", "rehome_koalas"] do
    with {:ok, cell_ids} <- cell_ids(map, cells),
         :ok <- require_unique_targets(cells),
         :ok <- require_shape(map, cell_ids, die_value),
         :ok <- require_one_accessible_area(map, sheet, cell_ids) do
      apply_shape_action(map, sheet, event, cells)
    end
  end

  defp apply_turn_action(map, sheet, event, %{target_cell: cell}, _die_value)
       when event in ["circle_tree", "circle_koala"] do
    cell_id = Ruleset.cell_id(cell)

    with :ok <- require_one_accessible_area(map, sheet, [cell_id]) do
      apply_single_action(map, sheet, event, cell)
    end
  end

  defp apply_turn_action(_map, _sheet, _event, _attrs, _die_value), do: {:error, :invalid_action}

  defp require_unique_targets(cell_ids) do
    if Enum.uniq(cell_ids) == cell_ids, do: :ok, else: {:error, :invalid_target}
  end

  defp require_shape(map, cell_ids, die_value) do
    if Ruleset.shape_match?(map, cell_ids, die_value), do: :ok, else: {:error, :invalid_shape}
  end

  defp cell_ids(%{cells: cells_by_id}, target_cells) do
    Enum.reduce_while(target_cells, {:ok, []}, fn cell, {:ok, cell_ids} ->
      cell_id = Ruleset.cell_id(cell)

      if Map.has_key?(cells_by_id, cell_id) do
        {:cont, {:ok, [cell_id | cell_ids]}}
      else
        {:halt, {:error, :invalid_target}}
      end
    end)
    |> case do
      {:ok, cell_ids} -> {:ok, Enum.reverse(cell_ids)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp require_one_accessible_area(%{cells: cells} = map, player_sheet, cell_ids) do
    with {:ok, areas} <- target_areas(cells, cell_ids),
         [area] <- Enum.uniq(areas),
         true <- area in Ruleset.accessible_areas(map, player_sheet) do
      :ok
    else
      {:error, reason} -> {:error, reason}
      [] -> {:error, :invalid_target}
      [_one, _two | _rest] -> {:error, :invalid_area}
      false -> {:error, :inaccessible_area}
    end
  end

  defp target_areas(cells, cell_ids) do
    Enum.reduce_while(cell_ids, {:ok, []}, fn cell_id, {:ok, areas} ->
      case Map.fetch(cells, cell_id) do
        {:ok, cell} -> {:cont, {:ok, [cell.area | areas]}}
        :error -> {:halt, {:error, :invalid_target}}
      end
    end)
  end

  defp apply_shape_action(_map, sheet, "plant_trees", cells) do
    if Enum.any?(cells, &(&1 in sheet.trees)) do
      {:error, :occupied}
    else
      {:ok, %{sheet | trees: add_refs(sheet.trees, cells)}}
    end
  end

  defp apply_shape_action(map, sheet, "rehome_koalas", cells) do
    Enum.reduce_while(cells, {:ok, sheet}, fn cell, {:ok, sheet} ->
      with :ok <- require_koala_target(map, sheet, cell) do
        {:cont, {:ok, %{sheet | koalas: add_refs(sheet.koalas, [cell])}}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp apply_single_action(_map, sheet, "circle_tree", cell) do
    if cell in sheet.trees do
      {:error, :occupied}
    else
      {:ok, %{sheet | trees: add_refs(sheet.trees, [cell])}}
    end
  end

  defp apply_single_action(map, sheet, "circle_koala", cell) do
    with :ok <- require_koala_target(map, sheet, cell) do
      {:ok, %{sheet | koalas: add_refs(sheet.koalas, [cell])}}
    end
  end

  defp require_koala_target(%{cells: cells}, player_sheet, target_cell) do
    cell_id = Ruleset.cell_id(target_cell)

    with {:ok, ruleset_cell} <- Map.fetch(cells, cell_id),
         true <- ruleset_cell.contains_koala,
         true <- target_cell in player_sheet.trees,
         false <- target_cell in player_sheet.koalas do
      :ok
    else
      :error -> {:error, :invalid_target}
      false -> {:error, :koala_requires_tree}
      true -> {:error, :occupied}
    end
  end

  defp apply_bonus_actions(map, sheet, bonus_actions) do
    Enum.reduce_while(bonus_actions, {:ok, sheet}, fn bonus_action, {:ok, sheet} ->
      case apply_bonus_action(map, sheet, bonus_action) do
        {:ok, sheet} -> {:cont, {:ok, sheet}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, sheet} -> {:ok, sheet}
      {:error, reason} -> {:error, reason}
    end
  end

  defp apply_bonus_action(map, sheet, %{bonus: bonus_ref, action: action}) do
    with {:ok, bonus} <- fetch_unlocked_bonus(map, sheet, bonus_ref),
         :ok <- require_bonus_action_match(bonus, action),
         {:ok, sheet} <- apply_bonus_effect(map, sheet, bonus, action) do
      {:ok, put_bonus_resolution(sheet, bonus_ref, :resolved)}
    end
  end

  defp fetch_unlocked_bonus(map, player_sheet, bonus_ref) do
    cond do
      bonus_resolved?(player_sheet, bonus_ref) -> {:error, :bonus_already_resolved}
      bonus_ref not in unlocked_bonus_refs(map, player_sheet) -> {:error, :bonus_not_unlocked}
      true -> fetch_bonus(map.bonuses, bonus_ref)
    end
  end

  defp fetch_bonus(bonuses, bonus_ref) do
    bonuses
    |> Map.values()
    |> Enum.find(&(Map.get(&1, :ref) == bonus_ref))
    |> case do
      nil -> {:error, :invalid_bonus}
      bonus -> {:ok, bonus}
    end
  end

  defp require_bonus_action_match(%{kind: :skybridge, target_area: target_area}, %{
         kind: :skybridge,
         to_area: target_area
       }),
       do: :ok

  defp require_bonus_action_match(%{kind: :skybridge}, %{kind: :skybridge}),
    do: {:error, :invalid_bonus}

  defp require_bonus_action_match(%{kind: kind, target_id: target_id}, %{kind: kind} = action) do
    target = Map.get(action, :hospital_id) || Map.get(action, :target_cell)

    if target == target_id, do: :ok, else: {:error, :invalid_bonus}
  end

  defp require_bonus_action_match(%{kind: kind}, %{kind: kind}), do: :ok
  defp require_bonus_action_match(_bonus, _action), do: {:error, :invalid_bonus}

  defp apply_bonus_effect(map, sheet, _bonus, %{kind: :tree, target_cell: cell}) do
    cell_id = Ruleset.cell_id(cell)

    with :ok <- require_one_accessible_area(map, sheet, [cell_id]) do
      apply_single_action(map, sheet, "circle_tree", cell)
    end
  end

  defp apply_bonus_effect(map, sheet, _bonus, %{kind: :koala, target_cell: cell}) do
    cell_id = Ruleset.cell_id(cell)

    with :ok <- require_one_accessible_area(map, sheet, [cell_id]) do
      apply_single_action(map, sheet, "circle_koala", cell)
    end
  end

  defp apply_bonus_effect(_map, sheet, _bonus, %{kind: :volunteer}) do
    case claim_volunteer(sheet.volunteers) do
      {:ok, volunteers} -> {:ok, %{sheet | volunteers: volunteers}}
      :error -> {:error, :invalid_bonus}
    end
  end

  defp apply_bonus_effect(%{hospitals: hospitals}, player_sheet, _bonus, %{
         kind: :hospital,
         hospital_id: hospital_id
       }) do
    with {:ok, hospital} <- Map.fetch(hospitals, hospital_id),
         filled <- Map.get(player_sheet.hospitals, hospital_id, 0),
         true <- filled < hospital.size do
      {:ok, put_in(player_sheet.hospitals[hospital_id], filled + 1)}
    else
      :error -> {:error, :invalid_hospital}
      false -> {:error, :invalid_hospital}
    end
  end

  defp apply_bonus_effect(%{skybridges: skybridges} = map, player_sheet, bonus, %{
         kind: :skybridge,
         to_area: to_area
       }) do
    with {:ok, skybridge} <- fetch_skybridge(skybridges, bonus.ref.area, to_area),
         false <- skybridge in player_sheet.skybridges,
         true <- skybridge.from in Ruleset.accessible_areas(map, player_sheet) do
      {:ok, %{player_sheet | skybridges: add_skybridges(player_sheet.skybridges, [skybridge])}}
    else
      :error -> {:error, :invalid_skybridge}
      true -> {:error, :invalid_skybridge}
      false -> {:error, :inaccessible_area}
    end
  end

  defp claim_volunteer(volunteers) do
    case Enum.find_index(volunteers, &(&1 == :locked)) do
      nil -> :error
      index -> {:ok, List.replace_at(volunteers, index, :available)}
    end
  end

  defp fetch_skybridge(skybridges, from_area, to_area) do
    skybridges
    |> Map.values()
    |> Enum.find(&(&1.from == from_area and &1.to == to_area))
    |> case do
      nil -> {:error, :invalid_skybridge}
      skybridge -> {:ok, skybridge}
    end
  end

  defp unlocked_bonus_refs(%{rows: rows, columns: columns}, player_sheet) do
    koala_cell_ids = player_sheet.koalas |> Enum.map(&Ruleset.cell_id/1) |> MapSet.new()

    rows
    |> Map.values()
    |> Kernel.++(Map.values(columns))
    |> Enum.filter(& &1.bonus)
    |> Enum.filter(fn line ->
      not bonus_resolved?(player_sheet, line.bonus.ref) and
        Enum.all?(line.cell_ids, &MapSet.member?(koala_cell_ids, &1))
    end)
    |> Enum.map(& &1.bonus.ref)
  end

  defp bonus_resolved?(sheet, bonus_ref) do
    Enum.any?(sheet.bonuses, &(bonus_ref(&1) == bonus_ref))
  end

  defp put_bonus_resolution(sheet, bonus_ref, :resolved) do
    bonuses =
      sheet.bonuses
      |> Enum.reject(&(bonus_ref(&1) == bonus_ref))
      |> Kernel.++([bonus_ref])
      |> Enum.sort_by(&{&1.area, &1.axis, &1.index})

    %{sheet | bonuses: bonuses}
  end

  defp bonus_ref(%{area: area, axis: axis, index: index}) do
    %{area: area, axis: axis, index: index}
  end

  defp add_refs(existing, refs) do
    existing
    |> Kernel.++(refs)
    |> Enum.uniq()
    |> Enum.sort_by(&{&1.area, &1.row, &1.column})
  end

  defp add_skybridges(existing, skybridges) do
    existing
    |> Kernel.++(skybridges)
    |> Enum.uniq()
    |> Enum.sort_by(&{&1.from, &1.to})
  end
end
