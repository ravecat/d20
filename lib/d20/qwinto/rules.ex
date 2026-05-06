defmodule D20.Qwinto.Rules do
  @moduledoc """
  Qwinto command precondition checks.
  """

  alias D20.Qwinto.Command
  alias D20.Qwinto.Constants

  @type setup_error :: :invalid_player_count
  @type reason ::
          setup_error()
          | :not_active_player
          | :unknown_player
          | :already_responded
          | :row_not_in_roll
          | :invalid_slot
          | :occupied
          | :row_order
          | :column_duplicate
          | :invalid_attempt
          | :invalid_phase

  @spec validate(D20.Qwinto.Game.t(), D20.Qwinto.Command.command()) ::
          :ok | {:error, reason()}
  def validate(game, %Command.Join{} = command) do
    with :ok <- require_phase(game, [:setup, :ready]),
         :ok <- require_player_capacity(game, command.player_id) do
      :ok
    end
  end

  def validate(game, %Command.Start{}) do
    with :ok <- require_phase(game, :ready),
         :ok <- require_player_count(game) do
      :ok
    end
  end

  def validate(game, %Command.Roll{} = command) do
    with :ok <- require_phase(game, :turn),
         :ok <- require_active_player(game, command.player_id) do
      :ok
    end
  end

  def validate(game, %Command.Keep{} = command) do
    with :ok <- require_phase(game, :decision),
         :ok <- require_active_player(game, command.player_id),
         :ok <- require_attempt(game, 1) do
      :ok
    end
  end

  def validate(game, %Command.Reroll{} = command) do
    with :ok <- require_phase(game, :decision),
         :ok <- require_active_player(game, command.player_id),
         :ok <- require_attempt(game, 1) do
      :ok
    end
  end

  def validate(game, %Command.Write{} = command) do
    with :ok <- require_phase(game, :result),
         :ok <- require_player(game, command.player_id),
         :ok <- require_ready(game, command.player_id),
         :ok <- require_row_in_roll(game, command.row),
         :ok <- require_slot(command.row, command.slot),
         :ok <- require_empty(game, command.player_id, command.row, command.slot),
         :ok <- require_row_order(game, command.player_id, command.row, command.slot, game.sum),
         :ok <-
           require_column_unique(
             game,
             command.player_id,
             command.row,
             command.slot,
             game.sum
           ) do
      :ok
    end
  end

  def validate(game, %Command.Skip{} = command) do
    with :ok <- require_phase(game, :result),
         :ok <- require_player(game, command.player_id),
         :ok <- require_ready(game, command.player_id) do
      :ok
    end
  end

  @spec turn_responses_complete?(D20.Qwinto.Game.t()) :: boolean()
  def turn_responses_complete?(game) do
    Enum.all?(game.players, fn {_player_id, player} -> player.status != :ready end)
  end

  @spec ready_to_start?(D20.Qwinto.Game.t()) :: boolean()
  def ready_to_start?(game), do: player_count_result(game) == :ok

  @spec finished?(D20.Qwinto.Game.t()) :: boolean()
  def finished?(game) do
    completed_rows_limit_reached?(game) or penalty_limit_reached?(game)
  end

  defp require_phase(%{phase: phase}, expected) when is_list(expected) do
    if phase in expected, do: :ok, else: {:error, :invalid_phase}
  end

  defp require_phase(%{phase: phase}, phase), do: :ok
  defp require_phase(%{phase: _phase}, _expected), do: {:error, :invalid_phase}

  defp require_attempt(%{attempt: attempt}, attempt), do: :ok
  defp require_attempt(%{attempt: _attempt}, _expected), do: {:error, :invalid_attempt}

  defp require_player_count(game), do: player_count_result(game)

  defp player_count_result(%{order: player_ids}) do
    if length(player_ids) in Constants.player_count_range(),
      do: :ok,
      else: {:error, :invalid_player_count}
  end

  defp require_player_capacity(game, player_id) do
    cond do
      Map.has_key?(game.players, player_id) -> :ok
      length(game.order) < Enum.max(Constants.player_count_range()) -> :ok
      true -> {:error, :invalid_player_count}
    end
  end

  defp require_active_player(%{order: order, cursor: cursor}, player_id) do
    if Enum.at(order, cursor) == player_id, do: :ok, else: {:error, :not_active_player}
  end

  defp require_player(game, player_id) do
    if Map.has_key?(game.players, player_id), do: :ok, else: {:error, :unknown_player}
  end

  defp require_ready(game, player_id) do
    if game.players[player_id].status == :ready, do: :ok, else: {:error, :already_responded}
  end

  defp require_row_in_roll(game, row) do
    if row in game.dices, do: :ok, else: {:error, :row_not_in_roll}
  end

  defp require_slot(row, slot) do
    cond do
      row not in Constants.colors() -> {:error, :invalid_slot}
      slot in Constants.row_slots(row) -> :ok
      true -> {:error, :invalid_slot}
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
    case Enum.find(Constants.score_sheet_columns(), fn column -> {row, slot} in column.cells end) do
      nil -> :ok
      column -> require_column_value_unique(game, player_id, row, slot, sum, column)
    end
  end

  defp require_column_value_unique(game, player_id, row, slot, sum, column) do
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
      completed_row_count(player) >= Constants.completed_rows_to_end()
    end)
  end

  defp penalty_limit_reached?(game) do
    Enum.any?(game.players, fn {_player_id, player} ->
      player.penalties >= Constants.penalty_limit()
    end)
  end

  defp completed_row_count(player) do
    Enum.count(Constants.colors(), fn row ->
      map_size(player.rows[row]) == length(Constants.row_slots(row))
    end)
  end
end
