defmodule D20.KoalaRescueClub.Game do
  @moduledoc """
  Koala Rescue Club game aggregate and reducer.
  """

  use D20.Game, server: D20.KoalaRescueClub.Server
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]
  import Kernel, except: [apply: 2]

  alias D20.Dice
  alias D20.KoalaRescueClub.Command
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset

  @phases [:setup, :ready, :roll, :submit, :finished]
  @modes [:solo, :multiplayer]
  @derive Jason.Encoder
  @primary_key false

  embedded_schema do
    field :phase, Ecto.Enum,
      values: @phases,
      default: :setup

    field :sheet, Ecto.Enum, values: [:dharug, :yugambeh], default: :dharug
    field :mode, Ecto.Enum, values: @modes
    field :round, :integer, default: 1
    field :turn, :integer, default: 0
    field :players, :map, default: %{}
    field :roll, :map
    field :scores, :map, default: %{}
  end

  @type player_id :: D20.Actors.Actor.id()
  @type volunteer :: :available | :locked | :used
  @type player_status :: :ready | :pending | :submitted
  @type award :: :large | :small
  @type skybridge :: %{required(:from) => Ruleset.area(), required(:to) => Ruleset.area()}
  @type sheet :: %{
          required(:trees) => [Ruleset.cell()],
          required(:koalas) => [Ruleset.cell()],
          required(:areas) => %{optional(Ruleset.area()) => true},
          required(:volunteers) => [volunteer()],
          required(:hospitals) => %{optional(atom()) => non_neg_integer()},
          required(:skybridges) => [skybridge()],
          required(:bonuses) => [Ruleset.bonus_ref()]
        }
  @type phase :: :setup | :ready | :roll | :submit | :finished
  @type mode :: :solo | :multiplayer
  @type turn :: 0 | Ruleset.turn()
  @type score :: %{required(:total) => integer(), required(:rank) => Ruleset.rank() | nil}
  @type round :: %{
          required(:trees) => non_neg_integer(),
          required(:koalas) => non_neg_integer(),
          required(:hospitals) => integer(),
          required(:total) => integer()
        }
  @type player :: %{
          required(:status) => player_status(),
          required(:sheet) => sheet(),
          required(:badges) => %{optional(Ruleset.badge()) => award()},
          required(:rounds) => [round()],
          required(:turns) => [Ruleset.die_value()]
        }
  @type roll :: %{required(:value) => Ruleset.die_value()}
  @type t :: %__MODULE__{
          phase: phase(),
          sheet: Ruleset.id(),
          mode: mode() | nil,
          round: Ruleset.round(),
          turn: turn(),
          players: %{optional(player_id()) => player()},
          roll: roll() | nil,
          scores: %{optional(player_id()) => score()}
        }
  @type reason :: :finished | :invalid_phase
  @typep players :: %{optional(player_id()) => player()}
  @typep transition ::
           {:player_joined, players(), phase()}
           | {:player_left, players(), phase()}
           | {:game_started, mode()}
           | {:die_rolled, Ruleset.die_value()}
           | {:turn_submitted, player_id(), player()}
           | {:badges_awarded, players()}
           | {:round_scored, players()}
           | {:turn_advanced, Ruleset.round(), Ruleset.turn()}
           | {:game_finished, %{optional(player_id()) => score()}}

  @impl D20.Game
  @spec init(D20.Game.attrs()) :: {:ok, t()}
  def init(attrs), do: {:ok, struct(__MODULE__, attrs)}

  @impl D20.Game
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params) do
    types = %{sheet: Ecto.ParameterizedType.init(Ecto.Enum, values: Ruleset.sheets())}

    {%{sheet: :dharug}, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:sheet])
  end

  @impl D20.Game
  @spec dispatch(t(), D20.Command.t()) ::
          {:ok, t()}
          | {:error, Ecto.Changeset.t() | Rules.reason() | Command.reason() | reason()}
  def dispatch(%__MODULE__{} = game, %D20.Command{} = command) do
    with {:ok, transitions} <- execute(game, command) do
      game = Enum.reduce(transitions, game, fn transition, game -> apply(game, transition) end)
      {:ok, game}
    end
  end

  defp execute(%__MODULE__{phase: phase} = game, %D20.Command{event: "join"} = command)
       when phase in [:setup, :ready] do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      players =
        Map.put_new_lazy(game.players, command.actor_id, fn ->
          rulesheet = Ruleset.sheet!(game.sheet)

          volunteers =
            List.duplicate(:available, rulesheet.volunteers) ++
              List.duplicate(:locked, Ruleset.volunteer() - rulesheet.volunteers)

          sheet = %{
            trees: [],
            koalas: [],
            areas:
              rulesheet.areas
              |> Enum.filter(fn {_id, area} -> area.access end)
              |> Map.new(fn {id, _area} -> {id, true} end),
            volunteers: volunteers,
            hospitals: Map.new(rulesheet.hospitals, fn {id, _hospital} -> {id, 0} end),
            skybridges: [],
            bonuses: []
          }

          %{status: :ready, sheet: sheet, rounds: [], badges: %{}, turns: []}
        end)

      phase = if map_size(players) in Ruleset.player_count_range(), do: :ready, else: :setup
      {:ok, [{:player_joined, players, phase}]}
    end
  end

  defp execute(%__MODULE__{phase: phase}, %D20.Command{event: event})
       when event in ["join", "left"] and phase in [:roll, :submit],
       do: {:ok, []}

  defp execute(%__MODULE__{phase: phase} = game, %D20.Command{event: "left"} = command)
       when phase in [:setup, :ready] do
    players = Map.delete(game.players, command.actor_id)
    phase = if map_size(players) in Ruleset.player_count_range(), do: :ready, else: :setup

    {:ok, [{:player_left, players, phase}]}
  end

  defp execute(%__MODULE__{phase: :ready} = game, %D20.Command{event: "start"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      mode =
        case map_size(game.players) do
          1 -> :solo
          count when count > 1 -> :multiplayer
        end

      {:ok, [{:game_started, mode}]}
    end
  end

  defp execute(%__MODULE__{phase: :roll} = game, %D20.Command{event: "roll"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      %{d6: [value]} = Dice.roll!(d6: 1)
      {:ok, [{:die_rolled, value}]}
    end
  end

  defp execute(%__MODULE__{phase: :submit} = game, %D20.Command{} = command) do
    with {:ok, command} <- Command.validate(command),
         {:ok, player} <- Rules.resolve_turn(game, command) do
      player = %{player | turns: player.turns ++ [command.attrs.die_value]}
      players = Map.put(game.players, command.actor_id, player)
      submitted = {:turn_submitted, command.actor_id, player}

      transitions =
        if Enum.all?(players, fn {_player_id, player} -> player.status == :submitted end) do
          rulesheet = Ruleset.sheet!(game.sheet)
          players = award_badges(rulesheet, game.mode, game.round, players)
          transitions = [submitted, {:badges_awarded, players}]

          {players, transitions} =
            if Ruleset.round_end_turn?(game.turn) do
              players = score_round(rulesheet, players)
              {players, transitions ++ [{:round_scored, players}]}
            else
              {players, transitions}
            end

          if Ruleset.final_turn?(game.turn) do
            scores = score_players(game.mode, rulesheet, players)
            transitions ++ [{:game_finished, scores}]
          else
            next_turn = game.turn + 1
            {:ok, next_round} = Ruleset.round(next_turn)

            transitions ++ [{:turn_advanced, next_round, next_turn}]
          end
        else
          [submitted]
        end

      {:ok, transitions}
    end
  end

  defp execute(%__MODULE__{phase: :finished}, %D20.Command{}), do: {:error, :finished}
  defp execute(%__MODULE__{}, %D20.Command{}), do: {:error, :invalid_phase}

  @impl D20.Game
  @spec preview(t(), D20.Command.t()) ::
          {:ok, Rules.draft_details()}
          | {:error, Ecto.Changeset.t() | Rules.reason() | Command.reason() | reason()}
  def preview(%__MODULE__{} = game, %D20.Command{event: "draft"} = command) do
    with {:ok, command} <- Command.validate(command) do
      Rules.draft_details(game, command)
    end
  end

  def preview(%__MODULE__{}, %D20.Command{}), do: {:error, :unknown_command}

  @impl D20.Game
  @spec finished?(t()) :: boolean()
  def finished?(%__MODULE__{phase: :finished}), do: true
  def finished?(%__MODULE__{}), do: false

  @spec apply(t(), transition()) :: t()
  defp apply(game, {:player_joined, players, phase}) do
    game
    |> Pathex.set!(path(:players), players)
    |> Pathex.set!(path(:phase), phase)
  end

  defp apply(game, {:player_left, players, phase}) do
    game
    |> Pathex.set!(path(:players), players)
    |> Pathex.set!(path(:phase), phase)
  end

  defp apply(game, {:game_started, mode}) do
    each_player = path(:players) ~> all()

    game
    |> Pathex.set!(path(:phase), :roll)
    |> Pathex.set!(path(:mode), mode)
    |> Pathex.set!(path(:round), 1)
    |> Pathex.set!(path(:turn), 1)
    |> Pathex.set!(each_player ~> path(:status), :ready)
    |> Pathex.set!(each_player ~> path(:rounds), [])
    |> Pathex.set!(each_player ~> path(:badges), %{})
    |> Pathex.set!(each_player ~> path(:turns), [])
  end

  defp apply(game, {:die_rolled, value}) do
    game
    |> Pathex.set!(path(:phase), :submit)
    |> Pathex.set!(path(:roll), %{value: value})
    |> Pathex.set!(path(:players) ~> all() ~> path(:status), :pending)
  end

  defp apply(game, {:turn_submitted, player_id, player}) do
    Pathex.set!(game, path(:players) ~> path(player_id), player)
  end

  defp apply(game, {:badges_awarded, players}) do
    Pathex.set!(game, path(:players), players)
  end

  defp apply(game, {:round_scored, players}) do
    Pathex.set!(game, path(:players), players)
  end

  defp apply(game, {:turn_advanced, round, turn}) do
    game
    |> Pathex.set!(path(:phase), :roll)
    |> Pathex.set!(path(:round), round)
    |> Pathex.set!(path(:turn), turn)
    |> Pathex.set!(path(:roll), nil)
    |> Pathex.set!(path(:players) ~> all() ~> path(:status), :ready)
  end

  defp apply(game, {:game_finished, scores}) do
    game
    |> Pathex.set!(path(:phase), :finished)
    |> Pathex.set!(path(:scores), scores)
  end

  defp award_badges(rulesheet, :solo, round, players) do
    [{player_id, player}] = Map.to_list(players)

    player =
      Enum.reduce(rulesheet.badges, player, fn {badge_id, badge}, player ->
        if Map.has_key?(player.badges, badge_id) or
             not Rules.badge_satisfied?(rulesheet, player.sheet, badge) do
          player
        else
          award = if round == 1, do: :large, else: :small
          %{player | badges: Map.put(player.badges, badge_id, award)}
        end
      end)

    Map.put(players, player_id, player)
  end

  defp award_badges(rulesheet, :multiplayer, _round, players) do
    Enum.reduce(rulesheet.badges, players, fn {badge_id, badge}, players ->
      large_awarded? =
        Enum.any?(players, fn {_player_id, player} ->
          Map.get(player.badges, badge_id) == :large
        end)

      {player_ids, award} =
        if large_awarded? do
          player_ids =
            players
            |> Enum.filter(fn {_player_id, player} ->
              not Map.has_key?(player.badges, badge_id) and
                Rules.badge_satisfied?(rulesheet, player.sheet, badge)
            end)
            |> Enum.map(fn {player_id, _player} -> player_id end)

          {player_ids, :small}
        else
          player_ids =
            players
            |> Enum.filter(fn {_player_id, player} ->
              Rules.badge_satisfied?(rulesheet, player.sheet, badge)
            end)
            |> Enum.map(fn {player_id, _player} -> player_id end)

          {player_ids, :large}
        end

      Enum.reduce(player_ids, players, fn player_id, players ->
        Map.update!(players, player_id, fn player ->
          %{player | badges: Map.put(player.badges, badge_id, award)}
        end)
      end)
    end)
  end

  defp score_round(rulesheet, players) do
    Map.new(players, fn {player_id, player} ->
      trees =
        rulesheet.areas
        |> Map.keys()
        |> Enum.count(&Ruleset.trees_complete?(rulesheet, player.sheet, &1))

      koalas =
        rulesheet.areas
        |> Map.keys()
        |> Enum.count(&Ruleset.koalas_complete?(rulesheet, player.sheet, &1))

      hospitals =
        rulesheet.hospitals
        |> Enum.map(fn {hospital_id, hospital} ->
          filled = Map.get(player.sheet.hospitals, hospital_id, 0)
          hospital = hospital |> Map.take([:size, :score, :penalty]) |> Map.put(:filled, filled)
          {:ok, score} = Ruleset.score_hospital(hospital)
          score
        end)
        |> Enum.sum()

      round = %{
        trees: trees,
        koalas: koalas,
        hospitals: hospitals,
        total: trees + koalas + hospitals
      }

      {player_id, %{player | rounds: player.rounds ++ [round]}}
    end)
  end

  defp score_players(mode, rulesheet, players) do
    Map.new(players, fn {player_id, player} ->
      badge_total =
        Enum.reduce(player.badges, 0, fn {badge_id, award}, total ->
          badge = Map.fetch!(rulesheet.badges, badge_id)
          total + Map.fetch!(badge.awards, award)
        end)

      round_total = player.rounds |> Enum.map(& &1.total) |> Enum.sum()
      total = round_total + badge_total

      rank =
        if mode == :solo do
          {:ok, %{rank: rank}} = Ruleset.solo_rating(rulesheet, total)
          rank
        end

      {player_id, %{total: total, rank: rank}}
    end)
  end
end
