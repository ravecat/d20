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
      game: render_game(rulesheet, game)
    }
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
