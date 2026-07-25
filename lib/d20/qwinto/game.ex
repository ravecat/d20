defmodule D20.Qwinto.Game do
  @moduledoc """
  Qwinto game aggregate and reducer.
  """

  use D20.Game

  use Ecto.Schema

  alias D20.Dice
  alias D20.Qwinto.Command
  alias D20.Qwinto.Rules
  alias D20.Qwinto.Ruleset

  @phases [:setup, :ready, :roll, :write_or_pass, :result, :finished]
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
  @type phase :: :setup | :ready | :roll | :write_or_pass | :result | :finished
  @type player_status :: :idle | :pending | :wrote | :skipped
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
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

  @impl D20.Game
  @spec init(D20.Game.attrs()) :: {:ok, t()}
  def init(_attrs), do: {:ok, %__MODULE__{}}

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

  def dispatch(%__MODULE__{phase: phase} = game, %D20.Command{event: "left"})
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

  def dispatch(%__MODULE__{phase: :roll} = game, %D20.Command{event: "join"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :roll} = game, %D20.Command{event: "left"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :roll} = game, %D20.Command{event: "roll"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :roll}, %D20.Command{}),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :write_or_pass} = game, %D20.Command{event: "join"}),
    do: {:ok, game}

  def dispatch(%__MODULE__{phase: :write_or_pass} = game, %D20.Command{event: "left"}),
    do: {:ok, game}

  def dispatch(%__MODULE__{phase: :write_or_pass} = game, %D20.Command{event: event} = command)
      when event in ["reroll", "write", "penalize"] do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :write_or_pass}, %D20.Command{}),
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{phase: :result} = game, %D20.Command{event: "join"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :result} = game, %D20.Command{event: "left"}), do: {:ok, game}

  def dispatch(%__MODULE__{phase: :result} = game, %D20.Command{event: "write"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :result} = game, %D20.Command{event: event} = command)
      when event in ["pass", "penalize"] do
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

  defp apply_command(%__MODULE__{phase: :ready} = game, %D20.Command{event: "start"}) do
    active = active_player_id(game, 0)

    %{game | phase: :roll, cursor: 0}
    |> set_player_statuses(:idle)
    |> set_player_statuses([{active, :pending}])
  end

  defp apply_command(%__MODULE__{phase: :roll} = game, %D20.Command{
         event: "roll",
         attrs: %{colors: colors}
       }) do
    active = active_player_id(game, game.cursor)

    game
    |> apply_roll(colors, 1)
    |> set_player_statuses([{active, :pending}])
    |> apply_phase(:write_or_pass)
  end

  defp apply_command(%__MODULE__{phase: :write_or_pass} = game, %D20.Command{event: "reroll"}) do
    game
    |> apply_roll(Map.keys(game.dices), 2)
    |> apply_phase(:result)
    |> set_player_statuses(:pending)
  end

  defp apply_command(%__MODULE__{phase: :write_or_pass} = game, %D20.Command{
         event: "write",
         actor_id: actor_id,
         attrs: %{row: row, slot: slot}
       }) do
    pending_players =
      for player_id <- game.order, player_id != actor_id, do: {player_id, :pending}

    game
    |> apply_result(actor_id, row, slot)
    |> apply_phase(:result)
    |> set_player_statuses([{actor_id, :wrote} | pending_players])
  end

  defp apply_command(%__MODULE__{phase: :result} = game, %D20.Command{
         event: "write",
         actor_id: actor_id,
         attrs: %{row: row, slot: slot}
       }) do
    game
    |> apply_result(actor_id, row, slot)
    |> set_player_statuses([{actor_id, :wrote}])
    |> maybe_resolve_turn()
  end

  defp apply_command(%__MODULE__{phase: :result} = game, %D20.Command{
         event: "pass",
         actor_id: actor_id
       }) do
    game
    |> set_player_statuses([{actor_id, :skipped}])
    |> maybe_resolve_turn()
  end

  defp apply_command(%__MODULE__{phase: :write_or_pass} = game, %D20.Command{
         event: "penalize",
         actor_id: actor_id
       }) do
    pending_players =
      for player_id <- game.order, player_id != actor_id, do: {player_id, :pending}

    game
    |> apply_penalty(actor_id)
    |> apply_phase(:result)
    |> set_player_statuses(pending_players)
  end

  defp apply_command(%__MODULE__{phase: :result} = game, %D20.Command{
         event: "penalize",
         actor_id: actor_id
       }) do
    game
    |> apply_penalty(actor_id)
    |> maybe_resolve_turn()
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
              status: :idle
            })
      }
    end
  end

  defp maybe_mark_ready(%__MODULE__{phase: :setup} = game) do
    if Rules.ready_to_start?(game), do: %{game | phase: :ready}, else: game
  end

  defp maybe_mark_ready(game), do: game

  defp active_player_id(game, cursor) do
    Enum.at(game.order, cursor)
  end

  defp apply_roll(game, dices, attempt) do
    %{sum: sum, d6: values} = Dice.roll!(d6: length(dices))
    dices = dices |> Enum.zip(values) |> Map.new()

    %{game | dices: dices, sum: sum, attempt: attempt}
  end

  defp apply_phase(game, phase) do
    %{game | phase: phase}
  end

  defp apply_result(game, actor_id, row, slot) do
    put_in(game.players[actor_id][:rows][row][slot], game.sum)
  end

  defp apply_penalty(game, player_id) do
    game
    |> update_in([Access.key!(:players), player_id, Access.key!(:penalties)], &(&1 + 1))
    |> set_player_statuses([{player_id, :skipped}])
  end

  defp set_player_statuses(game, status) when status in [:idle, :pending, :wrote, :skipped] do
    players =
      Map.new(game.players, fn {player_id, player} -> {player_id, %{player | status: status}} end)

    %{game | players: players}
  end

  defp set_player_statuses(game, assignments) when is_map(assignments) or is_list(assignments) do
    players =
      Enum.reduce(assignments, game.players, fn {player_id, status}, players ->
        Map.update!(players, player_id, fn player -> %{player | status: status} end)
      end)

    %{game | players: players}
  end

  defp maybe_resolve_turn(game) do
    cond do
      not Rules.turn_complete?(game) -> game
      Rules.finished?(game) -> finish(game)
      true -> advance_turn(game)
    end
  end

  defp finish(game), do: %{game | phase: :finished, scores: score_players(game)}

  defp advance_turn(game) do
    next_cursor = rem(game.cursor + 1, length(game.order))
    active = active_player_id(game, next_cursor)

    %{game | phase: :roll, cursor: next_cursor, dices: %{}, sum: nil, attempt: 0}
    |> set_player_statuses(:idle)
    |> set_player_statuses([{active, :pending}])
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
