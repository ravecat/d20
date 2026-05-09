defmodule D20.Qwinto.Game do
  @moduledoc """
  Qwinto game aggregate and reducer.
  """

  @behaviour D20.Game

  use Ecto.Schema

  alias D20.Dice
  alias D20.Qwinto.Command
  alias D20.Qwinto.Constants
  alias D20.Qwinto.Rules

  @colors Constants.colors()
  @phases [:setup, :ready, :turn, :decision, :result, :finished]
  @primary_key false

  embedded_schema do
    field :phase, Ecto.Enum,
      values: @phases,
      default: :setup

    field :order, {:array, :string}, default: []
    field :cursor, :integer, default: 0
    field :players, :map, default: %{}
    field :dices, {:array, Ecto.Enum}, values: @colors, default: []
    field :values, {:array, :integer}, default: []
    field :sum, :integer
    field :attempt, :integer, default: 0
    field :scores, :map, default: %{}
  end

  @type player_id :: String.t()
  @type phase :: :setup | :ready | :turn | :decision | :result | :finished
  @type player_status :: :ready | :wrote | :failed | :passed
  @type player :: %{
          required(:rows) => %{
            required(Constants.color()) => %{optional(non_neg_integer()) => integer()}
          },
          required(:penalties) => non_neg_integer(),
          required(:status) => player_status()
        }
  @type score :: %{
          required(:player_id) => player_id(),
          required(:rows) => %{required(Constants.color()) => integer()},
          required(:bonuses) => integer(),
          required(:penalties) => integer(),
          required(:total) => integer()
        }
  @type t :: %__MODULE__{
          phase: phase(),
          order: [player_id()],
          cursor: non_neg_integer(),
          players: %{optional(player_id()) => player()},
          dices: [Constants.color()],
          values: [integer()],
          sum: integer() | nil,
          attempt: 0 | 1 | 2,
          scores: %{optional(player_id()) => score()}
        }
  @type reason :: :finished | :invalid_phase

  @impl D20.Game
  @spec init() :: {:ok, t()}
  def init, do: {:ok, %__MODULE__{}}

  @impl D20.Game
  @spec dispatch(t(), Command.kind() | :leave, map()) ::
          {:ok, t()}
          | {:error, Ecto.Changeset.t() | Rules.reason() | reason()}
  def dispatch(%__MODULE__{phase: phase} = game, :join, attrs)
      when phase in [:setup, :ready] do
    with {:ok, command} <- Command.build(:join, attrs),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: phase} = game, :leave, _attrs)
      when phase in [:setup, :ready],
      do: {:ok, game}

  def dispatch(%__MODULE__{phase: :ready} = game, :start, attrs) do
    with {:ok, command} <- Command.build(:start, attrs),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: phase}, _kind, _attrs)
      when phase in [:setup, :ready],
      do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :turn} = game, :join, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :turn} = game, :leave, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :turn} = game, :roll, attrs) do
    with {:ok, command} <- Command.build(:roll, attrs),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :turn}, _kind, _attrs),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :decision} = game, :join, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :decision} = game, :leave, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :decision} = game, :keep, attrs) do
    with {:ok, command} <- Command.build(:keep, attrs),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :decision} = game, :reroll, attrs) do
    with {:ok, command} <- Command.build(:reroll, attrs),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :decision}, _kind, _attrs),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :result} = game, :join, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :result} = game, :leave, _attrs), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :result} = game, :write, attrs) do
    with {:ok, command} <- Command.build(:write, attrs),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :result} = game, :skip, attrs) do
    with {:ok, command} <- Command.build(:skip, attrs),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :result}, _kind, _attrs),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :finished}, _kind, _attrs), do: {:error, :finished}

  def dispatch(%__MODULE__{}, _kind, _attrs), do: {:error, :invalid_phase}

  @impl D20.Game
  @spec finished?(t()) :: boolean()
  def finished?(%__MODULE__{phase: :finished}), do: true
  def finished?(%__MODULE__{}), do: false

  defp apply_command(game, %Command.Join{} = command) do
    game
    |> join_player(command.player_id)
    |> maybe_mark_ready()
  end

  defp apply_command(game, %Command.Start{}) do
    %{game | phase: :turn, cursor: 0}
  end

  defp apply_command(game, %Command.Roll{} = command) do
    game =
      game
      |> put_roll(command.colors, 1)
      |> reset_responses()

    %{game | phase: :decision}
  end

  defp apply_command(game, %Command.Keep{}) do
    %{game | phase: :result}
  end

  defp apply_command(game, %Command.Reroll{}) do
    game = put_roll(game, game.dices, 2)

    %{game | phase: :result}
  end

  defp apply_command(game, %Command.Write{} = command) do
    game
    |> put_entry(command)
    |> set_player_status(command.player_id, :wrote)
    |> resolve_turn()
  end

  defp apply_command(game, %Command.Skip{} = command) do
    game
    |> apply_skip_response(command.player_id)
    |> resolve_turn()
  end

  defp join_player(game, player_id) do
    if Map.has_key?(game.players, player_id) do
      game
    else
      %{
        game
        | order: game.order ++ [player_id],
          players:
            Map.put(game.players, player_id, %{
              rows: Map.new(Constants.colors(), &{&1, %{}}),
              penalties: 0,
              status: :ready
            })
      }
    end
  end

  defp maybe_mark_ready(%__MODULE__{phase: :setup} = game) do
    if Rules.ready_to_start?(game), do: %{game | phase: :ready}, else: game
  end

  defp maybe_mark_ready(game), do: game

  defp reset_responses(game) do
    %{game | players: reset_player_statuses(game.players)}
  end

  defp reset_player_statuses(players) do
    Map.new(players, fn {player_id, player} ->
      {player_id, %{player | status: :ready}}
    end)
  end

  defp put_roll(game, dices, attempt) do
    %{sum: sum, d6: values} = Dice.roll!(d6: length(dices))

    %{game | dices: dices, values: values, sum: sum, attempt: attempt}
  end

  defp put_entry(game, command) do
    put_in(game.players[command.player_id][:rows][command.row][command.slot], game.sum)
  end

  defp apply_skip_response(game, player_id) do
    if active_player?(game, player_id) do
      game
      |> update_in([Access.key!(:players), player_id, Access.key!(:penalties)], &(&1 + 1))
      |> set_player_status(player_id, :failed)
    else
      set_player_status(game, player_id, :passed)
    end
  end

  defp active_player?(%{order: order, cursor: cursor}, player_id) do
    Enum.at(order, cursor) == player_id
  end

  defp set_player_status(game, player_id, status) do
    put_in(game.players[player_id][:status], status)
  end

  defp resolve_turn(game) do
    cond do
      not Rules.turn_responses_complete?(game) -> game
      Rules.finished?(game) -> finish(game)
      true -> advance_turn(game)
    end
  end

  defp finish(game), do: %{game | phase: :finished, scores: score_players(game)}

  defp advance_turn(game) do
    next_cursor = rem(game.cursor + 1, length(game.order))

    %{game | phase: :turn, cursor: next_cursor, dices: [], values: [], sum: nil, attempt: 0}
  end

  defp score_players(game) do
    Map.new(game.order, &{&1, score_player(game, &1)})
  end

  defp score_player(game, player_id) do
    player = Map.fetch!(game.players, player_id)
    rows = Map.new(Constants.colors(), &{&1, score_row(player, &1)})
    bonuses = score_bonus_columns(player)
    penalties = player.penalties * Constants.penalty_points()

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
      player.rows[row] |> Map.fetch!(List.last(Constants.row_slots(row)))
    else
      map_size(player.rows[row])
    end
  end

  defp row_complete?(player, row) do
    map_size(player.rows[row]) == length(Constants.row_slots(row))
  end

  defp score_bonus_columns(player) do
    Constants.bonus_columns()
    |> Enum.filter(&column_complete?(player, &1))
    |> Enum.map(fn %{bonus: {row, slot}} -> get_in(player.rows, [row, slot]) end)
    |> Enum.sum()
  end

  defp column_complete?(player, column) do
    Enum.all?(column.cells, fn {row, slot} -> get_in(player.rows, [row, slot]) end)
  end
end
