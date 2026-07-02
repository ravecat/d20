defmodule D20.KoalaRescueClub.Projection do
  @moduledoc """
  Renders caller-specific Koala Rescue Club projection fields.
  """

  alias D20.Accounts.Scope
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Permission
  alias D20.KoalaRescueClub.Ruleset
  alias D20.Sessions.Session

  @spec render(Scope.t(), Session.t()) :: map()
  def render(%Scope{} = scope, %Session{game: %Game{}} = session) do
    actor_id = scope.actor.id
    permissions = Permission.permissions(scope, session)
    sheet_projection = render_sheet_projection(session.game, actor_id)

    session
    |> Map.from_struct()
    |> Map.merge(%{
      self: actor_id,
      permissions: permissions,
      available_turn_actions: [],
      sheet_projection: sheet_projection
    })
  end

  defp render_sheet_projection(%Game{} = game, actor_id) do
    with {:ok, rulesheet} <- Ruleset.sheet(game.sheet),
         %{sheet: player_sheet} <- Map.get(game.players, actor_id) do
      %{areas: render_areas(rulesheet, player_sheet)}
    else
      _missing -> nil
    end
  end

  defp render_areas(rulesheet, player_sheet) do
    Map.new(rulesheet.areas, fn {area_id, _area} ->
      {area_id,
       %{
         matrix: render_matrix(rulesheet, player_sheet, area_id),
         row_bonuses: render_line_bonuses(rulesheet.rows, player_sheet, area_id),
         column_bonuses: render_line_bonuses(rulesheet.columns, player_sheet, area_id)
       }}
    end)
  end

  defp render_matrix(rulesheet, player_sheet, area_id) do
    cells = Ruleset.area_cells(rulesheet, area_id)
    max_row = cells |> Enum.map(& &1.r) |> Enum.max()
    max_column = cells |> Enum.map(& &1.q) |> Enum.max()
    by_coordinate = Map.new(cells, &{{&1.r, &1.q}, &1})

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
    cell_ref = Ruleset.cell_ref(cell)

    %{tree: cell_ref in player_sheet.trees, koala: cell_ref in player_sheet.koalas}
  end

  defp render_line_bonuses(lines, player_sheet, area_id) do
    area_lines = lines |> Map.values() |> Enum.filter(&(&1.area_id == area_id))

    max_index = area_lines |> Enum.map(& &1.index) |> Enum.max(fn -> -1 end)
    by_index = Map.new(area_lines, &{&1.index, &1})

    if max_index < 0 do
      []
    else
      for index <- 0..max_index do
        by_index
        |> Map.get(index)
        |> render_bonus(player_sheet)
      end
    end
  end

  defp render_bonus(nil, _player_sheet), do: nil
  defp render_bonus(%{bonus: nil}, _player_sheet), do: nil

  defp render_bonus(%{bonus: bonus} = line, player_sheet) do
    %{kind: bonus.kind, state: bonus_state(line, player_sheet)}
    |> maybe_put(:to_area, Map.get(bonus, :target_area_id))
    |> maybe_put(:target_id, Map.get(bonus, :target_id))
  end

  defp bonus_state(%{bonus: bonus} = line, player_sheet) do
    cond do
      bonus_resolved?(player_sheet, bonus.ref) -> :resolved
      line_unlocked?(line, player_sheet) -> :unlocked
      true -> :locked
    end
  end

  defp bonus_resolved?(player_sheet, bonus_ref) do
    Enum.any?(player_sheet.bonuses, &(bonus_ref(&1) == bonus_ref))
  end

  defp line_unlocked?(line, player_sheet) do
    koala_cell_ids = player_sheet.koalas |> Enum.map(&Ruleset.cell_id/1) |> MapSet.new()

    Enum.all?(line.cell_ids, &MapSet.member?(koala_cell_ids, &1))
  end

  defp bonus_ref(%{area: area, axis: axis, index: index}) do
    %{area: area, axis: axis, index: index}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
