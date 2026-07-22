defmodule D20.KoalaRescueClub.Bot do
  @moduledoc """
  Server-side opponent for Koala Rescue Club with configurable difficulty.

  The bot derives candidates from `D20.KoalaRescueClub.Rules` and returns a
  regular `D20.Command`. The session server remains responsible for dispatch,
  validation, state transitions, and publication.
  """

  alias D20.Command
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset
  alias D20.Sessions.Session

  @display_name "Ranger Bot"
  @difficulties [:easy, :normal, :hard]
  @simple_actions ["circle_koala", "circle_tree"]

  @type difficulty :: :easy | :normal | :hard
  @type chooser :: (nonempty_list(Command.t()) -> Command.t() | nil)

  @doc "Returns the session-scoped actor id used by the bot."
  @spec id(Session.id()) :: String.t()
  def id(session_id) when is_binary(session_id), do: "bot:#{session_id}"

  @doc "Returns the member projection stored through the ordinary join path."
  @spec member_attrs(difficulty()) :: map()
  def member_attrs(difficulty \\ :normal) when difficulty in @difficulties do
    %{
      display_name: @display_name,
      avatar: nil,
      bot: true,
      bot_difficulty: difficulty,
      online_at: System.system_time(:second)
    }
  end

  @doc "Reports whether the session was created with a bot opponent."
  @spec enabled?(Session.t()) :: boolean()
  def enabled?(%Session{game: %Game{opponent: opponent}}) when opponent != :none, do: true
  def enabled?(%Session{}), do: false

  @doc "Returns the configured bot difficulty."
  @spec difficulty(Session.t() | Game.t()) :: difficulty()
  def difficulty(%Session{game: %Game{} = game}), do: difficulty(game)
  def difficulty(%Game{opponent: :bot_easy}), do: :easy
  def difficulty(%Game{opponent: :bot_hard}), do: :hard
  def difficulty(%Game{}), do: :normal

  @doc "Reports whether the bot has already joined the game roster."
  @spec joined?(Session.t()) :: boolean()
  def joined?(%Session{id: session_id, game: %Game{players: players}}) do
    Map.has_key?(players, id(session_id))
  end

  @doc "Returns one legal bot command for the current authoritative state."
  @spec next_command(Session.t(), chooser()) :: {:ok, Command.t()} | :idle
  def next_command(session, chooser \\ &Enum.random/1)

  def next_command(
        %Session{phase: :in_progress, id: session_id, game: %Game{phase: :submit} = game},
        chooser
      )
      when is_function(chooser, 1) do
    player_id = id(session_id)

    with {:ok, %{status: :pending}} <- Game.fetch_player(game, player_id),
         [_ | _] = candidates <- candidates(game, player_id),
         [_ | _] = strategy_candidates <- strategy_candidates(game, candidates),
         %Command{} = command <- choose(strategy_candidates, chooser),
         true <- command in strategy_candidates do
      {:ok, command}
    else
      _reason -> :idle
    end
  end

  def next_command(%Session{}, _chooser), do: :idle

  @doc "Narrows legal commands according to the configured difficulty."
  @spec strategy_candidates(Game.t(), nonempty_list(Command.t())) :: nonempty_list(Command.t())
  def strategy_candidates(%Game{} = game, [_ | _] = candidates) do
    case difficulty(game) do
      :easy -> candidates
      :normal -> Enum.take(candidates, 8)
      :hard -> Enum.take(candidates, 2)
    end
  end

  @doc "Returns legal, deterministic single-action commands for a player."
  @spec candidates(Game.t(), Game.player_id()) :: [Command.t()]
  def candidates(%Game{} = game, player_id) do
    with {:ok, player} <- Game.fetch_player(game, player_id) do
      rulesheet = Ruleset.sheet!(game.sheet)

      game
      |> Rules.turn_options(player_id)
      |> Enum.flat_map(&option_candidates(&1, rulesheet, player.sheet, player_id))
      |> Enum.sort_by(&candidate_order(game, &1))
    else
      :error -> []
    end
  end

  defp option_candidates(
         {value, %{volunteer_cost: volunteer_cost, actions: actions}},
         rulesheet,
         sheet,
         player_id
       ) do
    Enum.flat_map(@simple_actions, fn action ->
      action_candidates(actions, rulesheet, sheet, player_id, action, value, volunteer_cost)
    end)
  end

  defp action_candidates(actions, rulesheet, sheet, player_id, action, value, volunteer_cost) do
    actions
    |> Map.get(action, %{available_cells: []})
    |> Map.fetch!(:available_cells)
    |> Enum.map(&command(rulesheet, sheet, player_id, action, value, volunteer_cost, &1))
  end

  defp command(rulesheet, sheet, player_id, action, value, volunteer_cost, cell) do
    attrs = %{
      die_value: value,
      volunteers_used: volunteer_cost,
      target_cell: cell,
      bonus_actions: bonus_actions(rulesheet, sheet, action, value, cell)
    }

    %Command{event: action, actor_id: player_id, attrs: attrs}
  end

  defp bonus_actions(rulesheet, sheet, action, value, cell) do
    previous_refs = rulesheet |> Rules.unlocked_bonuses(sheet) |> refs()

    with {:ok, updated_sheet} <-
           Rules.apply_primary_action(rulesheet, sheet, action, %{target_cell: cell}, value) do
      rulesheet
      |> Rules.unlocked_bonuses(updated_sheet)
      |> Enum.reject(&MapSet.member?(previous_refs, &1.ref))
      |> Enum.sort_by(&{&1.ref.area, &1.ref.axis, &1.ref.index})
      |> Enum.map(&bonus_action/1)
    else
      {:error, _reason} -> []
    end
  end

  defp refs(entries), do: MapSet.new(entries, & &1.ref)

  defp choose(candidates, chooser) do
    chooser.(candidates)
  rescue
    _exception -> nil
  catch
    _kind, _reason -> nil
  end

  defp bonus_action(%{ref: ref, bonus: %{kind: :skybridge, to: to}}) do
    %{bonus: ref, action: %{kind: "skybridge", to: to}}
  end

  defp bonus_action(%{ref: ref}), do: %{bonus: ref, action: %{kind: "skip"}}

  defp candidate_order(%Game{roll: %{value: rolled}}, %Command{
         event: event,
         attrs: %{die_value: value, volunteers_used: volunteers, target_cell: cell}
       }) do
    action_order = Enum.find_index(@simple_actions, &(&1 == event))
    {volunteers, value != rolled, action_order, value, cell.area, cell.row, cell.column}
  end
end
