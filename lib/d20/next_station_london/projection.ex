defmodule D20.NextStationLondon.Projection do
  @moduledoc """
  Renders the complete caller-specific Next Station: London read model.
  """

  alias D20.Accounts.Scope
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Permission
  alias D20.NextStationLondon.Rules
  alias D20.NextStationLondon.Ruleset
  alias D20.Sessions.Session

  @type section :: %{required(:from) => String.t(), required(:to) => String.t()}
  @type options :: %{
          required(:sections) => [section()],
          required(:wildcard_sections) => %{optional(atom()) => [section()]},
          required(:joker_sections) => [section()],
          required(:switch_sections) => [section()],
          required(:double_sections) => [map()],
          required(:double_station_targets) => [String.t()],
          required(:double_station_sections) => [map()],
          required(:power) => Ruleset.power_id() | nil
        }

  @spec render(Scope.t(), Session.t()) :: map()
  def render(%Scope{} = scope, %Session{game: %Game{} = game} = session) do
    actor_id = scope.actor.id
    permissions = Permission.permissions(scope, session)

    %{
      id: session.id,
      phase: session.phase,
      owner_id: session.owner_id,
      members: session.members,
      self: actor_id,
      objectives: game.objectives,
      powers: game.powers,
      pencil_colors: Ruleset.colors(),
      permissions: permissions,
      options: render_options(game, actor_id),
      game: %{
        phase: game.phase,
        round: game.round,
        pencil_cycle: game.pencil_cycle,
        current_instruction: Rules.current_instruction(game),
        reveals: render_reveals(game),
        players: render_players(game),
        scores: Rules.scores(game),
        outcome: render_outcome(game)
      }
    }
  end

  defp render_players(game) do
    Map.new(game.players, fn {player_id, player} ->
      current_color =
        case Rules.current_color(game, player_id) do
          {:ok, color} -> color
          {:error, _reason} -> nil
        end

      {player_id,
       %{
         status: player.status,
         pencil_offset: player.pencil_offset,
         current_color: current_color,
         lines: player.lines
       }}
    end)
  end

  defp render_reveals(game) do
    game.draws
    |> Enum.with_index(1)
    |> Enum.map(fn {_draw, turn} ->
      game |> Map.put(:draws, Enum.take(game.draws, turn)) |> Rules.current_instruction()
    end)
  end

  defp render_outcome(%Game{phase: :finished} = game), do: Rules.outcome(game)
  defp render_outcome(%Game{}), do: nil

  defp render_options(game, actor_id) do
    if Rules.submit_allowed?(game, actor_id) do
      instruction = Rules.current_instruction(game)
      power = available_power(game, actor_id)

      %{
        sections: game |> Rules.legal_sections(actor_id) |> sort_sections(),
        wildcard_sections: wildcard_sections(game, actor_id, instruction),
        joker_sections: power_sections(game, actor_id, power, :joker),
        switch_sections: power_sections(game, actor_id, power, :railroad_switch),
        double_sections: double_sections(game, actor_id, power),
        double_station_targets: double_station_targets(game, actor_id, power),
        double_station_sections: double_station_sections(game, actor_id, power),
        power: power
      }
    else
      empty_options()
    end
  end

  defp wildcard_sections(game, actor_id, %{destination: :joker}) do
    Map.new(Ruleset.ordinary_symbols(), fn symbol ->
      sections = game |> Rules.legal_sections(actor_id, chosen_symbol: symbol) |> sort_sections()

      {symbol, sections}
    end)
  end

  defp wildcard_sections(_game, _actor_id, _instruction), do: %{}

  defp power_sections(game, actor_id, power, power) when power in [:joker, :railroad_switch] do
    opts = if power == :joker, do: [destination: :joker], else: [switch: true]
    game |> Rules.legal_sections(actor_id, opts) |> sort_sections()
  end

  defp power_sections(_game, _actor_id, _available_power, _requested_power), do: []

  defp double_sections(game, actor_id, :double_section) do
    game
    |> Rules.legal_double_sections(actor_id)
    |> Enum.sort_by(fn %{sections: sections, chosen_symbol: symbol} ->
      {symbol || :none, Enum.map(sections, &{&1.from, &1.to})}
    end)
  end

  defp double_sections(_game, _actor_id, _power), do: []

  defp double_station_targets(game, actor_id, :double_station) do
    Rules.double_station_targets(game, actor_id)
  end

  defp double_station_targets(_game, _actor_id, _power), do: []

  defp double_station_sections(game, actor_id, :double_station) do
    Rules.double_station_section_options(game, actor_id)
  end

  defp double_station_sections(_game, _actor_id, _power), do: []

  defp available_power(game, actor_id) do
    case Rules.available_power(game, actor_id) do
      {:ok, power} -> power
      :error -> nil
    end
  end

  defp sort_sections(sections), do: Enum.sort_by(sections, &{&1.from, &1.to})

  defp empty_options do
    %{
      sections: [],
      wildcard_sections: %{},
      joker_sections: [],
      switch_sections: [],
      double_sections: [],
      double_station_targets: [],
      double_station_sections: [],
      power: nil
    }
  end
end
