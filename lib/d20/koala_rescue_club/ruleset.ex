defmodule D20.KoalaRescueClub.Ruleset do
  @moduledoc """
  Static Koala Rescue Club rules and sheet definitions.

  Shared game rules live here when they do not depend on mutable game state.
  Sheet-specific board data is exposed through `Sheet.t()` so each supported
  sheet has the same attribute shape: areas, bonuses, hospitals, skybridges,
  badges, solo ratings, and starting volunteers.
  """

  alias D20.KoalaRescueClub.Ruleset.Dharug
  alias D20.KoalaRescueClub.Ruleset.Sheet
  alias D20.KoalaRescueClub.Ruleset.Yugambeh

  @player_count_range 1..99
  @turns_per_round 15
  @turn_range 1..30
  @scoring_turns [15, 30]
  @die_value_range 1..6
  @volunteer 6

  @shapes %{
    1 => [{0, 0}, {1, 0}],
    2 => [{0, 0}, {1, 0}],
    3 => [{0, 0}, {1, 0}, {2, 0}],
    4 => [{0, 0}, {1, 0}, {0, 1}],
    5 => [{0, 0}, {1, 0}, {2, 0}, {0, 1}],
    6 => [{0, 0}, {1, 0}, {2, 0}, {1, 1}]
  }

  @sheet_modules %{dharug: Dharug, yugambeh: Yugambeh}
  @sheets [:dharug, :yugambeh]

  @type id :: :dharug | :yugambeh
  @type area :: atom()
  @type badge :: atom()
  @type cell :: %{
          required(:area) => area(),
          required(:row) => non_neg_integer(),
          required(:column) => non_neg_integer()
        }
  @type line_ref :: %{
          required(:area) => area(),
          required(:axis) => :row | :column,
          required(:index) => non_neg_integer()
        }
  @type bonus :: %{
          required(:ref) => line_ref(),
          required(:kind) => :tree | :koala | :volunteer | :hospital | :skybridge,
          optional(:target_area) => area(),
          optional(:target_id) => String.t()
        }
  @type line :: %{
          required(:ref) => line_ref(),
          required(:area) => area(),
          required(:axis) => :row | :column,
          required(:index) => non_neg_integer(),
          required(:cells) => [cell()],
          required(:bonus) => bonus() | nil
        }
  @type rank ::
          :junior_club_member
          | :club_secretary
          | :club_treasurer
          | :vice_president
          | :president
  @type solo_rating :: %{required(:rank) => rank(), required(:range) => Range.t()}
  @type hospital :: %{
          required(:filled) => non_neg_integer(),
          required(:size) => pos_integer(),
          required(:score) => integer(),
          optional(:penalty) => integer() | nil
        }

  @doc "Returns the supported player count range."
  @spec player_count_range() :: Range.t()
  def player_count_range, do: @player_count_range

  @doc "Returns the 1-based round for a valid turn."
  @spec round(term()) :: {:ok, pos_integer()} | {:error, :invalid_turn}
  def round(turn) when is_integer(turn) and turn in @turn_range do
    {:ok, div(turn - 1, @turns_per_round) + 1}
  end

  def round(_turn), do: {:error, :invalid_turn}

  @doc "Returns true when the given turn triggers round scoring."
  @spec scoring_turn?(term()) :: boolean()
  def scoring_turn?(turn), do: turn in @scoring_turns

  @doc "Returns true when the given turn is the final turn."
  @spec final_turn?(term()) :: boolean()
  def final_turn?(turn), do: turn == Enum.max(@turn_range)

  @doc "Returns the minimum volunteers needed to change one die face into another."
  @spec volunteers_needed(term(), term()) ::
          {:ok, non_neg_integer()} | {:error, :invalid_die_value}
  def volunteers_needed(from, to) when from in @die_value_range and to in @die_value_range do
    distance = abs(to - from)
    {:ok, min(distance, Enum.count(@die_value_range) - distance)}
  end

  def volunteers_needed(_from, _to), do: {:error, :invalid_die_value}

  @doc "Returns the maximum number of volunteer circles on the sheet."
  @spec volunteer() :: pos_integer()
  def volunteer, do: @volunteer

  @doc "Returns supported sheet ids."
  @spec sheets() :: [id()]
  def sheets, do: @sheets

  @doc "Returns a supported sheet definition or raises when the sheet is unknown."
  @spec sheet!(id()) :: Sheet.t()
  def sheet!(sheet), do: @sheet_modules |> Map.fetch!(sheet) |> Sheet.from_module()

  @doc "Returns all cells for one area."
  @spec area_cells(Sheet.t(), area()) :: [cell()]
  def area_cells(%Sheet{areas: areas}, area) do
    case Map.fetch(areas, area) do
      {:ok, area_sheet} ->
        area_sheet.rows
        |> Enum.with_index()
        |> Enum.flat_map(fn {row, index} ->
          Enum.map(row, &%{area: area, row: index, column: &1})
        end)

      :error ->
        []
    end
  end

  @doc "Returns the canonical internal key for a cell coordinate."
  @spec cell_key(cell()) :: cell()
  def cell_key(%{area: area, row: row, column: column}) do
    Sheet.cell_key(area, column, row)
  end

  @doc "Returns the player-state cell coordinate for a sheet cell."
  @spec cell(map()) :: cell()
  def cell(%{area: area, row: row, column: column}) do
    %{area: area, row: row, column: column}
  end

  def cell(%{area: area, q: column, r: row}) do
    %{area: area, row: row, column: column}
  end

  @doc "Returns true when the cell exists on the sheet."
  @spec cell_exists?(Sheet.t(), cell()) :: boolean()
  def cell_exists?(%Sheet{} = sheet, %{area: area} = cell) do
    cell in area_cells(sheet, area)
  end

  @doc "Returns all row or column lines for one area."
  @spec area_lines(Sheet.t(), area(), :row | :column) :: [line()]
  def area_lines(%Sheet{areas: areas} = sheet, area, axis) when axis in [:row, :column] do
    case Map.fetch(areas, area) do
      {:ok, area_sheet} -> lines(sheet, area, axis, area_sheet)
      :error -> []
    end
  end

  @doc "Returns all lines that carry bonuses."
  @spec bonus_lines(Sheet.t()) :: [line()]
  def bonus_lines(%Sheet{areas: areas} = sheet) do
    areas
    |> Map.keys()
    |> Enum.flat_map(fn area ->
      area_lines(sheet, area, :row) ++ area_lines(sheet, area, :column)
    end)
    |> Enum.filter(& &1.bonus)
  end

  @doc "Returns the bonus attached to a reference."
  @spec bonus(Sheet.t(), line_ref()) :: {:ok, bonus()} | {:error, :invalid_bonus}
  def bonus(%Sheet{} = sheet, %{axis: axis} = ref) when axis in [:row, :column] do
    case find_bonus(sheet, ref) do
      nil -> {:error, :invalid_bonus}
      bonus -> {:ok, bonus}
    end
  end

  def bonus(%Sheet{}, _ref), do: {:error, :invalid_bonus}

  @doc "Returns all areas accessible for a sheet through claimed skybridges."
  @spec accessible_areas(Sheet.t(), map()) :: [atom()]
  def accessible_areas(sheet, player_sheet) do
    initial =
      sheet.areas
      |> Enum.filter(fn {_id, area} -> area.access end)
      |> Enum.map(fn {id, _area} -> id end)
      |> MapSet.new()

    claimed = MapSet.new(player_sheet.skybridges)

    sheet.skybridges
    |> Enum.filter(&MapSet.member?(claimed, &1))
    |> expand_access(initial)
    |> MapSet.to_list()
    |> Enum.sort()
  end

  @doc "Returns true when all cells in an area have circled trees."
  @spec trees_complete?(Sheet.t(), map(), atom()) :: boolean()
  def trees_complete?(map, player_sheet, area) do
    complete_area?(map, player_sheet.trees, area)
  end

  @doc "Returns true when all cells in an area have circled koalas."
  @spec koalas_complete?(Sheet.t(), map(), atom()) :: boolean()
  def koalas_complete?(map, player_sheet, area) do
    complete_area?(map, player_sheet.koalas, area)
  end

  @doc "Returns true when the target cells match a die shape under rotation or flip."
  @spec shape_match?(Sheet.t(), [cell()], pos_integer()) :: boolean()
  def shape_match?(%Sheet{} = sheet, cell_keys, die_value) do
    with {:ok, shape} <- shape_for(die_value),
         true <- length(cell_keys) == length(shape),
         {:ok, coords} <- target_coords(sheet, cell_keys) do
      normalized = normalize_offsets(coords)

      die_value
      |> transformed_shapes()
      |> Enum.any?(&(normalize_offsets(&1) == normalized))
    else
      _ -> false
    end
  end

  @doc "Returns the solo rating for a sheet and score."
  @spec solo_rating(Sheet.t(), term()) :: {:ok, solo_rating()} | {:error, :invalid_score}
  def solo_rating(%Sheet{solo_ratings: solo_ratings}, score)
      when is_integer(score) and score >= 0 do
    case Enum.find(solo_ratings, &score_in_rating?(score, &1)) do
      {rank, range} -> {:ok, %{rank: rank, range: range}}
      nil -> {:error, :invalid_score}
    end
  end

  def solo_rating(_sheet, _score), do: {:error, :invalid_score}

  @doc "Scores one hospital."
  @spec score_hospital(hospital()) :: {:ok, integer()} | {:error, :invalid_hospital}
  def score_hospital(hospital) do
    with :ok <- validate_hospital(hospital) do
      {:ok, score_hospital_by_penalty(hospital)}
    end
  end

  defp shape_for(value) when value in @die_value_range, do: {:ok, Map.fetch!(@shapes, value)}
  defp shape_for(_value), do: {:error, :invalid_die_value}

  defp shape_offsets(value), do: Map.fetch!(@shapes, value)

  defp transformed_shapes(die_value) do
    die_value
    |> shape_offsets()
    |> transforms()
    |> Enum.uniq()
  end

  defp expand_access(skybridges, accessible) do
    next =
      Enum.reduce(skybridges, accessible, fn skybridge, accessible ->
        if MapSet.member?(accessible, skybridge.from) do
          MapSet.put(accessible, skybridge.to)
        else
          accessible
        end
      end)

    if MapSet.equal?(next, accessible), do: next, else: expand_access(skybridges, next)
  end

  defp complete_area?(map, cell_keys, area) do
    required = map |> area_cells(area) |> MapSet.new()

    required != MapSet.new() and MapSet.subset?(required, MapSet.new(cell_keys))
  end

  defp target_coords(sheet, cell_keys) do
    Enum.reduce_while(cell_keys, {:ok, []}, fn cell_key, {:ok, coords} ->
      if cell_exists?(sheet, cell_key) do
        {:cont, {:ok, [{cell_key.column, cell_key.row} | coords]}}
      else
        {:halt, {:error, :unknown_cell}}
      end
    end)
  end

  defp lines(sheet, area, :row, area_sheet) do
    area_sheet.rows
    |> Enum.with_index()
    |> Enum.map(fn {columns, index} ->
      cells = Enum.map(columns, &%{area: area, row: index, column: &1})
      line(sheet, area, :row, index, cells)
    end)
  end

  defp lines(sheet, area, :column, area_sheet) do
    area_sheet
    |> column_range()
    |> Enum.map(fn index ->
      cells =
        area_sheet.rows
        |> Enum.with_index()
        |> Enum.filter(fn {columns, _row} -> index in columns end)
        |> Enum.map(fn {_columns, row} -> %{area: area, row: row, column: index} end)

      line(sheet, area, :column, index, cells)
    end)
  end

  defp column_range(%{rows: rows}) do
    max_column = rows |> Enum.flat_map(&Enum.to_list/1) |> Enum.max(fn -> -1 end)

    if max_column < 0, do: [], else: 0..max_column
  end

  defp line(sheet, area, axis, index, cells) do
    ref = %{area: area, axis: axis, index: index}
    %{ref: ref, area: area, axis: axis, index: index, cells: cells, bonus: find_bonus(sheet, ref)}
  end

  defp find_bonus(%Sheet{bonuses: bonuses}, ref) do
    bonuses
    |> Map.get(ref.area, [])
    |> Enum.find(&(&1.axis == ref.axis and &1.index == ref.index))
    |> case do
      nil -> nil
      bonus -> expand_bonus(ref, bonus.bonus)
    end
  end

  defp expand_bonus(ref, {:skybridge, target_area}),
    do: %{ref: ref, kind: :skybridge, target_area: target_area}

  defp expand_bonus(ref, {kind, target_id}), do: %{ref: ref, kind: kind, target_id: target_id}
  defp expand_bonus(ref, kind), do: %{ref: ref, kind: kind}

  defp transforms(offsets) do
    rotations =
      Enum.reduce(1..4, [offsets], fn _step, [previous | _rest] = acc ->
        [rotate(previous) | acc]
      end)

    flipped = Enum.map(offsets, fn {x, y} -> {-x, y} end)

    rotations ++
      Enum.reduce(1..4, [flipped], fn _step, [previous | _rest] = acc ->
        [rotate(previous) | acc]
      end)
  end

  defp rotate(offsets), do: Enum.map(offsets, fn {x, y} -> {-y, x} end)

  defp normalize_offsets(offsets) do
    min_x = offsets |> Enum.map(&elem(&1, 0)) |> Enum.min()
    min_y = offsets |> Enum.map(&elem(&1, 1)) |> Enum.min()

    offsets
    |> Enum.map(fn {x, y} -> {x - min_x, y - min_y} end)
    |> Enum.sort()
  end

  defp score_in_rating?(score, {_rank, range}), do: score in range

  defp validate_hospital(%{filled: filled, size: size, score: score} = hospital)
       when is_integer(filled) and filled >= 0 and is_integer(size) and size > 0 and
              is_integer(score) do
    validate_hospital_penalty(hospital)
  end

  defp validate_hospital(_hospital), do: {:error, :invalid_hospital}

  defp validate_hospital_penalty(hospital) do
    case Map.fetch(hospital, :penalty) do
      :error -> :ok
      {:ok, nil} -> :ok
      {:ok, penalty} when is_integer(penalty) -> :ok
      {:ok, _penalty} -> {:error, :invalid_hospital}
    end
  end

  defp score_hospital_by_penalty(%{filled: filled, size: size, score: score} = hospital) do
    cond do
      filled == 0 -> 0
      filled >= size -> score
      true -> Map.get(hospital, :penalty) || 0
    end
  end
end
