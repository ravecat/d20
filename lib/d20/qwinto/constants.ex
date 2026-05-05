defmodule D20.Qwinto.Constants do
  @moduledoc """
  Static Qwinto board layout and numeric limits.

  The score sheet rows are staggered: purple starts one visual column before yellow,
  and yellow starts one visual column before orange.
  """

  @colors [:orange, :yellow, :purple]
  @player_count_range 2..4
  @dice_count_range 1..3
  @dice_value_range 1..6
  @slot_range 0..8
  @penalty_limit 4
  @completed_rows_to_end 2
  @penalty_points -5

  @row_slots Map.new(@colors, &{&1, Enum.to_list(@slot_range)})

  @score_sheet_columns [
    %{cells: [{:purple, 0}], bonus: nil},
    %{cells: [{:yellow, 0}, {:purple, 1}], bonus: nil},
    %{cells: [{:orange, 0}, {:yellow, 1}, {:purple, 2}], bonus: {:purple, 2}},
    %{cells: [{:orange, 1}, {:yellow, 2}, {:purple, 3}], bonus: {:orange, 1}},
    %{cells: [{:orange, 2}, {:yellow, 3}], bonus: nil},
    %{cells: [{:yellow, 4}, {:purple, 4}], bonus: nil},
    %{cells: [{:orange, 3}, {:purple, 5}], bonus: nil},
    %{cells: [{:orange, 4}, {:yellow, 5}, {:purple, 6}], bonus: {:orange, 4}},
    %{cells: [{:orange, 5}, {:yellow, 6}, {:purple, 7}], bonus: {:yellow, 6}},
    %{cells: [{:orange, 6}, {:yellow, 7}, {:purple, 8}], bonus: {:purple, 8}},
    %{cells: [{:orange, 7}, {:yellow, 8}], bonus: nil},
    %{cells: [{:orange, 8}], bonus: nil}
  ]

  @bonus_columns Enum.filter(@score_sheet_columns, & &1.bonus)

  @type color :: :orange | :yellow | :purple
  @type column :: %{
          required(:cells) => [{color(), non_neg_integer()}],
          required(:bonus) => {color(), non_neg_integer()} | nil
        }

  @spec colors() :: [color()]
  def colors, do: @colors

  @spec player_count_range() :: Range.t()
  def player_count_range, do: @player_count_range

  @spec dice_count_range() :: Range.t()
  def dice_count_range, do: @dice_count_range

  @spec dice_value_range() :: Range.t()
  def dice_value_range, do: @dice_value_range

  @spec slot_range() :: Range.t()
  def slot_range, do: @slot_range

  @spec penalty_limit() :: pos_integer()
  def penalty_limit, do: @penalty_limit

  @spec completed_rows_to_end() :: pos_integer()
  def completed_rows_to_end, do: @completed_rows_to_end

  @spec penalty_points() :: neg_integer()
  def penalty_points, do: @penalty_points

  @spec row_slots(color()) :: [non_neg_integer()]
  def row_slots(row), do: Map.fetch!(@row_slots, row)

  @spec score_sheet_columns() :: [column()]
  def score_sheet_columns, do: @score_sheet_columns

  @spec bonus_columns() :: [column()]
  def bonus_columns, do: @bonus_columns
end
