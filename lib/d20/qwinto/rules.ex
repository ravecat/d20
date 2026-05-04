defmodule D20.Qwinto.Rules do
  @moduledoc """
  Static Qwinto constraints and state-dependent rule checks.
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

  @columns [
    %{cells: [{:orange, 0}, {:yellow, 0}], bonus: nil},
    %{cells: [{:orange, 1}, {:yellow, 1}, {:purple, 0}], bonus: {:orange, 1}},
    %{cells: [{:orange, 2}, {:yellow, 2}, {:purple, 1}], bonus: nil},
    %{cells: [{:yellow, 3}, {:purple, 2}], bonus: {:purple, 2}},
    %{cells: [{:orange, 3}, {:yellow, 4}], bonus: nil},
    %{cells: [{:orange, 4}, {:purple, 3}], bonus: {:orange, 4}},
    %{cells: [{:orange, 5}, {:yellow, 5}, {:purple, 4}], bonus: nil},
    %{cells: [{:orange, 6}, {:yellow, 6}, {:purple, 5}], bonus: {:yellow, 6}},
    %{cells: [{:orange, 7}, {:yellow, 7}, {:purple, 6}], bonus: nil},
    %{cells: [{:orange, 8}, {:yellow, 8}, {:purple, 7}], bonus: nil},
    %{cells: [{:purple, 8}], bonus: {:purple, 8}}
  ]

  @bonus_columns Enum.filter(@columns, & &1.bonus)

  @type color :: :orange | :yellow | :purple
  @type setup_error :: :invalid_player_count | :duplicate_players
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

  @spec bonus_columns() :: [column()]
  def bonus_columns, do: @bonus_columns

  @spec validate_player_count([String.t()]) :: :ok | {:error, setup_error()}
  def validate_player_count(player_ids) do
    cond do
      length(player_ids) not in @player_count_range -> {:error, :invalid_player_count}
      Enum.uniq(player_ids) != player_ids -> {:error, :duplicate_players}
      true -> :ok
    end
  end

  @spec can_roll?(D20.Qwinto.Game.t(), D20.Qwinto.Command.Roll.t()) ::
          :ok | {:error, :not_active_player | :invalid_phase}
  def can_roll?(game, command) do
    with :ok <- require_phase(game, :waiting_for_roll),
         :ok <- require_active_player(game, command.player_id) do
      :ok
    end
  end

  @spec can_write?(D20.Qwinto.Game.t(), D20.Qwinto.Command.Write.t()) ::
          :ok
          | {:error,
             :unknown_player
             | :already_responded
             | :row_not_in_roll
             | :invalid_slot
             | :occupied
             | :row_order
             | :column_duplicate
             | :invalid_phase}
  def can_write?(game, command) do
    with :ok <- require_phase(game, :accepting_entries),
         :ok <- require_player(game, command.player_id),
         :ok <- require_not_responded(game, command.player_id),
         :ok <- require_row_in_roll(game, command.row),
         :ok <- require_slot(command.row, command.slot),
         :ok <- require_empty(game, command.player_id, command.row, command.slot),
         :ok <-
           require_row_order(game, command.player_id, command.row, command.slot, game.roll.sum),
         :ok <-
           require_column_unique(
             game,
             command.player_id,
             command.row,
             command.slot,
             game.roll.sum
           ) do
      :ok
    end
  end

  @spec can_skip?(D20.Qwinto.Game.t(), D20.Qwinto.Command.Skip.t()) ::
          :ok | {:error, :unknown_player | :already_responded | :invalid_phase}
  def can_skip?(game, command) do
    with :ok <- require_phase(game, :accepting_entries),
         :ok <- require_player(game, command.player_id),
         :ok <- require_not_responded(game, command.player_id) do
      :ok
    end
  end

  @spec turn_responses_complete?(D20.Qwinto.Game.t()) :: boolean()
  def turn_responses_complete?(game) do
    Enum.all?(game.players, fn {_player_id, player} -> player.responded end)
  end

  @spec finished?(D20.Qwinto.Game.t()) :: boolean()
  def finished?(game) do
    completed_rows_limit_reached?(game) or penalty_limit_reached?(game)
  end

  defp require_phase(%{phase: phase}, phase), do: :ok
  defp require_phase(%{phase: _phase}, _expected), do: {:error, :invalid_phase}

  defp require_active_player(game, player_id) do
    if game.active_player_id == player_id, do: :ok, else: {:error, :not_active_player}
  end

  defp require_player(game, player_id) do
    if Map.has_key?(game.players, player_id), do: :ok, else: {:error, :unknown_player}
  end

  defp require_not_responded(game, player_id) do
    if game.players[player_id].responded, do: {:error, :already_responded}, else: :ok
  end

  defp require_row_in_roll(game, row) do
    if row in game.roll.colors, do: :ok, else: {:error, :row_not_in_roll}
  end

  defp require_slot(row, slot) do
    case Map.fetch(@row_slots, row) do
      {:ok, slots} -> if slot in slots, do: :ok, else: {:error, :invalid_slot}
      :error -> {:error, :invalid_slot}
    end
  end

  defp require_empty(game, player_id, row, slot) do
    if Map.has_key?(game.players[player_id].rows[row], slot), do: {:error, :occupied}, else: :ok
  end

  defp require_row_order(game, player_id, row, slot, sum) do
    conflict? =
      Enum.any?(game.players[player_id].rows[row], fn
        {filled_slot, value} when filled_slot < slot -> value >= sum
        {filled_slot, value} when filled_slot > slot -> value <= sum
        {_filled_slot, _value} -> false
      end)

    if conflict?, do: {:error, :row_order}, else: :ok
  end

  defp require_column_unique(game, player_id, row, slot, sum) do
    column = Enum.find(@columns, fn column -> {row, slot} in column.cells end)

    duplicate? =
      Enum.any?(column.cells, fn
        {^row, ^slot} ->
          false

        {other_row, other_slot} ->
          get_in(game.players[player_id].rows, [other_row, other_slot]) == sum
      end)

    if duplicate?, do: {:error, :column_duplicate}, else: :ok
  end

  defp completed_rows_limit_reached?(game) do
    Enum.any?(game.players, fn {_player_id, player} ->
      completed_row_count(player) >= @completed_rows_to_end
    end)
  end

  defp penalty_limit_reached?(game) do
    Enum.any?(game.players, fn {_player_id, player} -> player.penalties >= @penalty_limit end)
  end

  defp completed_row_count(player) do
    Enum.count(@colors, fn row ->
      map_size(player.rows[row]) == length(row_slots(row))
    end)
  end
end
