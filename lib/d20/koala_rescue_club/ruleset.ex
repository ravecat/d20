defmodule D20.KoalaRescueClub.Ruleset do
  @moduledoc """
  Static Koala Rescue Club ruleset data.

  Keep game-wide facts here when they can be answered without mutable game
  state: turn and round limits, die shapes, volunteer die adjustment, scoring
  helpers, and sheet-specific rule differences.

  The supplied PDFs describe rules and sheet-specific differences, but not a
  machine-readable sheet geometry for areas, tree cells, koala cells, row and
  column bonuses, badge requirements, or skybridge graph edges. Those
  coordinates should be added separately before a full game reducer validates
  placements.
  """

  alias D20.KoalaRescueClub.Ruleset.Dharug
  alias D20.KoalaRescueClub.Ruleset.Sheet
  alias D20.KoalaRescueClub.Ruleset.Yugambeh

  @player_count_range 1..99
  @rounds 1..2
  @turns_per_round 15
  @turn_range 1..30
  @scoring_turns [15, 30]
  @die_value_range 1..6
  @volunteer_limit 6

  @badge_policy %{
    multiplayer: :first_players_large_others_small,
    solo: :round_1_large_round_2_small
  }

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
  @type offset :: {integer(), integer()}
  @type cell :: %{
          required(:area) => area(),
          required(:row) => non_neg_integer(),
          required(:column) => non_neg_integer()
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
  @type area_score_input :: %{
          required(:trees_complete?) => boolean(),
          required(:koalas_complete?) => boolean()
        }

  @doc "Returns the supported player count range."
  @spec player_count_range() :: Range.t()
  def player_count_range, do: @player_count_range

  @doc "Returns the round numbers."
  @spec rounds() :: Range.t()
  def rounds, do: @rounds

  @doc "Returns the number of turns in each round."
  @spec turns_per_round() :: pos_integer()
  def turns_per_round, do: @turns_per_round

  @doc "Returns the complete turn range."
  @spec turn_range() :: Range.t()
  def turn_range, do: @turn_range

  @doc "Returns the turn numbers that trigger round scoring."
  @spec scoring_turns() :: [pos_integer()]
  def scoring_turns, do: @scoring_turns

  @doc "Returns the 1-based round for a valid turn."
  @spec round_for_turn(term()) :: {:ok, pos_integer()} | {:error, :invalid_turn}
  def round_for_turn(turn) when is_integer(turn) and turn in @turn_range do
    {:ok, div(turn - 1, @turns_per_round) + 1}
  end

  def round_for_turn(_turn), do: {:error, :invalid_turn}

  @doc "Returns true when the given turn triggers round scoring."
  @spec scoring_turn?(term()) :: boolean()
  def scoring_turn?(turn), do: turn in @scoring_turns

  @doc "Returns true when the given turn is the final turn."
  @spec final_turn?(term()) :: boolean()
  def final_turn?(turn), do: turn == Enum.max(@turn_range)

  @doc "Returns the die face range."
  @spec die_value_range() :: Range.t()
  def die_value_range, do: @die_value_range

  @doc "Returns true when the value is a legal die face."
  @spec valid_die_value?(term()) :: boolean()
  def valid_die_value?(value), do: is_integer(value) and value in @die_value_range

  @doc "Returns the canonical cell offsets for a die face shape."
  @spec shape_for(term()) :: {:ok, [offset()]} | {:error, :invalid_die_value}
  def shape_for(value) when value in @die_value_range, do: {:ok, Map.fetch!(@shapes, value)}
  def shape_for(_value), do: {:error, :invalid_die_value}

  @doc "Returns the canonical cell offsets for a known die face shape."
  @spec shape_offsets(pos_integer()) :: [offset()]
  def shape_offsets(value), do: Map.fetch!(@shapes, value)

  @doc "Returns the number of cells in a die face shape."
  @spec shape_size(pos_integer()) :: pos_integer()
  def shape_size(value), do: value |> shape_offsets() |> length()

  @doc "Applies a volunteer die adjustment, wrapping between 1 and 6."
  @spec adjust_die(term(), term()) :: {:ok, pos_integer()} | {:error, :invalid_die_adjustment}
  def adjust_die(value, delta) when value in @die_value_range and is_integer(delta) do
    adjusted = value - 1 + delta
    {:ok, Integer.mod(adjusted, Enum.count(@die_value_range)) + 1}
  end

  def adjust_die(_value, _delta), do: {:error, :invalid_die_adjustment}

  @doc "Returns the minimum volunteers needed to change one die face into another."
  @spec volunteers_needed(term(), term()) ::
          {:ok, non_neg_integer()} | {:error, :invalid_die_value}
  def volunteers_needed(from, to) when from in @die_value_range and to in @die_value_range do
    distance = abs(to - from)
    {:ok, min(distance, Enum.count(@die_value_range) - distance)}
  end

  def volunteers_needed(_from, _to), do: {:error, :invalid_die_value}

  @doc "Returns all die faces reachable with up to the given number of volunteers."
  @spec reachable_die_values(term(), term()) ::
          {:ok, [pos_integer()]} | {:error, :invalid_volunteers}
  def reachable_die_values(value, volunteers)
      when value in @die_value_range and is_integer(volunteers) and volunteers >= 0 do
    values =
      Enum.filter(@die_value_range, fn candidate ->
        {:ok, needed} = volunteers_needed(value, candidate)
        needed <= volunteers
      end)

    {:ok, values}
  end

  def reachable_die_values(_value, _volunteers), do: {:error, :invalid_volunteers}

  @doc "Returns the maximum number of volunteer circles on the sheet."
  @spec volunteer_limit() :: pos_integer()
  def volunteer_limit, do: @volunteer_limit

  @doc "Returns the badge scoring policy."
  @spec badge_policy() :: map()
  def badge_policy, do: @badge_policy

  @doc "Returns supported sheet ids."
  @spec sheets() :: [id()]
  def sheets, do: @sheets

  @doc "Returns all supported sheet definitions."
  @spec sheet_definitions() :: [Sheet.t()]
  def sheet_definitions, do: Enum.map(@sheets, &sheet!/1)

  @doc "Fetches a supported sheet definition."
  @spec sheet(id() | String.t()) :: {:ok, Sheet.t()} | {:error, :unknown_sheet}
  def sheet(id) do
    case normalize_sheet(id) do
      {:ok, id} -> {:ok, sheet!(id)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Returns a supported sheet definition or raises when the sheet is unknown."
  @spec sheet!(id()) :: Sheet.t()
  def sheet!(sheet), do: @sheet_modules |> Map.fetch!(sheet) |> Sheet.from_module()

  @doc "Fetches the machine-readable geometry for a supported sheet."
  @spec geometry(id() | String.t()) :: {:ok, Sheet.t()} | {:error, :unknown_sheet}
  def geometry(id), do: sheet(id)

  @doc "Returns all cells for one area."
  @spec area_cells(Sheet.t(), atom()) :: [map()]
  def area_cells(%{cells: cells}, area) do
    cells
    |> Map.values()
    |> Enum.filter(&(&1.area == area))
    |> Enum.sort_by(&{&1.r, &1.q})
  end

  @doc "Returns the canonical internal cell id for a cell coordinate."
  @spec cell_id(cell()) :: String.t()
  def cell_id(%{area: area, row: row, column: column}) do
    Sheet.cell_id(area, column, row)
  end

  @doc "Returns the player-state cell coordinate for a sheet cell."
  @spec cell(map()) :: cell()
  def cell(%{area: area, q: column, r: row}) do
    %{area: area, row: row, column: column}
  end

  @doc "Returns all lines that carry bonuses."
  @spec bonus_lines(Sheet.t()) :: [map()]
  def bonus_lines(sheet) do
    sheet.rows
    |> Map.values()
    |> Kernel.++(Map.values(sheet.columns))
    |> Enum.filter(& &1.bonus)
  end

  @doc "Returns true when a supported sheet geometry is internally consistent."
  @spec valid_geometry?(Sheet.t()) :: boolean()
  def valid_geometry?(sheet) do
    valid_area_refs?(sheet) and valid_line_refs?(sheet) and valid_bonus_refs?(sheet) and
      valid_skybridge_refs?(sheet) and valid_badges?(sheet)
  end

  @doc "Returns all areas accessible for a sheet through claimed skybridges."
  @spec accessible_areas(Sheet.t(), map()) :: [atom()]
  def accessible_areas(sheet, player_sheet) do
    initial =
      sheet.areas |> Map.values() |> Enum.filter(& &1.access) |> Enum.map(& &1.id) |> MapSet.new()

    claimed = MapSet.new(player_sheet.skybridges)

    sheet.skybridges
    |> Map.values()
    |> Enum.filter(&MapSet.member?(claimed, &1))
    |> expand_access(initial)
    |> MapSet.to_list()
    |> Enum.sort()
  end

  @doc "Returns true when all tree cells in an area have circled trees."
  @spec trees_complete?(Sheet.t(), map(), atom()) :: boolean()
  def trees_complete?(map, player_sheet, area) do
    complete_area?(map, player_sheet.trees, area)
  end

  @doc "Returns true when all tree cells in an area have circled koalas."
  @spec koalas_complete?(Sheet.t(), map(), atom()) :: boolean()
  def koalas_complete?(map, player_sheet, area) do
    complete_area?(map, player_sheet.koalas, area)
  end

  @doc "Returns true when the target cells match a die shape under rotation or flip."
  @spec shape_match?(Sheet.t(), [String.t()], pos_integer()) :: boolean()
  def shape_match?(%{cells: cells}, cell_ids, die_value) do
    with {:ok, shape} <- shape_for(die_value),
         true <- length(cell_ids) == length(shape),
         {:ok, coords} <- target_coords(cells, cell_ids) do
      normalized = normalize_offsets(coords)

      die_value
      |> transformed_shapes()
      |> Enum.any?(&(normalize_offsets(&1) == normalized))
    else
      _ -> false
    end
  end

  @doc "Returns all transformed offsets for a die shape."
  @spec transformed_shapes(pos_integer()) :: [[offset()]]
  def transformed_shapes(die_value) do
    die_value
    |> shape_offsets()
    |> transforms()
    |> Enum.uniq()
  end

  @doc "Returns the solo rating for a supported sheet and score."
  @spec solo_rating(id() | String.t(), term()) ::
          {:ok, solo_rating()} | {:error, :unknown_sheet | :invalid_score}
  def solo_rating(id, score) when is_integer(score) and score >= 0 do
    with {:ok, sheet} <- sheet(id),
         {rank, range} <- Enum.find(sheet.solo_ratings, &score_in_rating?(score, &1)) do
      {:ok, %{rank: rank, range: range}}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :invalid_score}
    end
  end

  def solo_rating(_sheet, _score), do: {:error, :invalid_score}

  @doc "Scores one area for a round."
  @spec score_area(area_score_input()) :: 0..2
  def score_area(%{trees_complete?: trees_complete?, koalas_complete?: koalas_complete?}) do
    score_if(trees_complete?) + score_if(koalas_complete?)
  end

  @doc "Scores one hospital."
  @spec score_hospital(id() | String.t(), hospital()) ::
          {:ok, integer()} | {:error, :unknown_sheet | :invalid_hospital}
  def score_hospital(id, hospital) do
    with {:ok, _sheet} <- sheet(id),
         :ok <- validate_hospital(hospital) do
      {:ok, score_hospital_by_penalty(hospital)}
    end
  end

  defp normalize_sheet(id) when is_atom(id) and id in @sheets, do: {:ok, id}
  defp normalize_sheet("dharug"), do: {:ok, :dharug}
  defp normalize_sheet("yugambeh"), do: {:ok, :yugambeh}
  defp normalize_sheet(_id), do: {:error, :unknown_sheet}

  defp valid_area_refs?(%{areas: areas, cells: cells}) do
    Enum.all?(cells, fn {_id, cell} -> Map.has_key?(areas, cell.area) end)
  end

  defp valid_line_refs?(%{cells: cells, rows: rows, columns: columns}) do
    rows
    |> Map.values()
    |> Kernel.++(Map.values(columns))
    |> Enum.all?(fn line ->
      line.cell_ids != [] and Enum.all?(line.cell_ids, &Map.has_key?(cells, &1))
    end)
  end

  defp valid_bonus_refs?(%{rows: rows, columns: columns, bonuses: bonuses}) do
    line_ids = rows |> Map.keys() |> Kernel.++(Map.keys(columns)) |> MapSet.new()

    Enum.all?(bonuses, fn {_id, bonus} ->
      valid_bonus_kind?(bonus.kind) and MapSet.member?(line_ids, bonus.line_id)
    end)
  end

  defp valid_bonus_kind?(:tree), do: true
  defp valid_bonus_kind?(:koala), do: true
  defp valid_bonus_kind?(:volunteer), do: true
  defp valid_bonus_kind?(:hospital), do: true
  defp valid_bonus_kind?(:skybridge), do: true
  defp valid_bonus_kind?(_kind), do: false

  defp valid_skybridge_refs?(%{areas: areas, skybridges: skybridges}) do
    Enum.all?(skybridges, fn {_id, skybridge} ->
      Map.has_key?(areas, skybridge.from) and Map.has_key?(areas, skybridge.to)
    end)
  end

  defp valid_badges?(%{badges: badges} = sheet) do
    Enum.all?(badges, fn
      {_id, %{requirement: requirement, awards: awards}} ->
        valid_awards?(awards) and valid_badge_requirement?(sheet, requirement)

      _badge ->
        false
    end)
  end

  defp valid_awards?(awards) when is_map(awards) and map_size(awards) > 0 do
    Enum.all?(awards, fn {award, points} ->
      is_atom(award) and is_integer(points) and points >= 0
    end)
  end

  defp valid_awards?(_awards), do: false

  defp valid_badge_requirement?(%{areas: areas}, %{complete: %{area: area, mark: mark}}) do
    Map.has_key?(areas, area) and mark in [:trees, :koalas]
  end

  defp valid_badge_requirement?(_sheet, %{count: %{field: field, at_least: at_least}}) do
    field in [:skybridges, :volunteers] and is_integer(at_least) and at_least >= 0
  end

  defp valid_badge_requirement?(%{hospitals: hospitals}, %{filled: %{hospital: hospital_id}}) do
    Map.has_key?(hospitals, hospital_id)
  end

  defp valid_badge_requirement?(_sheet, _requirement), do: false

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

  defp complete_area?(map, cell_ids, area) do
    required = map |> area_cells(area) |> Enum.map(&cell/1) |> MapSet.new()

    required != MapSet.new() and MapSet.subset?(required, MapSet.new(cell_ids))
  end

  defp target_coords(cells, cell_ids) do
    Enum.reduce_while(cell_ids, {:ok, []}, fn cell_id, {:ok, coords} ->
      case Map.fetch(cells, cell_id) do
        {:ok, cell} -> {:cont, {:ok, [{cell.q, cell.r} | coords]}}
        :error -> {:halt, {:error, :unknown_cell}}
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

  defp score_if(true), do: 1
  defp score_if(false), do: 0

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
