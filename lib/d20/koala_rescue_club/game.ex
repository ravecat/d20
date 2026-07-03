defmodule D20.KoalaRescueClub.Game do
  @moduledoc """
  Koala Rescue Club game aggregate and reducer.
  """

  @behaviour D20.Game

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias D20.Dice
  alias D20.KoalaRescueClub.Command
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset

  @phases [:setup, :ready, :roll, :submit, :finished]
  @player_statuses [:ready, :pending, :submitted]
  @derive Jason.Encoder
  @primary_key false

  embedded_schema do
    field :phase, Ecto.Enum,
      values: @phases,
      default: :setup

    field :sheet, Ecto.Enum, values: [:dharug, :yugambeh], default: :dharug
    field :round, :integer, default: 1
    field :turn, :integer, default: 0
    field :order, {:array, :string}, default: []
    field :players, :map, default: %{}
    field :roll, :map
    field :scores, :map, default: %{}
  end

  @type player_id :: D20.Actors.Actor.id()
  @type skybridge :: %{required(:from) => Ruleset.area(), required(:to) => Ruleset.area()}
  @type bonus :: %{
          required(:area) => Ruleset.area(),
          required(:axis) => :row | :column,
          required(:index) => non_neg_integer()
        }
  @type sheet :: %{
          required(:trees) => [Ruleset.cell()],
          required(:koalas) => [Ruleset.cell()],
          required(:volunteers) => [:available | :locked | :used],
          required(:hospitals) => %{optional(String.t()) => non_neg_integer()},
          required(:skybridges) => [skybridge()],
          required(:bonuses) => [bonus()]
        }
  @type score :: %{required(:total) => integer(), required(:rank) => Ruleset.rank() | nil}
  @type player :: %{
          required(:status) => :ready | :pending | :submitted,
          required(:sheet) => sheet(),
          required(:badges) => %{optional(Ruleset.badge()) => atom()},
          required(:rounds) => [
            %{
              required(:trees) => non_neg_integer(),
              required(:koalas) => non_neg_integer(),
              required(:hospitals) => integer(),
              required(:total) => integer()
            }
          ]
        }
  @type roll :: %{required(:value) => 1..6}
  @type t :: %__MODULE__{
          phase: :setup | :ready | :roll | :submit | :finished,
          sheet: Ruleset.id(),
          round: 1..2,
          turn: 0..30,
          order: [player_id()],
          players: %{optional(player_id()) => player()},
          roll: roll() | nil,
          scores: %{optional(player_id()) => score()}
        }
  @type reason :: :finished | :invalid_phase

  @impl D20.Game
  @spec init(D20.Game.attrs()) :: {:ok, t()}
  def init(attrs), do: {:ok, struct(__MODULE__, attrs)}

  @impl D20.Game
  @spec attrs(map()) :: Ecto.Changeset.t()
  def attrs(params) do
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
      when event in ["join", "leave"] and phase in [:roll, :submit],
      do: {:ok, game}

  def dispatch(%__MODULE__{phase: phase} = game, %D20.Command{event: "leave"})
      when phase in [:setup, :ready],
      do: {:ok, game}

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

  def dispatch(%__MODULE__{phase: :submit} = game, %D20.Command{event: event} = command)
      when event in ["plant_trees", "rehome_koalas", "circle_tree", "circle_koala"] do
    with {:ok, command} <- Command.validate(command),
         :ok <- Rules.validate(game, command) do
      {:ok, apply_command(game, command)}
    end
  end

  def dispatch(%__MODULE__{phase: :finished}, %D20.Command{}), do: {:error, :finished}
  def dispatch(%__MODULE__{}, %D20.Command{}), do: {:error, :invalid_phase}

  @impl D20.Game
  @spec finished?(t()) :: boolean()
  def finished?(%__MODULE__{phase: :finished}), do: true
  def finished?(%__MODULE__{}), do: false

  defp apply_command(game, %D20.Command{event: "join", actor_id: actor_id}) do
    game
    |> join_player(actor_id)
    |> maybe_mark_ready()
  end

  defp apply_command(%__MODULE__{phase: :ready} = game, %D20.Command{event: "start"}) do
    players =
      Map.new(game.players, fn {player_id, player} ->
        {player_id, %{player | status: :ready, rounds: [], badges: %{}}}
      end)

    %{game | phase: :roll, round: 1, turn: 1, players: players}
  end

  defp apply_command(%__MODULE__{phase: :roll} = game, %D20.Command{event: "roll"}) do
    %{d6: [value]} = Dice.roll!(d6: 1)

    set_player_statuses(%{game | phase: :submit, roll: %{value: value}}, :pending)
  end

  defp apply_command(
         %__MODULE__{phase: :submit} = game,
         %D20.Command{event: event, actor_id: actor_id} = command
       )
       when event in ["plant_trees", "rehome_koalas", "circle_tree", "circle_koala"] do
    {:ok, player} = Rules.resolve_turn(game, command)

    game
    |> put_in([Access.key!(:players), actor_id], player)
    |> maybe_resolve_turn()
  end

  defp join_player(game, player_id) do
    if Map.has_key?(game.players, player_id) do
      game
    else
      {:ok, rulesheet} = Ruleset.sheet(game.sheet)

      %{
        game
        | order: game.order ++ [player_id],
          players: Map.put(game.players, player_id, new_player(empty_sheet(rulesheet)))
      }
    end
  end

  defp maybe_mark_ready(%__MODULE__{phase: :setup} = game) do
    if Rules.ready_to_start?(game), do: %{game | phase: :ready}, else: game
  end

  defp maybe_mark_ready(game), do: game

  defp maybe_resolve_turn(game) do
    if Rules.turn_complete?(game) do
      game
      |> award_badges()
      |> maybe_score_round()
      |> advance_or_finish()
    else
      game
    end
  end

  defp maybe_score_round(game) do
    if Ruleset.scoring_turn?(game.turn), do: score_round(game), else: game
  end

  defp advance_or_finish(game) do
    if Ruleset.final_turn?(game.turn) do
      finish(game)
    else
      {:ok, next_round} = Ruleset.round_for_turn(game.turn + 1)

      set_player_statuses(
        %{game | phase: :roll, round: next_round, turn: game.turn + 1, roll: nil},
        :ready
      )
    end
  end

  defp finish(game) do
    scores = score_players(game)
    %{game | phase: :finished, scores: scores}
  end

  defp score_round(game) do
    {:ok, rulesheet} = Ruleset.sheet(game.sheet)

    players =
      Map.new(game.players, fn {player_id, player} ->
        round = score_round_for_player(game.sheet, rulesheet, player)

        {player_id, %{player | rounds: player.rounds ++ [round]}}
      end)

    %{game | players: players}
  end

  defp score_round_for_player(sheet_id, rulesheet, player) do
    trees = score_complete_areas(rulesheet, player.sheet, &Ruleset.trees_complete?/3)
    koalas = score_complete_areas(rulesheet, player.sheet, &Ruleset.koalas_complete?/3)

    hospitals =
      rulesheet.hospitals |> Enum.map(&score_hospital(sheet_id, player.sheet, &1)) |> Enum.sum()

    %{trees: trees, koalas: koalas, hospitals: hospitals, total: trees + koalas + hospitals}
  end

  defp score_complete_areas(rulesheet, player_sheet, complete?) do
    rulesheet.areas
    |> Map.keys()
    |> Enum.count(&complete?.(rulesheet, player_sheet, &1))
  end

  defp score_hospital(sheet_id, player_sheet, {hospital_id, hospital}) do
    filled = Map.get(player_sheet.hospitals, hospital_id, 0)

    hospital = hospital |> Map.take([:size, :score, :penalty]) |> Map.put(:filled, filled)

    {:ok, score} = Ruleset.score_hospital(sheet_id, hospital)
    score
  end

  defp award_badges(game) do
    {:ok, rulesheet} = Ruleset.sheet(game.sheet)

    if length(game.order) == 1 do
      award_solo_badges(game, rulesheet)
    else
      award_multiplayer_badges(game, rulesheet)
    end
  end

  defp award_solo_badges(game, map) do
    [player_id] = game.order

    player =
      Enum.reduce(map.badges, game.players[player_id], fn {_badge_name, badge}, player ->
        if Map.has_key?(player.badges, badge.id) or
             not Rules.badge_satisfied?(map, player.sheet, badge) do
          player
        else
          award = if game.round == 1, do: :large, else: :small
          put_badge(player, badge, award)
        end
      end)

    put_in(game.players[player_id], player)
  end

  defp award_multiplayer_badges(game, map) do
    Enum.reduce(map.badges, game, fn {_badge_name, badge}, game ->
      if large_badge_awarded?(game, badge.id) do
        award_late_badges(game, map, badge)
      else
        first_achievers =
          Enum.filter(game.order, fn player_id ->
            player = game.players[player_id]
            Rules.badge_satisfied?(map, player.sheet, badge)
          end)

        if first_achievers == [] do
          game
        else
          update_players(game, first_achievers, fn player -> put_badge(player, badge, :large) end)
        end
      end
    end)
  end

  defp award_late_badges(game, map, badge) do
    late_achievers =
      Enum.filter(game.order, fn player_id ->
        player = game.players[player_id]

        not Map.has_key?(player.badges, badge.id) and
          Rules.badge_satisfied?(map, player.sheet, badge)
      end)

    update_players(game, late_achievers, fn player -> put_badge(player, badge, :small) end)
  end

  defp large_badge_awarded?(game, badge_name) do
    Enum.any?(game.players, fn {_player_id, player} ->
      Map.get(player.badges, badge_name) == :large
    end)
  end

  defp put_badge(player, badge, award) do
    put_in(player.badges[badge.id], award)
  end

  defp score_players(game) do
    {:ok, rulesheet} = Ruleset.sheet(game.sheet)

    Map.new(game.order, &{&1, score_player(game, rulesheet, &1)})
  end

  defp score_player(game, rulesheet, player_id) do
    player = Map.fetch!(game.players, player_id)
    badge_total = badge_total(rulesheet, player)
    round_total = player.rounds |> Enum.map(& &1.total) |> Enum.sum()
    total = round_total + badge_total
    rank = solo_rank(game, total)

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

  defp solo_rank(%__MODULE__{order: [_one], sheet: sheet}, total) do
    {:ok, %{rank: rank}} = Ruleset.solo_rating(sheet, total)
    rank
  end

  defp solo_rank(%__MODULE__{}, _total), do: nil

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

  defp new_player(sheet) do
    %{status: :ready, sheet: sheet, rounds: [], badges: %{}}
  end

  defp volunteer_slots(claimed) do
    List.duplicate(:available, claimed) ++
      List.duplicate(:locked, Ruleset.volunteer_limit() - claimed)
  end

  defp empty_sheet do
    %{trees: [], koalas: [], volunteers: [], hospitals: %{}, skybridges: [], bonuses: []}
  end

  defp empty_sheet(rulesheet) do
    empty_sheet()
    |> Map.put(:volunteers, volunteer_slots(rulesheet.volunteers))
    |> Map.put(:hospitals, Map.new(rulesheet.hospitals, fn {id, _hospital} -> {id, 0} end))
  end
end
