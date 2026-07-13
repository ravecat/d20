defmodule D20.KoalaRescueClub.Rules do
  @moduledoc """
  State-dependent Koala Rescue Club command checks and turn resolution.
  """

  import D20.Guards, only: [is_player_id: 1]

  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Ruleset
  alias D20.KoalaRescueClub.Ruleset.Sheet

  @type reason ::
          :invalid_player_count
          | :invalid_identity
          | :invalid_phase
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
  def validate(game, %D20.Command{event: "join", actor_id: actor_id} = command) do
    with :ok <- require_actor(command),
         :ok <- require_phase(game, [:setup, :ready]),
         :ok <- require_player_count_in_range(game, actor_id) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "start"} = command) do
    with :ok <- require_actor(command),
         :ok <- require_phase(game, :ready),
         :ok <- require_player_count_in_range(game) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "roll"} = command) do
    with :ok <- require_missing_actor(command),
         :ok <- require_phase(game, :roll),
         :ok <- require_missing_roll(game) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: event} = command)
      when event in ["plant_trees", "rehome_koalas", "circle_tree", "circle_koala"] do
    with :ok <- require_actor(command) do
      case resolve_turn(game, command) do
        {:ok, _player} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def validate(%Game{}, %D20.Command{}), do: {:error, :invalid_phase}

  @spec ready_to_start?(Game.t()) :: boolean()
  def ready_to_start?(%Game{order: player_ids}) do
    length(player_ids) in Ruleset.player_count_range()
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

  @doc "Returns caller-specific die values and shapes available for the pending turn."
  @spec turn_options(Game.t(), Game.player_id()) :: [
          %{
            required(:die_value) => 1..6,
            required(:volunteers_used) => non_neg_integer(),
            required(:shape) => [
              %{required(:row) => non_neg_integer(), required(:column) => non_neg_integer()}
            ]
          }
        ]
  def turn_options(%Game{} = game, player_id) do
    if submit_allowed?(game, player_id) do
      available_volunteers =
        Enum.count(game.players[player_id].sheet.volunteers, &(&1 == :available))

      for die_value <- 1..6,
          {:ok, volunteers_used} = Ruleset.volunteers_needed(game.roll.value, die_value),
          volunteers_used <= available_volunteers do
        {:ok, shape} = Ruleset.shape(die_value)

        %{die_value: die_value, volunteers_used: volunteers_used, shape: shape}
      end
    else
      []
    end
  end

  @spec resolve_turn(Game.t(), D20.Command.t()) ::
          {:ok, Game.player()} | {:error, reason()}
  def resolve_turn(%Game{} = game, %D20.Command{event: event, actor_id: actor_id, attrs: attrs})
      when event in ["plant_trees", "rehome_koalas", "circle_tree", "circle_koala"] do
    with :ok <- require_phase(game, :submit),
         :ok <- require_roll(game),
         :ok <- require_player_status(game, actor_id, :pending),
         rulesheet = Ruleset.sheet!(game.sheet),
         player <- Map.fetch!(game.players, actor_id),
         {:ok, sheet} <- spend_volunteers(player.sheet, game.roll.value, attrs),
         {:ok, sheet} <- apply_turn_action(rulesheet, sheet, event, attrs, attrs.die_value),
         {:ok, sheet} <- apply_bonus_actions(rulesheet, sheet, attrs.bonus_actions) do
      {:ok, %{player | sheet: sheet, status: :submitted}}
    end
  end

  def resolve_turn(%Game{}, %D20.Command{}), do: {:error, :invalid_phase}

  @spec badge_satisfied?(Sheet.t(), Game.sheet(), map()) :: boolean()
  def badge_satisfied?(rulesheet, player_sheet, %{
        requirement: %{complete: %{area: area, mark: :trees}}
      }) do
    Ruleset.trees_complete?(rulesheet, player_sheet, area)
  end

  def badge_satisfied?(rulesheet, player_sheet, %{
        requirement: %{complete: %{area: area, mark: :koalas}}
      }) do
    Ruleset.koalas_complete?(rulesheet, player_sheet, area)
  end

  def badge_satisfied?(_rulesheet, player_sheet, %{
        requirement: %{count: %{field: :skybridges, at_least: at_least}}
      }) do
    length(player_sheet.skybridges) >= at_least
  end

  def badge_satisfied?(_rulesheet, player_sheet, %{
        requirement: %{count: %{field: :volunteers, at_least: at_least}}
      }) do
    claimed_volunteers(player_sheet) >= at_least
  end

  def badge_satisfied?(rulesheet, player_sheet, %{
        requirement: %{filled: %{hospital: hospital_id}}
      }) do
    case Map.fetch(rulesheet.hospitals, hospital_id) do
      {:ok, hospital} -> Map.get(player_sheet.hospitals, hospital_id, 0) >= hospital.size
      :error -> false
    end
  end

  def badge_satisfied?(_rulesheet, _player_sheet, _badge), do: false

  defp require_phase(%{phase: phase}, expected) when is_list(expected) do
    if phase in expected, do: :ok, else: {:error, :invalid_phase}
  end

  defp require_phase(%{phase: phase}, phase), do: :ok
  defp require_phase(%{phase: _phase}, _expected), do: {:error, :invalid_phase}

  defp require_actor(%D20.Command{actor_id: actor_id}) when is_player_id(actor_id), do: :ok
  defp require_actor(%D20.Command{}), do: {:error, :invalid_identity}

  defp require_missing_actor(%D20.Command{actor_id: nil}), do: :ok
  defp require_missing_actor(%D20.Command{}), do: {:error, :invalid_identity}

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
    with {:ok, valid_cells} <- valid_cells(map, cells),
         :ok <- require_unique_targets(cells),
         :ok <- require_shape(map, valid_cells, die_value),
         :ok <- require_one_accessible_area(map, sheet, valid_cells) do
      apply_shape_action(map, sheet, event, cells)
    end
  end

  defp apply_turn_action(map, sheet, event, %{target_cell: cell}, _die_value)
       when event in ["circle_tree", "circle_koala"] do
    with :ok <- require_one_accessible_area(map, sheet, [cell]) do
      apply_single_action(map, sheet, event, cell)
    end
  end

  defp apply_turn_action(_map, _sheet, _event, _attrs, _die_value), do: {:error, :invalid_action}

  defp require_unique_targets(cells) do
    if Enum.uniq(cells) == cells, do: :ok, else: {:error, :invalid_target}
  end

  defp require_shape(map, cells, die_value) do
    if Ruleset.shape_match?(map, cells, die_value), do: :ok, else: {:error, :invalid_shape}
  end

  defp valid_cells(rulesheet, target_cells) do
    Enum.reduce_while(target_cells, {:ok, []}, fn cell, {:ok, cells} ->
      if Ruleset.cell_exists?(rulesheet, cell) do
        {:cont, {:ok, [cell | cells]}}
      else
        {:halt, {:error, :invalid_target}}
      end
    end)
    |> case do
      {:ok, cells} -> {:ok, Enum.reverse(cells)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp require_one_accessible_area(rulesheet, player_sheet, cells) do
    with {:ok, areas} <- target_areas(rulesheet, cells),
         [area] <- Enum.uniq(areas),
         true <- area in Ruleset.accessible_areas(player_sheet) do
      :ok
    else
      {:error, reason} -> {:error, reason}
      [] -> {:error, :invalid_target}
      [_one, _two | _rest] -> {:error, :invalid_area}
      false -> {:error, :inaccessible_area}
    end
  end

  defp target_areas(rulesheet, cells) do
    Enum.reduce_while(cells, {:ok, []}, fn cell, {:ok, areas} ->
      if Ruleset.cell_exists?(rulesheet, cell) do
        {:cont, {:ok, [cell.area | areas]}}
      else
        {:halt, {:error, :invalid_target}}
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

  defp require_koala_target(rulesheet, player_sheet, target_cell) do
    with :ok <- require_cell_exists(rulesheet, target_cell),
         true <- target_cell in player_sheet.trees,
         false <- target_cell in player_sheet.koalas do
      :ok
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :koala_requires_tree}
      true -> {:error, :occupied}
    end
  end

  defp require_cell_exists(rulesheet, cell) do
    if Ruleset.cell_exists?(rulesheet, cell), do: :ok, else: {:error, :invalid_target}
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
    with {:ok, bonus_entry} <- fetch_unlocked_bonus(map, sheet, bonus_ref),
         :ok <- require_bonus_action_match(bonus_entry.bonus, action),
         {:ok, sheet} <- apply_bonus_effect(map, sheet, bonus_entry, action) do
      {:ok, put_bonus_resolution(sheet, bonus_ref, :resolved)}
    end
  end

  defp fetch_unlocked_bonus(map, player_sheet, bonus_ref) do
    if bonus_resolved?(player_sheet, bonus_ref) do
      {:error, :bonus_already_resolved}
    else
      find_unlocked_bonus(map, player_sheet, bonus_ref)
    end
  end

  defp find_unlocked_bonus(map, player_sheet, bonus_ref) do
    map
    |> unlocked_bonuses(player_sheet)
    |> Enum.find(&(bonus_ref(&1.ref) == bonus_ref))
    |> case do
      nil -> {:error, :bonus_not_unlocked}
      bonus_entry -> {:ok, bonus_entry}
    end
  end

  defp require_bonus_action_match(%{kind: :skybridge, to: to}, %{kind: :skybridge, to: to}),
    do: :ok

  defp require_bonus_action_match(%{kind: :skybridge}, %{kind: :skybridge}),
    do: {:error, :invalid_bonus}

  defp require_bonus_action_match(_bonus, %{kind: :skip}), do: :ok
  defp require_bonus_action_match(%{kind: kind}, %{kind: kind}), do: :ok
  defp require_bonus_action_match(_bonus, _action), do: {:error, :invalid_bonus}

  defp apply_bonus_effect(%Sheet{} = rulesheet, player_sheet, _bonus, %{
         kind: :tree,
         target_cell: cell
       }) do
    with :ok <- require_one_accessible_area(rulesheet, player_sheet, [cell]) do
      apply_single_action(rulesheet, player_sheet, "circle_tree", cell)
    end
  end

  defp apply_bonus_effect(%Sheet{} = rulesheet, player_sheet, _bonus, %{
         kind: :koala,
         target_cell: cell
       }) do
    with :ok <- require_one_accessible_area(rulesheet, player_sheet, [cell]) do
      apply_single_action(rulesheet, player_sheet, "circle_koala", cell)
    end
  end

  defp apply_bonus_effect(%Sheet{}, player_sheet, _bonus, %{kind: :volunteer}) do
    case claim_volunteer(player_sheet.volunteers) do
      {:ok, volunteers} -> {:ok, %{player_sheet | volunteers: volunteers}}
      :error -> {:error, :invalid_bonus}
    end
  end

  defp apply_bonus_effect(%Sheet{hospitals: hospitals}, player_sheet, _bonus, %{
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

  defp apply_bonus_effect(%Sheet{skybridges: skybridges}, player_sheet, bonus_entry, %{
         kind: :skybridge,
         to: to
       }) do
    with {:ok, skybridge} <- fetch_skybridge(skybridges, bonus_entry.ref.area, to),
         false <- skybridge in player_sheet.skybridges,
         true <- skybridge.from in Ruleset.accessible_areas(player_sheet) do
      player_sheet =
        player_sheet
        |> Map.put(:skybridges, add_skybridges(player_sheet.skybridges, [skybridge]))
        |> put_area_access(skybridge.to, true)

      {:ok, player_sheet}
    else
      :error -> {:error, :invalid_skybridge}
      true -> {:error, :invalid_skybridge}
      false -> {:error, :inaccessible_area}
    end
  end

  defp apply_bonus_effect(%Sheet{}, player_sheet, _bonus, %{kind: :skip}) do
    {:ok, player_sheet}
  end

  defp claim_volunteer(volunteers) do
    case Enum.find_index(volunteers, &(&1 == :locked)) do
      nil -> :error
      index -> {:ok, List.replace_at(volunteers, index, :available)}
    end
  end

  defp fetch_skybridge(skybridges, from_area, to_area) do
    skybridges
    |> Enum.find(&(&1.from == from_area and &1.to == to_area))
    |> case do
      nil -> {:error, :invalid_skybridge}
      skybridge -> {:ok, skybridge}
    end
  end

  defp unlocked_bonuses(map, player_sheet) do
    koalas = MapSet.new(player_sheet.koalas)

    map
    |> Ruleset.bonuses()
    |> Enum.filter(fn bonus_entry ->
      cells = Ruleset.line_cells(map, bonus_entry.ref)

      not bonus_resolved?(player_sheet, bonus_entry.ref) and cells != [] and
        Enum.all?(cells, &MapSet.member?(koalas, &1))
    end)
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

  defp put_area_access(player_sheet, area, access) do
    Map.update!(player_sheet, :areas, &Map.put(&1, area, access))
  end
end
