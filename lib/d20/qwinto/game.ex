defmodule D20.Qwinto.Game do
  @moduledoc """
  Qwinto game aggregate and reducer.
  """

  @behaviour D20.Game

  use Ecto.Schema

  alias D20.Dice
  alias D20.Qwinto.Command
  alias D20.Qwinto.Rules
  alias D20.Qwinto.Ruleset

  @phases [:setup, :ready, :turn, :decision, :result, :finished]
  @derive Jason.Encoder
  @primary_key false

  embedded_schema do
    field :phase, Ecto.Enum,
      values: @phases,
      default: :setup

    field :order, {:array, :string}, default: []
    field :cursor, :integer, default: 0
    field :players, :map, default: %{}
    field :dices, :map, default: %{}
    field :sum, :integer
    field :attempt, :integer, default: 0
    field :scores, :map, default: %{}
  end

  @type player_id :: D20.Actors.Actor.id()
  @type roll :: %{optional(Ruleset.color()) => pos_integer()}
  @type phase :: :setup | :ready | :turn | :decision | :result | :finished
  @type player_status :: :ready | :wrote | :failed | :passed
  @type player :: %{
          required(:rows) => %{
            required(Ruleset.color()) => %{optional(non_neg_integer()) => integer()}
          },
          required(:penalties) => non_neg_integer(),
          required(:status) => player_status()
        }
  @type score :: %{
          required(:player_id) => player_id(),
          required(:rows) => %{required(Ruleset.color()) => integer()},
          required(:bonuses) => integer(),
          required(:penalties) => integer(),
          required(:total) => integer()
        }
  @type t :: %__MODULE__{
          phase: phase(),
          order: [player_id()],
          cursor: non_neg_integer(),
          players: %{optional(player_id()) => player()},
          dices: roll(),
          sum: integer() | nil,
          attempt: 0 | 1 | 2,
          scores: %{optional(player_id()) => score()}
        }
  @type reason :: :finished | :invalid_phase

  @impl D20.Game
  @spec init() :: {:ok, t()}
  def init, do: {:ok, %__MODULE__{}}

  @impl D20.Game
  @spec dispatch(t(), D20.Command.t()) ::
          {:ok, t()}
          | {:error, Ecto.Changeset.t() | Rules.reason() | Command.reason() | reason()}
  def dispatch(%__MODULE__{phase: phase} = game, %D20.Command{event: "join"} = command)
      when phase in [:setup, :ready] do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: phase} = game, %D20.Command{event: "leave"})
      when phase in [:setup, :ready],
      do: {:ok, game}

  def dispatch(%__MODULE__{phase: :ready} = game, %D20.Command{event: "start"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: phase}, %D20.Command{})
      when phase in [:setup, :ready],
      do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :turn} = game, %D20.Command{event: "join"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :turn} = game, %D20.Command{event: "leave"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :turn} = game, %D20.Command{event: "roll"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :turn}, %D20.Command{}),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :decision} = game, %D20.Command{event: "join"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :decision} = game, %D20.Command{event: "leave"}),
    do: {:ok, game}

  def dispatch(%__MODULE__{phase: :decision} = game, %D20.Command{event: "keep"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :decision} = game, %D20.Command{event: "reroll"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :decision}, %D20.Command{}),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :result} = game, %D20.Command{event: "join"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :result} = game, %D20.Command{event: "leave"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :result} = game, %D20.Command{event: "write"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :result} = game, %D20.Command{event: event} = command)
      when event in ["skip", "take_penalty"] do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :result}, %D20.Command{}),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :finished}, %D20.Command{}), do: {:error, :finished}

  def dispatch(%__MODULE__{}, %D20.Command{}), do: {:error, :invalid_phase}

  @impl D20.Game
  @spec finished?(t()) :: boolean()
  def finished?(%__MODULE__{phase: :finished}), do: true
  def finished?(%__MODULE__{}), do: false

  @spec active_player?(t(), player_id()) :: boolean()
  def active_player?(%__MODULE__{order: order, cursor: cursor}, player_id) do
    Enum.at(order, cursor) == player_id
  end

  defp apply_command(game, %D20.Command{event: "join", actor_id: actor_id}) do
    game
    |> join_player(actor_id)
    |> maybe_mark_ready()
  end

  defp apply_command(game, %D20.Command{event: "start"}) do
    %{game | phase: :turn, cursor: 0}
  end

  defp apply_command(game, %D20.Command{event: "roll", attrs: %{colors: colors}}) do
    game = game |> put_roll(colors, 1) |> reset_responses()

    %{game | phase: :decision}
  end

  defp apply_command(game, %D20.Command{event: "keep"}) do
    %{game | phase: :result}
  end

  defp apply_command(game, %D20.Command{event: "reroll"}) do
    game = put_roll(game, Map.keys(game.dices), 2)

    %{game | phase: :result}
  end

  defp apply_command(game, %D20.Command{
         event: "write",
         actor_id: actor_id,
         attrs: %{row: row, slot: slot}
       }) do
    game
    |> put_entry(actor_id, row, slot)
    |> set_player_status(actor_id, :wrote)
    |> resolve_turn()
  end

  defp apply_command(game, %D20.Command{event: "skip", actor_id: actor_id}) do
    game
    |> apply_skip(actor_id)
    |> resolve_turn()
  end

  defp apply_command(game, %D20.Command{event: "take_penalty", actor_id: actor_id}) do
    game
    |> apply_penalty(actor_id)
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
              rows: Map.new(Ruleset.colors(), &{&1, %{}}),
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
    Map.new(players, fn {player_id, player} -> {player_id, %{player | status: :ready}} end)
  end

  defp put_roll(game, dices, attempt) do
    %{sum: sum, d6: values} = Dice.roll!(d6: length(dices))
    dices = dices |> Enum.zip(values) |> Map.new()

    %{game | dices: dices, sum: sum, attempt: attempt}
  end

  defp put_entry(game, actor_id, row, slot) do
    put_in(game.players[actor_id][:rows][row][slot], game.sum)
  end

  defp apply_skip(game, player_id) do
    if active_player?(game, player_id) do
      apply_penalty(game, player_id)
    else
      set_player_status(game, player_id, :passed)
    end
  end

  defp apply_penalty(game, player_id) do
    game
    |> update_in([Access.key!(:players), player_id, Access.key!(:penalties)], &(&1 + 1))
    |> set_player_status(player_id, :failed)
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

    %{game | phase: :turn, cursor: next_cursor, dices: %{}, sum: nil, attempt: 0}
  end

  defp score_players(game) do
    Map.new(game.order, &{&1, score_player(game, &1)})
  end

  defp score_player(game, player_id) do
    player = Map.fetch!(game.players, player_id)
    rows = Map.new(Ruleset.colors(), &{&1, score_row(player, &1)})
    bonuses = score_bonus_columns(player)
    penalties = player.penalties * Ruleset.penalty_points()

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
      player.rows[row] |> Map.fetch!(Ruleset.final_slot(row))
    else
      map_size(player.rows[row])
    end
  end

  defp row_complete?(player, row) do
    map_size(player.rows[row]) == Ruleset.row_slot_count(row)
  end

  defp score_bonus_columns(player) do
    Ruleset.bonus_columns()
    |> Enum.filter(&column_complete?(player, &1))
    |> Enum.map(fn %{bonus: {row, slot}} -> get_in(player.rows, [row, slot]) end)
    |> Enum.sum()
  end

  defp column_complete?(player, column) do
    Enum.all?(column.cells, fn {row, slot} -> get_in(player.rows, [row, slot]) end)
  end
end
