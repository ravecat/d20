defmodule D20.KoalaRescueClub.Projection do
  @moduledoc """
  Renders caller-specific Koala Rescue Club projection fields.
  """

  alias D20.Accounts.Scope
  alias D20.Command
  alias D20.KoalaRescueClub.Command, as: KoalaCommand
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Permission
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset
  alias D20.Sessions.Session

  @shape_actions ["plant_trees", "rehome_koalas"]
  @single_actions ["circle_tree", "circle_koala"]
  @primary_actions @shape_actions ++ @single_actions

  @type options :: %{
          optional(String.t()) => %{
            required(:volunteer_cost) => non_neg_integer(),
            required(:actions) => %{
              optional(String.t()) => %{required(:available_cells) => [Ruleset.cell()]}
            }
          }
        }
  @type selection :: %{
          required(:action) => String.t(),
          required(:die_value) => 1..6,
          required(:volunteers_used) => non_neg_integer(),
          required(:required_cells) => pos_integer(),
          required(:selected_cells) => [Ruleset.cell()],
          required(:available_cells) => [Ruleset.cell()],
          required(:complete) => boolean(),
          required(:bonus_options) => [Ruleset.bonus_entry()]
        }
  @type cell :: %{required(:tree) => boolean(), required(:koala) => boolean()}
  @type area :: %{required(:accessible) => boolean(), required(:rows) => [[cell() | nil]]}
  @type bonus_kind :: :tree | :koala | :volunteer | :hospital | :skybridge
  @type bonus_details :: %{
          required(:kind) => bonus_kind(),
          optional(:from) => Ruleset.area(),
          optional(:to) => Ruleset.area()
        }
  @type bonus :: %{
          required(:ref) => Ruleset.bonus_ref(),
          required(:state) => :locked | :unlocked | :resolved,
          required(:bonus) => bonus_details()
        }
  @type sheet :: %{
          required(:volunteers) => [:available | :locked | :used],
          required(:hospitals) => %{optional(atom()) => Ruleset.hospital()},
          required(:skybridges) => [Game.skybridge()],
          required(:bonuses) => [bonus()],
          required(:areas) => %{optional(Ruleset.area()) => area()}
        }
  @type t :: %{
          required(:id) => Session.id(),
          required(:phase) => Session.phase(),
          required(:owner_id) => Session.player_id(),
          required(:members) => Session.members(),
          required(:self) => Game.player_id(),
          required(:permissions) => Permission.t(),
          required(:options) => options(),
          required(:game) => Game.state(sheet())
        }

  @spec render(Scope.t(), Session.t()) :: t()
  def render(%Scope{} = scope, %Session{game: %Game{} = game} = session) do
    actor_id = scope.actor.id
    permissions = Permission.permissions(scope, session)
    rulesheet = Ruleset.sheet!(game.sheet)

    %{
      id: session.id,
      phase: session.phase,
      owner_id: session.owner_id,
      members: session.members,
      self: actor_id,
      permissions: permissions,
      options: render_options(game, actor_id),
      game: render_game(rulesheet, game)
    }
  end

  @doc "Projects a complete client-owned shape draft against the current committed game."
  @spec project_turn_selection(Scope.t(), Session.t(), map()) ::
          {:ok, selection()} | {:error, KoalaCommand.reason() | Rules.reason()}
  def project_turn_selection(
        %Scope{actor: %{id: actor_id}},
        %Session{game: %Game{} = game},
        attrs
      ) do
    command = %Command{event: "project_turn_selection", actor_id: actor_id, attrs: attrs}

    with {:ok, command} <- KoalaCommand.validate(command),
         {:ok, player} <- fetch_player(game, actor_id),
         true <- Rules.submit_allowed?(game, actor_id),
         :ok <- validate_volunteer_cost(game, player.sheet, command.attrs),
         {:ok, selection} <- render_selection(game, player.sheet, command.attrs) do
      {:ok, selection}
    else
      :error -> {:error, :not_joined}
      false -> {:error, :invalid_phase}
      {:error, reason} -> {:error, reason}
    end
  end

  defp render_options(game, actor_id) do
    if Rules.submit_allowed?(game, actor_id) do
      player_sheet = game.players[actor_id].sheet
      rulesheet = Ruleset.sheet!(game.sheet)
      available_volunteers = Enum.count(player_sheet.volunteers, &(&1 == :available))

      Map.new(1..6, fn die_value ->
        {:ok, volunteer_cost} = Ruleset.volunteers_needed(game.roll.value, die_value)

        actions =
          if volunteer_cost <= available_volunteers do
            render_turn_actions(rulesheet, player_sheet, die_value)
          else
            %{}
          end

        {Integer.to_string(die_value), %{volunteer_cost: volunteer_cost, actions: actions}}
      end)
    else
      %{}
    end
  end

  defp render_selection(game, player_sheet, attrs) do
    with {:ok, required_cells} <- Ruleset.shape_size(attrs.die_value),
         :ok <- require_unique_cells(attrs.selected_cells) do
      selected = MapSet.new(attrs.selected_cells)

      compatible_placements =
        game.sheet
        |> Ruleset.sheet!()
        |> Rules.legal_shape_placements(player_sheet, attrs.action, attrs.die_value)
        |> Enum.filter(&MapSet.subset?(selected, MapSet.new(&1)))

      if compatible_placements == [] do
        {:error, :invalid_target}
      else
        complete =
          MapSet.size(selected) == required_cells and
            Enum.any?(compatible_placements, &(MapSet.new(&1) == selected))

        available_cells =
          if complete do
            []
          else
            compatible_placements
            |> List.flatten()
            |> Enum.reject(&MapSet.member?(selected, &1))
            |> sort_cells()
          end

        {:ok,
         %{
           action: attrs.action,
           die_value: attrs.die_value,
           volunteers_used: attrs.volunteers_used,
           required_cells: required_cells,
           selected_cells: sort_cells(attrs.selected_cells),
           available_cells: available_cells,
           complete: complete,
           bonus_options: render_selection_bonus_options(game, player_sheet, attrs, complete)
         }}
      end
    end
  end

  defp render_turn_actions(rulesheet, player_sheet, die_value) do
    Map.new(@primary_actions, fn action ->
      {action, render_turn_action(rulesheet, player_sheet, action, die_value)}
    end)
    |> Map.reject(fn {_action, option} -> is_nil(option) end)
  end

  defp render_turn_action(rulesheet, player_sheet, action, die_value)
       when action in @shape_actions do
    available_cells =
      rulesheet
      |> Rules.legal_shape_placements(player_sheet, action, die_value)
      |> List.flatten()
      |> sort_cells()

    if available_cells == [], do: nil, else: %{available_cells: available_cells}
  end

  defp render_turn_action(rulesheet, player_sheet, action, _die_value)
       when action in @single_actions do
    case Rules.legal_single_targets(rulesheet, player_sheet, action) do
      [] -> nil
      available_cells -> %{available_cells: available_cells}
    end
  end

  defp render_selection_bonus_options(_game, _sheet, _attrs, false), do: []

  defp render_selection_bonus_options(game, sheet, attrs, true) do
    rulesheet = Ruleset.sheet!(game.sheet)

    case Rules.apply_primary_action(
           rulesheet,
           sheet,
           attrs.action,
           %{target_cells: attrs.selected_cells},
           attrs.die_value
         ) do
      {:ok, simulated_sheet} ->
        rulesheet
        |> Rules.unlocked_bonuses(simulated_sheet)
        |> Enum.sort_by(&{&1.ref.area, &1.ref.axis, &1.ref.index})

      {:error, _reason} ->
        []
    end
  end

  defp fetch_player(game, actor_id), do: Map.fetch(game.players, actor_id)

  defp validate_volunteer_cost(game, sheet, attrs) do
    with {:ok, needed} <- Ruleset.volunteers_needed(game.roll.value, attrs.die_value),
         true <- needed == attrs.volunteers_used,
         true <- Enum.count(sheet.volunteers, &(&1 == :available)) >= needed do
      :ok
    else
      {:error, :invalid_die_value} -> {:error, :invalid_die_value}
      false -> {:error, :insufficient_volunteers}
    end
  end

  defp require_unique_cells(cells) do
    if Enum.uniq(cells) == cells, do: :ok, else: {:error, :invalid_target}
  end

  defp sort_cells(cells) do
    cells
    |> Enum.uniq()
    |> Enum.sort_by(&{&1.area, &1.row, &1.column})
  end

  defp render_game(rulesheet, %Game{} = game) do
    %{
      sheet: game.sheet,
      phase: game.phase,
      round: game.round,
      turn: game.turn,
      order: game.order,
      players: render_players(rulesheet, game.players),
      roll: game.roll,
      scores: game.scores
    }
  end

  defp render_players(rulesheet, players) do
    Map.new(players, fn {player_id, player} -> {player_id, render_player(rulesheet, player)} end)
  end

  defp render_player(rulesheet, player) do
    %{
      status: player.status,
      sheet: render_sheet(rulesheet, player.sheet),
      badges: player.badges,
      rounds: player.rounds
    }
  end

  defp render_sheet(rulesheet, player_sheet) do
    accessible_areas = Ruleset.accessible_areas(player_sheet)

    %{
      volunteers: player_sheet.volunteers,
      hospitals: render_hospitals(rulesheet, player_sheet),
      skybridges: player_sheet.skybridges,
      bonuses: render_bonuses(rulesheet, player_sheet),
      areas: render_areas(rulesheet, player_sheet, accessible_areas)
    }
  end

  defp render_areas(rulesheet, player_sheet, accessible_areas) do
    Map.new(rulesheet.areas, fn {area, _area} ->
      {area,
       %{accessible: area in accessible_areas, rows: render_rows(rulesheet, player_sheet, area)}}
    end)
  end

  defp render_rows(rulesheet, player_sheet, area) do
    cells = Ruleset.area_cells(rulesheet, area)
    max_row = cells |> Enum.map(& &1.row) |> Enum.max()
    max_column = cells |> Enum.map(& &1.column) |> Enum.max()
    by_coordinate = Map.new(cells, &{{&1.row, &1.column}, &1})

    for row <- 0..max_row do
      for column <- 0..max_column do
        case Map.get(by_coordinate, {row, column}) do
          nil -> nil
          cell -> render_cell(player_sheet, cell)
        end
      end
    end
  end

  defp render_cell(player_sheet, cell) do
    %{tree: cell in player_sheet.trees, koala: cell in player_sheet.koalas}
  end

  defp render_hospitals(rulesheet, player_sheet) do
    Map.new(rulesheet.hospitals, fn {id, hospital} ->
      {id,
       hospital
       |> Map.take([:size, :score, :penalty])
       |> Map.put(:filled, Map.get(player_sheet.hospitals, id, 0))}
    end)
  end

  defp render_bonuses(rulesheet, player_sheet) do
    rulesheet
    |> Ruleset.bonuses()
    |> Enum.sort_by(&{&1.ref.area, &1.ref.axis, &1.ref.index})
    |> Enum.map(&render_bonus(rulesheet, &1, player_sheet))
  end

  defp render_bonus(rulesheet, %{ref: ref, bonus: bonus}, player_sheet) do
    %{
      ref: ref,
      state: bonus_state(rulesheet, ref, player_sheet),
      bonus: render_bonus_details(ref, bonus)
    }
  end

  defp render_bonus_details(%{area: from}, %{kind: :skybridge, to: to}) do
    %{kind: :skybridge, from: from, to: to}
  end

  defp render_bonus_details(_ref, %{kind: kind}), do: %{kind: kind}

  defp bonus_state(rulesheet, bonus_ref, player_sheet) do
    cond do
      bonus_resolved?(player_sheet, bonus_ref) -> :resolved
      bonus_unlocked?(rulesheet, bonus_ref, player_sheet) -> :unlocked
      true -> :locked
    end
  end

  defp bonus_resolved?(player_sheet, bonus_ref) do
    Enum.any?(player_sheet.bonuses, &(bonus_ref(&1) == bonus_ref))
  end

  defp bonus_unlocked?(rulesheet, bonus_ref, player_sheet) do
    koalas = MapSet.new(player_sheet.koalas)
    cells = Ruleset.line_cells(rulesheet, bonus_ref)

    cells != [] and Enum.all?(cells, &MapSet.member?(koalas, &1))
  end

  defp bonus_ref(%{area: area, axis: axis, index: index}) do
    %{area: area, axis: axis, index: index}
  end
end
