defmodule D20.Qwinto.Game do
  @moduledoc """
  Qwinto game aggregate and reducer.
  """

  @behaviour D20.Game

  use Ecto.Schema

  alias D20.Qwinto.Command
  alias D20.Qwinto.Rules

  @phases [:setup, :waiting_for_roll, :accepting_entries, :finished]
  @primary_key false

  embedded_schema do
    field :phase, Ecto.Enum,
      values: @phases,
      default: :setup

    field :active_player_id, :string
    field :order, {:array, :string}, default: []
    field :players, :map, default: %{}
    field :roll, :map
    field :scores, :map, default: %{}
  end

  @type player_id :: String.t()
  @type phase :: :setup | :waiting_for_roll | :accepting_entries | :finished
  @type player :: %{
          required(:rows) => %{
            required(Rules.color()) => %{optional(non_neg_integer()) => integer()}
          },
          required(:penalties) => non_neg_integer(),
          required(:responded) => boolean()
        }
  @type roll :: %{
          required(:colors) => [Rules.color()],
          required(:values) => [integer()],
          required(:sum) => integer()
        }
  @type score :: %{
          required(:player_id) => player_id(),
          required(:rows) => %{required(Rules.color()) => integer()},
          required(:bonuses) => integer(),
          required(:penalties) => integer(),
          required(:total) => integer()
        }
  @type t :: %__MODULE__{
          phase: phase(),
          active_player_id: player_id() | nil,
          order: [player_id()],
          players: %{optional(player_id()) => player()},
          roll: roll() | nil,
          scores: %{optional(player_id()) => score()}
        }
  @type reason ::
          :game_finished
          | :not_active_player
          | :unknown_player
          | :already_responded
          | :row_not_in_roll
          | :invalid_slot
          | :occupied
          | :row_order
          | :column_duplicate
          | :invalid_phase

  @impl D20.Game
  @spec init() :: {:ok, t()}
  def init, do: {:ok, %__MODULE__{}}

  @impl D20.Game
  @spec dispatch(t(), Command.kind() | :join | :leave, map()) ::
          {:ok, t()}
          | {:error, Ecto.Changeset.t() | Rules.setup_error() | reason()}
  def dispatch(%__MODULE__{phase: :setup} = game, :join, %{player_id: player_id}) do
    if Map.has_key?(game.players, player_id) do
      {:ok, game}
    else
      {:ok,
       %{
         game
         | order: game.order ++ [player_id],
           players:
             Map.put(game.players, player_id, %{
               rows: Map.new(Rules.colors(), &{&1, %{}}),
               penalties: 0,
               responded: false
             })
       }}
    end
  end

  def dispatch(%__MODULE__{phase: :setup} = game, :leave, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :setup} = game, :start, attrs), do: reduce(game, :start, attrs)

  def dispatch(%__MODULE__{phase: :setup}, _kind, _attrs), do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :waiting_for_roll} = game, :join, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :waiting_for_roll} = game, :leave, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :waiting_for_roll} = game, :roll, attrs),
    do: reduce(game, :roll, attrs)

  def dispatch(%__MODULE__{phase: :waiting_for_roll}, _kind, _attrs),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :accepting_entries} = game, :join, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :accepting_entries} = game, :leave, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :accepting_entries} = game, :write, attrs),
    do: reduce(game, :write, attrs)

  def dispatch(%__MODULE__{phase: :accepting_entries} = game, :skip, attrs),
    do: reduce(game, :skip, attrs)

  def dispatch(%__MODULE__{phase: :accepting_entries}, _kind, _attrs),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :finished} = game, :join, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :finished} = game, :leave, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :finished} = game, :roll, attrs), do: reduce(game, :roll, attrs)

  def dispatch(%__MODULE__{phase: :finished} = game, :write, attrs),
    do: reduce(game, :write, attrs)

  def dispatch(%__MODULE__{phase: :finished} = game, :skip, attrs), do: reduce(game, :skip, attrs)

  def dispatch(%__MODULE__{}, _kind, _attrs), do: {:error, :invalid_phase}

  defp reduce(%__MODULE__{} = game, kind, attrs) do
    with {:ok, command} <- Command.build(kind, attrs),
         {:ok, game} <- reduce(game, command) do
      {:ok, game}
    end
  end

  defp reduce(%__MODULE__{phase: :setup} = game, %Command.Start{} = command) do
    with :ok <- Rules.can_start?(game, command) do
      {:ok, %{game | phase: :waiting_for_roll, active_player_id: List.first(game.order)}}
    end
  end

  defp reduce(%__MODULE__{phase: :waiting_for_roll} = game, %Command.Roll{} = command) do
    with :ok <- Rules.can_roll?(game, command) do
      {:ok,
       %{
         game
         | phase: :accepting_entries,
           roll: %{colors: command.colors, values: command.values, sum: Enum.sum(command.values)},
           players: reset_responses(game.players)
       }}
    end
  end

  defp reduce(%__MODULE__{phase: :accepting_entries} = game, %Command.Write{} = command) do
    with :ok <- Rules.can_write?(game, command) do
      game =
        game
        |> put_entry(command)
        |> mark_responded(command.player_id)
        |> resolve_turn_after_response()

      {:ok, game}
    end
  end

  defp reduce(%__MODULE__{phase: :accepting_entries} = game, %Command.Skip{} = command) do
    with :ok <- Rules.can_skip?(game, command) do
      game =
        game
        |> maybe_penalize_active_player(command.player_id)
        |> mark_responded(command.player_id)
        |> resolve_turn_after_response()

      {:ok, game}
    end
  end

  defp reduce(%__MODULE__{phase: :finished}, _command), do: {:error, :game_finished}

  defp reduce(%__MODULE__{}, %{__struct__: _module}), do: {:error, :invalid_phase}

  @impl D20.Game
  @spec finished?(t()) :: boolean()
  def finished?(%__MODULE__{phase: :finished}), do: true
  def finished?(%__MODULE__{}), do: false

  @spec scoreboard(t()) :: [score()]
  def scoreboard(%__MODULE__{scores: scores}) do
    scores
    |> Map.values()
    |> Enum.sort_by(& &1.total, :desc)
  end

  defp reset_responses(players) do
    Map.new(players, fn {player_id, player} ->
      {player_id, %{player | responded: false}}
    end)
  end

  defp put_entry(game, command) do
    put_in(game.players[command.player_id][:rows][command.row][command.slot], game.roll.sum)
  end

  defp maybe_penalize_active_player(game, active_player_id)
       when active_player_id == game.active_player_id do
    update_in(game.players[active_player_id][:penalties], &(&1 + 1))
  end

  defp maybe_penalize_active_player(game, _player_id), do: game

  defp mark_responded(game, player_id) do
    put_in(game.players[player_id][:responded], true)
  end

  defp resolve_turn_after_response(game) do
    cond do
      not Rules.turn_responses_complete?(game) -> game
      Rules.finished?(game) -> finish(game)
      true -> advance_turn(game)
    end
  end

  defp finish(game), do: %{game | phase: :finished, scores: score_players(game)}

  defp advance_turn(game) do
    index = Enum.find_index(game.order, &(&1 == game.active_player_id))
    next_player_id = Enum.at(game.order, rem(index + 1, length(game.order)))

    %{game | phase: :waiting_for_roll, active_player_id: next_player_id, roll: nil}
  end

  defp score_players(game) do
    Map.new(game.order, &{&1, score_player(game, &1)})
  end

  defp score_player(game, player_id) do
    player = Map.fetch!(game.players, player_id)
    rows = Map.new(Rules.colors(), &{&1, score_row(player, &1)})
    bonuses = score_bonus_columns(player)
    penalties = player.penalties * Rules.penalty_points()

    %{
      player_id: player_id,
      rows: rows,
      bonuses: bonuses,
      penalties: penalties,
      total: Enum.sum(Map.values(rows)) + bonuses + penalties
    }
  end

  defp score_row(player, row) do
    if row_complete?(player, row) do
      player.rows[row] |> Map.fetch!(List.last(Rules.row_slots(row)))
    else
      map_size(player.rows[row])
    end
  end

  defp row_complete?(player, row) do
    map_size(player.rows[row]) == length(Rules.row_slots(row))
  end

  defp score_bonus_columns(player) do
    Rules.bonus_columns()
    |> Enum.filter(&column_complete?(player, &1))
    |> Enum.map(fn %{bonus: {row, slot}} -> get_in(player.rows, [row, slot]) end)
    |> Enum.sum()
  end

  defp column_complete?(player, column) do
    Enum.all?(column.cells, fn {row, slot} -> get_in(player.rows, [row, slot]) end)
  end
end
