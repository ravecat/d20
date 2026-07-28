defmodule D20.KoalaRescueClub.Game do
  @moduledoc """
  Koala Rescue Club game aggregate and reducer.
  """

  use D20.Game, server: D20.KoalaRescueClub.Server
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias D20.Dice
  alias D20.KoalaRescueClub.Command
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset

  @phases [:setup, :ready, :roll, :submit, :finished]
  @modes [:solo, :multiplayer]
  @player_statuses [:ready, :pending, :submitted]
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
  def dispatch(%__MODULE__{phase: phase} = game, %D20.Command{event: "join"} = command)
      when phase in [:setup, :ready] do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: phase} = game, %D20.Command{event: event})
      when event in ["join", "left"] and phase in [:roll, :submit],
      do: {:ok, game}

  def dispatch(%__MODULE__{phase: phase} = game, %D20.Command{event: "left", actor_id: actor_id})
      when phase in [:setup, :ready] do
    {:ok, game |> leave_player(actor_id) |> refresh_setup_phase()}
  end

  def dispatch(%__MODULE__{phase: :ready} = game, %D20.Command{event: "start"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :roll} = game, %D20.Command{event: "roll"} = command) do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :submit} = game, %D20.Command{} = command) do
    with {:ok, command} <- Command.validate(command),
         {:ok, player} <- Rules.resolve_turn(game, command) do
      {:ok, apply_submit(game, command, player)}
    end
  end

  def dispatch(%__MODULE__{phase: :finished}, %D20.Command{}), do: {:error, :finished}
  def dispatch(%__MODULE__{}, %D20.Command{}), do: {:error, :invalid_phase}

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

  @doc "Fetches a player from the game by id."
  @spec fetch_player(t(), player_id()) :: {:ok, player()} | :error
  def fetch_player(%__MODULE__{players: players}, player_id), do: Map.fetch(players, player_id)

  defp apply_command(game, %D20.Command{event: "join", actor_id: actor_id}) do
    game
    |> join_player(actor_id)
    |> refresh_setup_phase()
  end

  defp apply_command(%__MODULE__{phase: :ready} = game, %D20.Command{event: "start"}) do
    players =
      Map.new(game.players, fn {player_id, player} ->
        {player_id, Map.merge(player, %{status: :ready, rounds: [], badges: %{}, turns: []})}
      end)

    %{game | phase: :roll, mode: game_mode(game.players), round: 1, turn: 1, players: players}
  end

  defp apply_command(%__MODULE__{phase: :roll} = game, %D20.Command{event: "roll"}) do
    %{d6: [value]} = Dice.roll!(d6: 1)

    set_player_statuses(%{game | phase: :submit, roll: %{value: value}}, :pending)
  end

  defp apply_submit(
         %__MODULE__{phase: :submit} = game,
         %D20.Command{event: "submit", actor_id: actor_id, attrs: %{die_value: value}},
         player
       ) do
    player = record_turn(player, value)

    game
    |> put_in([Access.key!(:players), actor_id], player)
    |> maybe_resolve_turn()
  end

  defp join_player(game, player_id) do
    if Map.has_key?(game.players, player_id) do
      game
    else
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

      player = %{status: :ready, sheet: sheet, rounds: [], badges: %{}, turns: []}

      %{game | players: Map.put(game.players, player_id, player)}
    end
  end

  defp leave_player(game, player_id) do
    %{game | players: Map.delete(game.players, player_id)}
  end

  defp refresh_setup_phase(game) do
    phase = if Rules.ready_to_start?(game), do: :ready, else: :setup

    %{game | phase: phase}
  end

  defp game_mode(players) when map_size(players) == 1, do: :solo
  defp game_mode(players) when map_size(players) > 1, do: :multiplayer

  defp record_turn(player, value) do
    Map.put(player, :turns, Map.get(player, :turns, []) ++ [value])
  end

  defp maybe_resolve_turn(game) do
    if Rules.turn_complete?(game) do
      game
      |> award_badges()
      |> maybe_score_round()
      |> maybe_finish()
    else
      game
    end
  end

  defp maybe_score_round(game) do
    if Ruleset.round_end_turn?(game.turn), do: score_round(game), else: game
  end

  defp maybe_finish(game) do
    if Ruleset.final_turn?(game.turn) do
      %{game | phase: :finished, scores: score_players(game)}
    else
      {:ok, next_round} = Ruleset.round(game.turn + 1)

      set_player_statuses(
        %{game | phase: :roll, round: next_round, turn: game.turn + 1, roll: nil},
        :ready
      )
    end
  end

  defp score_round(game) do
    rulesheet = Ruleset.sheet!(game.sheet)

    players =
      Map.new(game.players, fn {player_id, player} ->
        round = score_round_for_player(rulesheet, player)

        {player_id, %{player | rounds: player.rounds ++ [round]}}
      end)

    %{game | players: players}
  end

  defp score_round_for_player(rulesheet, player) do
    trees = score_complete_areas(rulesheet, player.sheet, &Ruleset.trees_complete?/3)
    koalas = score_complete_areas(rulesheet, player.sheet, &Ruleset.koalas_complete?/3)

    hospitals = rulesheet.hospitals |> Enum.map(&score_hospital(player.sheet, &1)) |> Enum.sum()

    %{trees: trees, koalas: koalas, hospitals: hospitals, total: trees + koalas + hospitals}
  end

  defp score_complete_areas(rulesheet, player_sheet, complete?) do
    rulesheet.areas
    |> Map.keys()
    |> Enum.count(&complete?.(rulesheet, player_sheet, &1))
  end

  defp score_hospital(player_sheet, {hospital_id, hospital}) do
    filled = Map.get(player_sheet.hospitals, hospital_id, 0)

    hospital = hospital |> Map.take([:size, :score, :penalty]) |> Map.put(:filled, filled)

    {:ok, score} = Ruleset.score_hospital(hospital)
    score
  end

  defp award_badges(game) do
    rulesheet = Ruleset.sheet!(game.sheet)

    award_badges(game, rulesheet)
  end

  defp award_badges(%__MODULE__{mode: :solo} = game, rulesheet),
    do: award_solo_badges(game, rulesheet)

  defp award_badges(%__MODULE__{mode: :multiplayer} = game, rulesheet),
    do: award_multiplayer_badges(game, rulesheet)

  defp award_solo_badges(game, map) do
    [{player_id, player}] = Map.to_list(game.players)

    player =
      Enum.reduce(map.badges, player, fn {badge_id, badge}, player ->
        if Map.has_key?(player.badges, badge_id) or
             not Rules.badge_satisfied?(map, player.sheet, badge) do
          player
        else
          award = if game.round == 1, do: :large, else: :small
          put_badge(player, badge_id, award)
        end
      end)

    put_in(game.players[player_id], player)
  end

  defp award_multiplayer_badges(game, map) do
    Enum.reduce(map.badges, game, fn {badge_id, badge}, game ->
      if large_badge_awarded?(game, badge_id) do
        award_late_badges(game, map, badge_id, badge)
      else
        first_achievers =
          game.players
          |> Enum.filter(fn {_player_id, player} ->
            Rules.badge_satisfied?(map, player.sheet, badge)
          end)
          |> Enum.map(fn {player_id, _player} -> player_id end)

        if first_achievers == [] do
          game
        else
          update_players(game, first_achievers, fn player ->
            put_badge(player, badge_id, :large)
          end)
        end
      end
    end)
  end

  defp award_late_badges(game, map, badge_id, badge) do
    late_achievers =
      game.players
      |> Enum.filter(fn {_player_id, player} ->
        not Map.has_key?(player.badges, badge_id) and
          Rules.badge_satisfied?(map, player.sheet, badge)
      end)
      |> Enum.map(fn {player_id, _player} -> player_id end)

    update_players(game, late_achievers, fn player -> put_badge(player, badge_id, :small) end)
  end

  defp large_badge_awarded?(game, badge_name) do
    Enum.any?(game.players, fn {_player_id, player} ->
      Map.get(player.badges, badge_name) == :large
    end)
  end

  defp put_badge(player, badge_id, award) do
    put_in(player.badges[badge_id], award)
  end

  defp score_players(game) do
    rulesheet = Ruleset.sheet!(game.sheet)

    Map.new(game.players, fn {player_id, _player} ->
      {player_id, score_player(game, rulesheet, player_id)}
    end)
  end

  defp score_player(game, rulesheet, player_id) do
    player = Map.fetch!(game.players, player_id)
    badge_total = badge_total(rulesheet, player)
    round_total = player.rounds |> Enum.map(& &1.total) |> Enum.sum()
    total = round_total + badge_total
    rank = solo_rank(game, rulesheet, total)

    %{total: total, rank: rank}
  end

  defp badge_total(rulesheet, player) do
    player.badges
    |> Enum.map(fn {badge_id, award} ->
      rulesheet.badges |> Map.fetch!(badge_id) |> points_for_badge(award)
    end)
    |> Enum.sum()
  end

  defp points_for_badge(badge, award), do: Map.fetch!(badge.awards, award)

  defp solo_rank(%__MODULE__{mode: :solo}, rulesheet, total) do
    {:ok, %{rank: rank}} = Ruleset.solo_rating(rulesheet, total)
    rank
  end

  defp solo_rank(%__MODULE__{}, _rulesheet, _total), do: nil

  defp update_players(game, player_ids, fun) do
    Enum.reduce(player_ids, game, fn player_id, game ->
      update_in(game.players[player_id], fun)
    end)
  end

  defp set_player_statuses(game, status) when status in @player_statuses do
    players =
      Map.new(game.players, fn {player_id, player} -> {player_id, %{player | status: status}} end)

    %{game | players: players}
  end
end
