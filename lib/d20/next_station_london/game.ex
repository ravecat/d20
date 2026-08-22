defmodule D20.NextStationLondon.Game do
  @moduledoc """
  Server-authoritative Next Station: London aggregate and state machine.
  """

  use D20.Game, server: D20.NextStationLondon.Server
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias D20.NextStationLondon.Command
  alias D20.NextStationLondon.Rules
  alias D20.NextStationLondon.Ruleset

  @phases [:setup, :reveal, :turn, :finished]
  @player_statuses [:ready, :pending, :submitted]
  @known_events ["join", "left", "start", "reveal", "draw", "pass"]
  @derive Jason.Encoder
  @primary_key false

  embedded_schema do
    field :phase, Ecto.Enum, values: @phases, default: :setup
    field :round, :integer, default: 0
    field :players, :map, default: %{}
    field :objectives, {:array, :string}
    field :powers, :map
    field :pencil_cycle, {:array, :string}, default: []
    field :remaining_deck, {:array, :string}, default: []
    field :draws, {:array, :map}, default: []
  end

  @type phase :: :setup | :reveal | :turn | :finished
  @type player_status :: :ready | :pending | :submitted
  @type line :: %{
          required(:edges) => [Ruleset.edge_id()],
          required(:power_used) => boolean(),
          required(:doubled_station) => Ruleset.station_id() | nil
        }
  @type player :: %{
          required(:status) => player_status(),
          required(:pencil_offset) => 0..3 | nil,
          required(:lines) => %{required(Ruleset.color()) => line()}
        }
  @type draw :: %{required(:cards) => [Ruleset.card_id()]}
  @type t :: %__MODULE__{
          phase: phase(),
          round: 0..4,
          players: %{optional(D20.Actors.Actor.id()) => player()},
          objectives: [Ruleset.objective_id()] | nil,
          powers: %{optional(Ruleset.color()) => Ruleset.power_id()} | nil,
          pencil_cycle: [Ruleset.color()],
          remaining_deck: [Ruleset.card_id()],
          draws: [draw()]
        }
  @type reason ::
          :finished
          | :invalid_phase
          | :unknown_command
          | Command.reason()
          | Rules.reason()

  @impl D20.Game
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params) do
    types = %{objectives: :boolean, powers: :boolean}

    {%{objectives: false, powers: false}, types}
    |> cast(params, Map.keys(types))
    |> validate_required(Map.keys(types))
  end

  @impl D20.Game
  @spec init(D20.Game.attrs()) :: {:ok, t()}
  def init(attrs) do
    {:ok,
     %__MODULE__{
       objectives: if(attrs.objectives, do: [], else: nil),
       powers: if(attrs.powers, do: %{}, else: nil)
     }}
  end

  @impl D20.Game
  @spec dispatch(t(), D20.Command.t()) :: {:ok, t()} | {:error, reason()}
  def dispatch(%__MODULE__{phase: :setup} = game, %D20.Command{event: "join"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, join_player(game, command.actor_id)}
    end
  end

  def dispatch(%__MODULE__{phase: :setup} = game, %D20.Command{event: "left"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, leave_player(game, command.actor_id)}
    end
  end

  def dispatch(%__MODULE__{phase: :setup} = game, %D20.Command{event: "start"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, start_game(game)}
    end
  end

  def dispatch(%__MODULE__{phase: :reveal} = game, %D20.Command{event: "reveal"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, reveal(game, command.attrs)}
    end
  end

  def dispatch(%__MODULE__{phase: :turn} = game, %D20.Command{event: event} = command)
      when event in ["draw", "pass"] do
    with {:ok, command} <- Command.validate(command),
         {:ok, player} <- Rules.resolve_action(game, command) do
      {:ok, commit_action(game, command.actor_id, player)}
    end
  end

  def dispatch(%__MODULE__{phase: phase} = game, %D20.Command{event: event})
      when event in ["join", "left"] and phase in [:reveal, :turn] do
    {:ok, game}
  end

  def dispatch(%__MODULE__{phase: :finished}, %D20.Command{}), do: {:error, :finished}

  def dispatch(%__MODULE__{}, %D20.Command{event: event}) when event in @known_events,
    do: {:error, :invalid_phase}

  def dispatch(%__MODULE__{}, %D20.Command{}), do: {:error, :unknown_command}

  @impl D20.Game
  @spec finished?(t()) :: boolean()
  def finished?(%__MODULE__{phase: :finished}), do: true
  def finished?(%__MODULE__{}), do: false

  @spec fetch_player(t(), D20.Actors.Actor.id()) :: {:ok, player()} | :error
  def fetch_player(%__MODULE__{players: players}, player_id), do: Map.fetch(players, player_id)

  @spec initial_line() :: line()
  def initial_line, do: %{edges: [], power_used: false, doubled_station: nil}

  @spec initial_player() :: player()
  def initial_player do
    lines = Map.new(Ruleset.colors(), &{&1, initial_line()})
    %{status: :ready, pencil_offset: nil, lines: lines}
  end

  defp join_player(game, player_id) do
    %{game | players: Map.put_new(game.players, player_id, initial_player())}
  end

  defp leave_player(game, player_id) do
    %{game | players: Map.delete(game.players, player_id)}
  end

  defp start_game(game) do
    players =
      Map.new(game.players, fn {player_id, player} ->
        {player_id, %{player | status: :ready, pencil_offset: nil}}
      end)

    %{
      game
      | phase: :reveal,
        round: 1,
        players: players,
        pencil_cycle: [],
        remaining_deck: [],
        draws: []
    }
  end

  defp reveal(game, attrs) do
    game
    |> maybe_commit_round_setup(attrs)
    |> reveal_instruction()
    |> set_player_statuses(:pending)
    |> Map.put(:phase, :turn)
  end

  defp maybe_commit_round_setup(%__MODULE__{draws: [], remaining_deck: []} = game, attrs) do
    game
    |> commit_first_round_assignments(attrs)
    |> Map.put(:remaining_deck, attrs.deck)
  end

  defp maybe_commit_round_setup(game, _attrs), do: game

  defp commit_first_round_assignments(%__MODULE__{round: 1} = game, attrs) do
    players =
      Map.new(game.players, fn {player_id, player} ->
        {player_id, %{player | pencil_offset: Map.fetch!(attrs.pencil_offsets, player_id)}}
      end)

    %{
      game
      | players: players,
        pencil_cycle: attrs.pencil_cycle,
        objectives: attrs.objectives || game.objectives,
        powers: attrs.powers || game.powers
    }
  end

  defp commit_first_round_assignments(game, _attrs), do: game

  defp commit_action(game, player_id, player) do
    game = put_in(game.players[player_id], %{player | status: :submitted})

    if Rules.turn_complete?(game) do
      advance_instruction_or_round(game)
    else
      game
    end
  end

  defp advance_instruction_or_round(game) do
    if Rules.current_instruction(game).final do
      finish_or_prepare_next_round(game)
    else
      %{game | phase: :reveal}
    end
  end

  defp finish_or_prepare_next_round(%__MODULE__{round: 4} = game) do
    %{game | phase: :finished, remaining_deck: []}
  end

  defp finish_or_prepare_next_round(game) do
    game
    |> Map.put(:phase, :reveal)
    |> Map.put(:round, game.round + 1)
    |> Map.put(:remaining_deck, [])
    |> Map.put(:draws, [])
    |> set_player_statuses(:ready)
  end

  defp reveal_instruction(%__MODULE__{remaining_deck: [card_id | remaining]} = game) do
    {cards, remaining} =
      if Ruleset.railroad_switch?(card_id) do
        [destination_id | remaining] = remaining
        {[card_id, destination_id], remaining}
      else
        {[card_id], remaining}
      end

    %{game | remaining_deck: remaining, draws: game.draws ++ [%{cards: cards}]}
  end

  defp set_player_statuses(game, status) when status in @player_statuses do
    players = Map.new(game.players, fn {id, player} -> {id, %{player | status: status}} end)
    %{game | players: players}
  end
end
