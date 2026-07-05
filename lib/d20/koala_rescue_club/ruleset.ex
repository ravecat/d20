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
  @round_end_turns [15, 30]
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

  @type id :: :dharug | :yugambeh
  @type area :: atom()
  @type badge :: atom()
  @type cell :: %{
          required(:area) => area(),
          required(:row) => non_neg_integer(),
          required(:column) => non_neg_integer()
        }
  @type bonus_ref :: %{
          required(:area) => area(),
          required(:axis) => :row | :column,
          required(:index) => non_neg_integer()
        }
  @type bonus :: %{
          required(:kind) => :tree | :koala | :volunteer | :hospital | :skybridge,
          optional(:to) => area()
        }
  @type bonus_entry :: %{required(:ref) => bonus_ref(), required(:bonus) => bonus()}
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

  @doc "Returns true when the given turn ends a round."
  @spec round_end_turn?(term()) :: boolean()
  def round_end_turn?(turn), do: turn in @round_end_turns

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
  def sheets, do: @sheet_modules |> Map.keys() |> Enum.sort()

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

  @doc "Returns true when the cell exists on the sheet."
  @spec cell_exists?(Sheet.t(), cell()) :: boolean()
  def cell_exists?(%Sheet{} = sheet, %{area: area} = cell) do
    cell in area_cells(sheet, area)
  end

  @doc "Returns all bonuses placed on sheet lines."
  @spec bonuses(Sheet.t()) :: [bonus_entry()]
  def bonuses(%Sheet{bonuses: bonuses}) do
    Enum.flat_map(bonuses, fn {area, area_bonuses} ->
      Enum.map(area_bonuses, fn %{axis: axis, index: index, bonus: bonus} ->
        %{ref: %{area: area, axis: axis, index: index}, bonus: bonus}
      end)
    end)
  end

  @doc "Returns all cells in a row or column reference."
  @spec line_cells(Sheet.t(), bonus_ref()) :: [cell()]
  def line_cells(%Sheet{areas: areas}, %{area: area, axis: :row, index: index})
      when is_integer(index) and index >= 0 do
    case Map.fetch(areas, area) do
      {:ok, area_sheet} ->
        area_sheet.rows |> Enum.at(index, []) |> Enum.map(&%{area: area, row: index, column: &1})

      :error ->
        []
    end
  end

  def line_cells(%Sheet{areas: areas}, %{area: area, axis: :column, index: index})
      when is_integer(index) and index >= 0 do
    case Map.fetch(areas, area) do
      {:ok, area_sheet} ->
        area_sheet.rows
        |> Enum.with_index()
        |> Enum.filter(fn {columns, _row} -> index in columns end)
        |> Enum.map(fn {_columns, row} -> %{area: area, row: row, column: index} end)

      :error ->
        []
    end
  end

  def line_cells(%Sheet{}, _ref), do: []

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
  def shape_match?(%Sheet{} = sheet, cells, die_value) do
    with {:ok, shape} <- shape_for(die_value),
         true <- length(cells) == length(shape),
         {:ok, coords} <- target_coords(sheet, cells) do
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

  defp complete_area?(map, cells, area) do
    required = map |> area_cells(area) |> MapSet.new()

    required != MapSet.new() and MapSet.subset?(required, MapSet.new(cells))
  end

  defp target_coords(sheet, cells) do
    Enum.reduce_while(cells, {:ok, []}, fn cell, {:ok, coords} ->
      if cell_exists?(sheet, cell) do
        {:cont, {:ok, [{cell.column, cell.row} | coords]}}
      else
        {:halt, {:error, :unknown_cell}}
      end
    end)
  end

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
