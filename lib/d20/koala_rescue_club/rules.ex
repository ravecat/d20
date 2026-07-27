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
          | :invalid_shape
          | :no_legal_placement
          | :missing_turn_selection
          | :incomplete_turn_selection
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
      when event in ["select", "deselect", "reset", "submit"] do
    with :ok <- require_actor(command) do
      case resolve_turn(game, command) do
        {:ok, _player} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def validate(%Game{}, %D20.Command{}), do: {:error, :invalid_phase}

  @spec ready_to_start?(Game.t()) :: boolean()
  def ready_to_start?(%Game{players: players}) do
    map_size(players) in Ruleset.player_count_range()
  end

  @spec submit_allowed?(Game.t(), Game.player_id()) :: boolean()
  def submit_allowed?(%Game{} = game, player_id) do
    with :ok <- require_phase(game, :submit),
         {:ok, player} <- Game.fetch_player(game, player_id),
         :ok <- require_player_status(player, :pending),
         :ok <- require_roll(game) do
      true
    else
      :error -> false
      {:error, _reason} -> false
    end
  end

  @spec turn_complete?(Game.t()) :: boolean()
  def turn_complete?(%Game{} = game) do
    Enum.all?(game.players, fn {_player_id, player} -> player.status == :submitted end)
  end

  @type turn_mark_option :: %{required(:available_cells) => [Ruleset.cell()]}
  @type turn_option :: %{
          required(:volunteer_cost) => non_neg_integer(),
          required(:marks) => %{optional(Ruleset.mark()) => turn_mark_option()}
        }
  @type selection_details :: %{
          required(:mark) => Ruleset.mark(),
          required(:value) => Ruleset.die_value(),
          required(:volunteers) => non_neg_integer(),
          required(:required_cells) => pos_integer(),
          required(:cells) => [Ruleset.cell()],
          required(:available_cells) => [Ruleset.cell()],
          required(:submit_ready) => boolean(),
          required(:resolution) => :single | :shape | nil,
          required(:bonus_options) => [Ruleset.bonus_entry()]
        }

  @doc "Returns caller-specific die values and legal primary marks for the pending turn."
  @spec turn_options(Game.t(), Game.player_id()) ::
          %{optional(Ruleset.die_value()) => turn_option()}
  def turn_options(%Game{} = game, player_id) do
    with true <- submit_allowed?(game, player_id),
         {:ok, player} <- Game.fetch_player(game, player_id) do
      rulesheet = Ruleset.sheet!(game.sheet)
      available_volunteers = Enum.count(player.sheet.volunteers, &(&1 == :available))

      Map.new(1..6, fn value ->
        {:ok, volunteer_cost} = Ruleset.volunteers_needed(game.roll.value, value)

        marks =
          if volunteer_cost <= available_volunteers do
            turn_marks(rulesheet, player.sheet)
          else
            %{}
          end

        {value, %{volunteer_cost: volunteer_cost, marks: marks}}
      end)
    else
      _reason -> %{}
    end
  end

  @doc "Returns the caller's stored selection with its current rule-derived details."
  @spec selection_details(Game.t(), Game.player_id()) :: selection_details() | nil
  def selection_details(%Game{} = game, player_id) do
    with true <- submit_allowed?(game, player_id),
         {:ok, %{selection: selection} = player} when not is_nil(selection) <-
           Game.fetch_player(game, player_id),
         {:ok, volunteers} <- Ruleset.volunteers_needed(game.roll.value, selection.value),
         {:ok, details} <- analyze_selection(Ruleset.sheet!(game.sheet), player.sheet, selection) do
      Map.put(details, :volunteers, volunteers)
    else
      _reason -> nil
    end
  end

  @spec resolve_turn(Game.t(), D20.Command.t()) ::
          {:ok, Game.player()} | {:error, reason()}
  def resolve_turn(%Game{} = game, %D20.Command{event: "select", actor_id: actor_id, attrs: attrs}) do
    with {:ok, player, rulesheet} <- pending_player(game, actor_id),
         {:ok, selection} <- selection_for_select(game, player, rulesheet, attrs),
         {:ok, selection} <- select_cell(rulesheet, player.sheet, selection, attrs.target_cell) do
      {:ok, %{player | selection: selection}}
    end
  end

  def resolve_turn(%Game{} = game, %D20.Command{
        event: "deselect",
        actor_id: actor_id,
        attrs: attrs
      }) do
    with {:ok, player, rulesheet} <- pending_player(game, actor_id),
         {:ok, selection} <- require_selection(player),
         {:ok, selection} <- deselect_cell(rulesheet, player.sheet, selection, attrs.target_cell) do
      {:ok, %{player | selection: selection}}
    end
  end

  def resolve_turn(%Game{} = game, %D20.Command{event: "reset", actor_id: actor_id}) do
    with {:ok, player, _rulesheet} <- pending_player(game, actor_id) do
      {:ok, %{player | selection: nil}}
    end
  end

  def resolve_turn(%Game{} = game, %D20.Command{event: "submit", actor_id: actor_id, attrs: attrs}) do
    with {:ok, player, rulesheet} <- pending_player(game, actor_id),
         {:ok, selection} <- require_selection(player),
         {:ok, details} <- analyze_selection(rulesheet, player.sheet, selection),
         :ok <- require_submit_ready(details),
         {:ok, sheet} <- spend_volunteers(player.sheet, game.roll.value, selection.value),
         {:ok, sheet} <- apply_primary_resolution(rulesheet, sheet, selection, details.resolution),
         {:ok, sheet} <- apply_bonus_actions(rulesheet, player.sheet, sheet, attrs.bonus_actions) do
      {:ok, %{player | sheet: sheet, status: :submitted, selection: nil}}
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

  defp pending_player(game, player_id) do
    with :ok <- require_phase(game, :submit),
         :ok <- require_roll(game),
         {:ok, player} <- Game.fetch_player(game, player_id),
         :ok <- require_player_status(player, :pending) do
      {:ok, player, Ruleset.sheet!(game.sheet)}
    else
      :error -> {:error, :not_joined}
      {:error, reason} -> {:error, reason}
    end
  end

  defp require_selection(%{selection: nil}), do: {:error, :missing_turn_selection}
  defp require_selection(%{selection: selection}), do: {:ok, selection}

  defp selection_for_select(game, player, _rulesheet, %{mark: mark, die_value: value}) do
    with {:ok, _cost} <- available_volunteer_cost(player.sheet, game.roll.value, value) do
      {:ok, %{mark: mark, value: value, cells: []}}
    end
  end

  defp selection_for_select(_game, player, _rulesheet, _attrs), do: require_selection(player)

  defp select_cell(rulesheet, sheet, selection, cell) do
    if cell in selection.cells do
      {:ok, selection}
    else
      selection = %{selection | cells: selection.cells ++ [cell]}

      case analyze_selection(rulesheet, sheet, selection) do
        {:ok, _details} -> {:ok, selection}
        {:error, _reason} -> {:error, :invalid_target}
      end
    end
  end

  defp deselect_cell(rulesheet, sheet, selection, cell) do
    cond do
      cell not in selection.cells ->
        {:ok, selection}

      length(selection.cells) == 1 ->
        {:ok, nil}

      true ->
        selection = %{selection | cells: List.delete(selection.cells, cell)}

        with {:ok, _details} <- analyze_selection(rulesheet, sheet, selection) do
          {:ok, selection}
        end
    end
  end

  defp analyze_selection(rulesheet, sheet, selection) do
    with {:ok, required_cells} <- Ruleset.shape_size(selection.value),
         :ok <- require_selection_cells(selection.cells, required_cells),
         {:ok, compatible_placements} <- compatible_shape_placements(rulesheet, sheet, selection),
         {:ok, submit_ready, resolution} <-
           classify_selection(selection.cells, required_cells, compatible_placements) do
      selected = MapSet.new(selection.cells)

      available_cells =
        if resolution == :shape do
          []
        else
          compatible_placements
          |> List.flatten()
          |> Enum.reject(&MapSet.member?(selected, &1))
          |> sort_cells()
        end

      details = %{
        mark: selection.mark,
        value: selection.value,
        required_cells: required_cells,
        cells: selection.cells,
        available_cells: available_cells,
        submit_ready: submit_ready,
        resolution: resolution
      }

      {:ok,
       Map.put(
         details,
         :bonus_options,
         selection_bonus_options(rulesheet, sheet, selection, details)
       )}
    end
  end

  defp require_selection_cells([], _required_cells), do: {:error, :no_legal_placement}

  defp require_selection_cells(cells, required_cells) do
    cond do
      Enum.uniq(cells) != cells -> {:error, :invalid_target}
      length(cells) > required_cells -> {:error, :invalid_shape}
      true -> :ok
    end
  end

  defp compatible_shape_placements(rulesheet, sheet, selection) do
    selected = MapSet.new(selection.cells)

    placements =
      rulesheet
      |> legal_shape_placements(sheet, selection.mark, selection.value)
      |> Enum.filter(&MapSet.subset?(selected, MapSet.new(&1)))

    case selection.cells do
      [cell] ->
        if cell in legal_initial_targets(rulesheet, sheet, selection.mark) do
          {:ok, placements}
        else
          {:error, :invalid_target}
        end

      [_first, _second | _rest] when placements != [] ->
        {:ok, placements}

      _cells ->
        {:error, :no_legal_placement}
    end
  end

  defp classify_selection([_cell], _required_cells, _placements),
    do: {:ok, true, :single}

  defp classify_selection(cells, required_cells, placements) do
    if length(cells) == required_cells and placements != [] do
      {:ok, true, :shape}
    else
      {:ok, false, nil}
    end
  end

  defp turn_marks(rulesheet, sheet) do
    Ruleset.marks()
    |> Map.new(fn mark -> {mark, legal_initial_targets(rulesheet, sheet, mark)} end)
    |> Map.reject(fn {_mark, cells} -> cells == [] end)
    |> Map.new(fn {mark, cells} -> {mark, %{available_cells: cells}} end)
  end

  defp selection_bonus_options(_rulesheet, _sheet, _selection, %{submit_ready: false}),
    do: []

  defp selection_bonus_options(rulesheet, sheet, selection, %{resolution: resolution}) do
    case apply_primary_resolution(rulesheet, sheet, selection, resolution) do
      {:ok, simulated_sheet} ->
        rulesheet
        |> newly_unlocked_bonuses(sheet, simulated_sheet)
        |> Enum.sort_by(&{&1.ref.area, &1.ref.axis, &1.ref.index})

      {:error, _reason} ->
        []
    end
  end

  @doc "Returns every legal transformed placement for a primary mark."
  @spec legal_shape_placements(Sheet.t(), Game.sheet(), Ruleset.mark(), Ruleset.die_value()) :: [
          [Ruleset.cell()]
        ]
  def legal_shape_placements(%Sheet{} = rulesheet, sheet, mark, die_value) do
    if mark in Ruleset.marks() do
      sheet
      |> Ruleset.accessible_areas()
      |> Enum.flat_map(fn area ->
        case Ruleset.shape_placements(rulesheet, area, die_value) do
          {:ok, placements} -> placements
          {:error, :invalid_die_value} -> []
        end
      end)
      |> Enum.filter(&legal_mark_placement?(sheet, mark, &1))
    else
      []
    end
  end

  @doc "Returns every legal initial cell for a primary mark."
  @spec legal_initial_targets(Sheet.t(), Game.sheet(), Ruleset.mark()) :: [Ruleset.cell()]
  def legal_initial_targets(%Sheet{} = rulesheet, sheet, mark) do
    if mark in Ruleset.marks() do
      rulesheet
      |> accessible_cells(sheet)
      |> Enum.filter(&legal_mark_target?(sheet, mark, &1))
      |> sort_cells()
    else
      []
    end
  end

  defp accessible_cells(rulesheet, sheet) do
    sheet
    |> Ruleset.accessible_areas()
    |> Enum.flat_map(&Ruleset.area_cells(rulesheet, &1))
  end

  defp legal_mark_target?(sheet, :tree, cell), do: cell not in sheet.trees

  defp legal_mark_target?(sheet, :koala, cell),
    do: cell in sheet.trees and cell not in sheet.koalas

  defp legal_mark_placement?(sheet, mark, cells) do
    Enum.all?(cells, &legal_mark_target?(sheet, mark, &1))
  end

  defp sort_cells(cells) do
    cells
    |> Enum.uniq()
    |> Enum.sort_by(&{&1.area, &1.row, &1.column})
  end

  defp require_phase(%{phase: phase}, expected) when is_list(expected) do
    if phase in expected, do: :ok, else: {:error, :invalid_phase}
  end

  defp require_phase(%{phase: phase}, phase), do: :ok
  defp require_phase(%{phase: _phase}, _expected), do: {:error, :invalid_phase}

  defp require_actor(%D20.Command{actor_id: actor_id}) when is_player_id(actor_id), do: :ok
  defp require_actor(%D20.Command{}), do: {:error, :invalid_identity}

  defp require_missing_actor(%D20.Command{actor_id: nil}), do: :ok
  defp require_missing_actor(%D20.Command{}), do: {:error, :invalid_identity}

  defp require_player_count_in_range(%Game{players: players} = game, player_id \\ nil) do
    count =
      cond do
        is_nil(player_id) -> map_size(players)
        match?({:ok, _player}, Game.fetch_player(game, player_id)) -> map_size(players)
        true -> map_size(players) + 1
      end

    if count in Ruleset.player_count_range(),
      do: :ok,
      else: {:error, :invalid_player_count}
  end

  defp require_player_status(player, status) do
    case player.status do
      ^status -> :ok
      :submitted -> {:error, :already_submitted}
      _status -> {:error, :invalid_phase}
    end
  end

  defp require_missing_roll(%{roll: nil}), do: :ok
  defp require_missing_roll(%{roll: _roll}), do: {:error, :roll_already_exists}

  defp require_roll(%{roll: nil}), do: {:error, :missing_roll}
  defp require_roll(%{roll: %{value: value}}) when value in 1..6, do: :ok
  defp require_roll(%{roll: _roll}), do: {:error, :missing_roll}

  defp require_submit_ready(%{submit_ready: true}), do: :ok
  defp require_submit_ready(%{submit_ready: false}), do: {:error, :incomplete_turn_selection}

  defp available_volunteer_cost(sheet, value, die_value) do
    with {:ok, needed} <- Ruleset.volunteers_needed(value, die_value),
         true <- Enum.count(sheet.volunteers, &(&1 == :available)) >= needed do
      {:ok, needed}
    else
      {:error, :invalid_die_value} -> {:error, :invalid_die_value}
      false -> {:error, :insufficient_volunteers}
    end
  end

  defp spend_volunteers(sheet, value, die_value) do
    with {:ok, needed} <- available_volunteer_cost(sheet, value, die_value),
         {:ok, volunteers} <- spend_volunteer_slots(sheet.volunteers, needed) do
      {:ok, %{sheet | volunteers: volunteers}}
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

  defp apply_primary_resolution(map, sheet, %{mark: mark, cells: [cell]}, :single) do
    with :ok <- require_one_accessible_area(map, sheet, [cell]) do
      apply_mark(map, sheet, mark, [cell])
    end
  end

  defp apply_primary_resolution(map, sheet, %{mark: mark, value: die_value, cells: cells}, :shape) do
    with {:ok, valid_cells} <- valid_cells(map, cells),
         :ok <- require_unique_targets(cells),
         :ok <- require_shape(map, valid_cells, die_value),
         :ok <- require_one_accessible_area(map, sheet, valid_cells) do
      apply_mark(map, sheet, mark, cells)
    end
  end

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

  defp apply_mark(_map, sheet, :tree, cells) do
    if Enum.any?(cells, &(&1 in sheet.trees)) do
      {:error, :occupied}
    else
      {:ok, %{sheet | trees: add_refs(sheet.trees, cells)}}
    end
  end

  defp apply_mark(map, sheet, :koala, cells) do
    Enum.reduce_while(cells, {:ok, sheet}, fn cell, {:ok, sheet} ->
      with :ok <- require_koala_target(map, sheet, cell) do
        {:cont, {:ok, %{sheet | koalas: add_refs(sheet.koalas, [cell])}}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
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

  defp apply_bonus_actions(map, original_sheet, sheet, bonus_actions) do
    legacy_bonus_refs = unlocked_bonus_refs(map, original_sheet)

    Enum.reduce_while(bonus_actions, {:ok, sheet}, fn bonus_action, {:ok, sheet} ->
      case apply_bonus_action(map, sheet, legacy_bonus_refs, bonus_action) do
        {:ok, sheet} -> {:cont, {:ok, sheet}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, sheet} -> {:ok, resolve_unclaimed_bonuses(map, sheet)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp apply_bonus_action(map, sheet, legacy_bonus_refs, %{bonus: bonus_ref, action: action}) do
    with {:ok, bonus_entry} <- fetch_unlocked_bonus(map, sheet, bonus_ref),
         false <- MapSet.member?(legacy_bonus_refs, bonus_ref(bonus_entry.ref)),
         :ok <- require_bonus_action_match(bonus_entry.bonus, action),
         {:ok, sheet} <- apply_bonus_effect(map, sheet, bonus_entry, action) do
      {:ok, put_bonus_resolution(sheet, bonus_ref, :resolved)}
    else
      true -> {:error, :invalid_bonus}
      {:error, reason} -> {:error, reason}
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
      apply_mark(rulesheet, player_sheet, :tree, [cell])
    end
  end

  defp apply_bonus_effect(%Sheet{} = rulesheet, player_sheet, _bonus, %{
         kind: :koala,
         target_cell: cell
       }) do
    with :ok <- require_one_accessible_area(rulesheet, player_sheet, [cell]) do
      apply_mark(rulesheet, player_sheet, :koala, [cell])
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

  @doc "Returns unresolved bonuses whose requirements are satisfied by the player sheet."
  @spec unlocked_bonuses(Sheet.t(), Game.sheet()) :: [Ruleset.bonus_entry()]
  def unlocked_bonuses(map, player_sheet) do
    koalas = MapSet.new(player_sheet.koalas)

    map
    |> Ruleset.bonuses()
    |> Enum.filter(fn bonus_entry ->
      cells = Ruleset.line_cells(map, bonus_entry.ref)

      not bonus_resolved?(player_sheet, bonus_entry.ref) and cells != [] and
        Enum.all?(cells, &MapSet.member?(koalas, &1))
    end)
  end

  defp newly_unlocked_bonuses(map, original_sheet, sheet) do
    previous_refs = unlocked_bonus_refs(map, original_sheet)

    map
    |> unlocked_bonuses(sheet)
    |> Enum.reject(&MapSet.member?(previous_refs, bonus_ref(&1.ref)))
  end

  defp unlocked_bonus_refs(map, sheet) do
    map
    |> unlocked_bonuses(sheet)
    |> MapSet.new(&bonus_ref(&1.ref))
  end

  defp resolve_unclaimed_bonuses(map, sheet) do
    map
    |> unlocked_bonuses(sheet)
    |> Enum.reduce(sheet, &put_bonus_resolution(&2, &1.ref, :resolved))
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
