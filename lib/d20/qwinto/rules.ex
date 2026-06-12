defmodule D20.Qwinto.Rules do
  @moduledoc """
  State-dependent Qwinto command precondition checks.

  Keep checks here when they need the current `D20.Qwinto.Game` state: phase,
  active player, player readiness, rolled rows, occupied cells, row order,
  column duplicates, and end-game conditions. Static limits and score-sheet
  geometry belong in `D20.Qwinto.Ruleset`; state mutation belongs in
  `D20.Qwinto.Game`.
  """

  alias D20.Qwinto.Game
  alias D20.Qwinto.Ruleset

  @type setup_error :: :invalid_player_count
  @type reason ::
          setup_error()
          | :not_active_player
          | :unknown_player
          | :already_responded
          | :invalid_slot
          | :occupied
          | :invalid_row_order
          | :column_duplicate
          | :invalid_attempt
          | :invalid_phase
  @type slot :: %{required(:row) => Ruleset.color(), required(:slot) => non_neg_integer()}

  @spec validate(D20.Qwinto.Game.t(), D20.Command.t()) ::
          :ok | {:error, reason()}
  def validate(game, %D20.Command{event: "join", actor_id: actor_id}) do
    with :ok <- require_phase(game, [:setup, :ready]),
         :ok <- require_player_capacity(game, actor_id) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "start"}) do
    with :ok <- require_phase(game, :ready),
         :ok <- require_player_count(game) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "roll", actor_id: actor_id}) do
    with :ok <- require_phase(game, :turn),
         :ok <- require_active_player(game, actor_id) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "keep", actor_id: actor_id}) do
    with :ok <- require_phase(game, :decision),
         :ok <- require_active_player(game, actor_id),
         :ok <- require_attempt(game, 1) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "reroll", actor_id: actor_id}) do
    with :ok <- require_phase(game, :decision),
         :ok <- require_active_player(game, actor_id),
         :ok <- require_attempt(game, 1) do
      :ok
    end
  end

  def validate(%Game{phase: :decision} = game, %D20.Command{
        event: "write",
        actor_id: actor_id,
        attrs: %{row: row, slot: slot}
      }) do
    with :ok <- require_player(game, actor_id),
         :ok <- require_ready(game, actor_id),
         :ok <- require_active_player(game, actor_id),
         :ok <- require_valid_slot(game, row, slot),
         :ok <- require_available_slot(game, actor_id, row, slot),
         :ok <- require_valid_order(game, actor_id, row, slot),
         :ok <- require_column_unique(game, actor_id, row, slot) do
      :ok
    end
  end

  def validate(%Game{phase: :result} = game, %D20.Command{
        event: "write",
        actor_id: actor_id,
        attrs: %{row: row, slot: slot}
      }) do
    with :ok <- require_player(game, actor_id),
         :ok <- require_ready(game, actor_id),
         :ok <- require_valid_slot(game, row, slot),
         :ok <- require_available_slot(game, actor_id, row, slot),
         :ok <- require_valid_order(game, actor_id, row, slot),
         :ok <- require_column_unique(game, actor_id, row, slot) do
      :ok
    end
  end

  def validate(%Game{}, %D20.Command{event: "write"}), do: {:error, :invalid_phase}

  def validate(game, %D20.Command{event: "skip", actor_id: actor_id}) do
    with :ok <- require_phase(game, :result),
         :ok <- require_player(game, actor_id),
         :ok <- require_ready(game, actor_id) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "take_penalty", actor_id: actor_id}) do
    with :ok <- require_phase(game, [:decision, :result]),
         :ok <- require_player(game, actor_id),
         :ok <- require_ready(game, actor_id),
         :ok <- require_active_player(game, actor_id) do
      :ok
    end
  end

  @spec write_allowed?(D20.Qwinto.Game.t(), Game.player_id()) :: boolean()
  def write_allowed?(%Game{} = game, actor_id) do
    can_write_now?(game, actor_id) and Enum.any?(available_slots(game, actor_id))
  end

  @spec available_slots(D20.Qwinto.Game.t(), Game.player_id()) :: [slot()]
  def available_slots(%Game{phase: phase} = game, actor_id) when phase in [:decision, :result] do
    for row <- Map.keys(game.dices),
        slot <- Ruleset.row_slots(row),
        require_available_slot(game, actor_id, row, slot) == :ok,
        require_valid_order(game, actor_id, row, slot) == :ok,
        require_column_unique(game, actor_id, row, slot) == :ok,
        do: %{row: row, slot: slot}
  end

  def available_slots(%Game{}, _actor_id), do: []

  @spec turn_responses_complete?(D20.Qwinto.Game.t()) :: boolean()
  def turn_responses_complete?(game) do
    Enum.all?(game.players, fn {_player_id, player} -> player.status != :ready end)
  end

  @spec ready_to_start?(D20.Qwinto.Game.t()) :: boolean()
  def ready_to_start?(game), do: valid_player_count?(game)

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

  defp require_player_count(game) do
    if valid_player_count?(game), do: :ok, else: {:error, :invalid_player_count}
  end

  defp valid_player_count?(%{order: player_ids}) do
    length(player_ids) in Ruleset.player_count_range()
  end

  defp require_player_capacity(game, player_id) do
    cond do
      Map.has_key?(game.players, player_id) -> :ok
      length(game.order) < Enum.max(Ruleset.player_count_range()) -> :ok
      true -> {:error, :invalid_player_count}
    end
  end

  defp require_active_player(game, player_id) do
    if Game.active_player?(game, player_id), do: :ok, else: {:error, :not_active_player}
  end

  defp require_player(game, player_id) do
    if Map.has_key?(game.players, player_id), do: :ok, else: {:error, :unknown_player}
  end

  defp require_ready(game, player_id) do
    if game.players[player_id].status == :ready, do: :ok, else: {:error, :already_responded}
  end

  defp can_write_now?(%Game{phase: :decision} = game, player_id) do
    with :ok <- require_player(game, player_id),
         :ok <- require_ready(game, player_id),
         :ok <- require_active_player(game, player_id) do
      true
    else
      {:error, _reason} -> false
    end
  end

  defp can_write_now?(%Game{phase: :result} = game, player_id) do
    with :ok <- require_player(game, player_id),
         :ok <- require_ready(game, player_id) do
      true
    else
      {:error, _reason} -> false
    end
  end

  defp can_write_now?(%Game{}, _player_id), do: false

  defp require_valid_slot(game, row, slot) do
    if Map.has_key?(game.dices, row) and Ruleset.valid_slot?(row, slot) do
      :ok
    else
      {:error, :invalid_slot}
    end
  end

  defp require_available_slot(game, player_id, row, slot) do
    if Map.has_key?(game.players[player_id].rows[row], slot), do: {:error, :occupied}, else: :ok
  end

  defp require_valid_order(%{sum: sum} = game, player_id, row, slot) do
    conflict? =
      Enum.any?(game.players[player_id].rows[row], fn
        {filled_slot, value} when filled_slot < slot -> value >= sum
        {filled_slot, value} when filled_slot > slot -> value <= sum
        {_filled_slot, _value} -> false
      end)

    if conflict?, do: {:error, :invalid_row_order}, else: :ok
  end

  defp require_column_unique(%{sum: sum} = game, player_id, row, slot) do
    case Ruleset.column_for_cell(row, slot) do
      nil ->
        :ok

      %{cells: cells} ->
        duplicate? =
          Enum.any?(cells, fn
            {^row, ^slot} ->
              false

            {other_row, other_slot} ->
              get_in(game.players[player_id].rows, [other_row, other_slot]) == sum
          end)

        if duplicate?, do: {:error, :column_duplicate}, else: :ok
    end
  end

  defp completed_rows_limit_reached?(game) do
    Enum.any?(game.players, fn {_player_id, player} ->
      Enum.count(Ruleset.colors(), fn row ->
        map_size(player.rows[row]) == Ruleset.row_slot_count(row)
      end) >= Ruleset.completed_rows_to_end()
    end)
  end

  defp penalty_limit_reached?(game) do
    Enum.any?(game.players, fn {_player_id, player} ->
      player.penalties >= Ruleset.penalty_limit()
    end)
  end
end
