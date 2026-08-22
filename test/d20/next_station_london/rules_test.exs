defmodule D20.NextStationLondon.RulesTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Rules
  alias D20.NextStationLondon.Ruleset

  describe "setup predicates" do
    test "enforces capacity, participation, readiness, and system-only preparation" do
      game = game_with_players(4)

      assert Rules.ready_to_start?(game)
      assert Rules.participant?(game, "p1")
      refute Rules.participant?(game, "spectator")

      assert {:error, :player_limit_reached} = Rules.validate(game, command("join", "p5"))

      assert {:error, :not_joined} = Rules.validate(game, command("start", "spectator"))

      solo = game_with_players(1)

      assert :ok = Rules.validate(solo, command("start", "p1"))

      preparing = %{game | phase: :reveal, round: 1}

      assert {:error, :system_only} =
               Rules.validate(preparing, command("reveal", "p1", valid_round_setup(preparing)))
    end

    test "validates exact first-round assignments and later-round omissions" do
      game = %{game_with_players(3) | phase: :reveal, round: 1}
      attrs = valid_round_setup(game)

      assert :ok = Rules.validate_round_setup(game, attrs)

      invalid_setups = [
        %{attrs | deck: tl(attrs.deck)},
        %{attrs | pencil_offsets: %{"p1" => 0, "p2" => 0, "p3" => 2}},
        %{attrs | pencil_offsets: %{"p1" => 0, "p2" => 1}},
        %{attrs | pencil_offsets: %{"p1" => 0, "p2" => 1, "p3" => 4}},
        %{attrs | pencil_offsets: %{"p1" => 1, "p2" => 2, "p3" => 3}},
        %{attrs | pencil_cycle: [:green, :green, :pink, :purple]}
      ]

      assert Enum.all?(invalid_setups, fn invalid ->
               Rules.validate_round_setup(game, invalid) == {:error, :invalid_system_setup}
             end)

      solo = %{game_with_players(1) | phase: :reveal, round: 1}
      solo_attrs = valid_round_setup(solo)
      assert :ok = Rules.validate_round_setup(solo, solo_attrs)

      assert {:error, :invalid_system_setup} =
               Rules.validate_round_setup(solo, %{solo_attrs | pencil_offsets: %{"p1" => 1}})

      enabled = %{game | objectives: [], powers: %{}}
      enabled_attrs = valid_round_setup(enabled)
      assert :ok = Rules.validate_round_setup(enabled, enabled_attrs)

      assert {:error, :invalid_system_setup} =
               Rules.validate_round_setup(enabled, %{
                 enabled_attrs
                 | objectives: [:all_districts, :all_districts]
               })

      assert {:error, :invalid_system_setup} =
               Rules.validate_round_setup(enabled, %{
                 enabled_attrs
                 | powers: %{
                     green: :joker,
                     blue: :joker,
                     pink: :double_section,
                     purple: :double_station
                   }
               })

      later = %{
        enabled
        | round: 2,
          objectives: enabled_attrs.objectives,
          powers: enabled_attrs.powers
      }

      assert :ok =
               Rules.validate_round_setup(later, %{
                 deck: Ruleset.card_ids(),
                 pencil_cycle: nil,
                 pencil_offsets: nil,
                 objectives: nil,
                 powers: nil
               })
    end
  end

  describe "instruction derivation" do
    test "pairs switches, suppresses early branching, and detects the fifth Underground card" do
      first_switch = %Game{draws: [%{cards: ["street_railroad_switch", "underground_circle"]}]}

      assert %{turn: 1, destination: :circle, switch: false, final: false} =
               Rules.current_instruction(first_switch)

      late_switch = %Game{
        draws: [
          %{cards: ["underground_circle"]},
          %{cards: ["street_square"]},
          %{cards: ["street_railroad_switch", "underground_joker"]}
        ]
      }

      assert %{turn: 3, destination: :joker, switch: true, final: false} =
               Rules.current_instruction(late_switch)

      final = %Game{
        draws:
          Enum.map(
            ~w(underground_circle underground_square underground_triangle underground_pentagon underground_joker),
            &%{cards: [&1]}
          )
      }

      assert Rules.underground_count(final.draws) == 5
      assert %{final: true} = Rules.current_instruction(final)
    end
  end

  describe "section legality" do
    test "applies an ordinary section without mutating the input candidate" do
      game = build_game("street_square")
      player_before = game.players["p1"]

      assert {:ok, player} =
               Rules.resolve_action(game, draw_command("p1", [%{from: "r2c3", to: "r1c3"}]))

      assert player.lines.green.edges == ["r1c3-r2c3"]
      assert player_before.lines.green.edges == []
      assert game.players["p1"] == player_before
    end

    test "uses stable precedence for origin, edge, revisit, reuse, crossing, and destination errors" do
      game = build_game("street_square")

      assert {:error, :invalid_origin} =
               Rules.resolve_action(game, draw_command("p1", [%{from: "r0c2", to: "r1c3"}]))

      pentagon_game = build_game("street_pentagon")

      assert {:error, :invalid_section} =
               Rules.resolve_action(
                 pentagon_game,
                 draw_command("p1", [%{from: "r2c3", to: "r1c6"}])
               )

      revisited = put_in(game.players["p1"].lines.green.edges, ["r1c3-r2c3"])

      assert {:error, :station_revisited} =
               Rules.resolve_action(revisited, draw_command("p1", [%{from: "r1c3", to: "r2c3"}]))

      reused = put_in(build_game("street_circle").players["p1"].lines.purple.edges, ["r0c5-r2c3"])

      assert {:error, :section_reused} =
               Rules.resolve_action(reused, draw_command("p1", [%{from: "r2c3", to: "r0c5"}]))

      crossing =
        put_in(build_game("street_circle").players["p1"].lines.purple.edges, ["r0c4-r3c4"])

      assert {:error, :section_crossing} =
               Rules.resolve_action(crossing, draw_command("p1", [%{from: "r2c3", to: "r0c5"}]))

      assert {:error, :invalid_destination} =
               Rules.resolve_action(
                 build_game("street_circle"),
                 draw_command("p1", [%{from: "r2c3", to: "r1c3"}])
               )
    end

    test "allows shared station endpoints and central wild destinations" do
      shared = put_in(build_game("street_square").players["p1"].lines.purple.edges, ["r1c3-r3c5"])

      assert {:ok, _player} =
               Rules.resolve_action(shared, draw_command("p1", [%{from: "r2c3", to: "r1c3"}]))

      central =
        build_game("street_circle")
        |> put_in([Access.key!(:players), "p1", :lines, :green, :edges], ["r1c3-r2c3"])

      assert {:ok, player} =
               Rules.resolve_action(central, draw_command("p1", [%{from: "r1c3", to: "r3c5"}]))

      assert "r1c3-r3c5" in player.lines.green.edges
    end
  end

  describe "Pencil Powers" do
    test "applies Double Section atomically and preserves the candidate on failure" do
      game = build_game("street_square", :double_section)

      sections = [%{from: "r2c3", to: "r1c3"}, %{from: "r1c3", to: "r0c2"}]

      assert {:ok, player} =
               Rules.resolve_action(game, draw_command("p1", sections, power: :double_section))

      assert player.lines.green.edges == ["r1c3-r2c3", "r0c2-r1c3"]
      assert player.lines.green.power_used

      invalid_sections = [%{from: "r2c3", to: "r1c3"}, %{from: "r1c3", to: "r0c4"}]

      assert {:error, :invalid_destination} =
               Rules.resolve_action(
                 game,
                 draw_command("p1", invalid_sections, power: :double_section)
               )

      assert game.players["p1"].lines.green == Game.initial_line()
    end

    test "applies Joker, Railroad Switch, and Double Station without weakening other rules" do
      joker_game = build_game("street_circle", :joker)

      assert {:ok, joker_player} =
               Rules.resolve_action(
                 joker_game,
                 draw_command("p1", [%{from: "r2c3", to: "r1c3"}], power: :joker)
               )

      assert joker_player.lines.green.power_used

      switch_game =
        build_game("street_circle", :railroad_switch)
        |> put_in([Access.key!(:players), "p1", :lines, :green, :edges], [
          "r1c3-r2c3",
          "r0c2-r1c3"
        ])

      assert {:ok, switch_player} =
               Rules.resolve_action(
                 switch_game,
                 draw_command("p1", [%{from: "r1c3", to: "r3c5"}], power: :railroad_switch)
               )

      assert switch_player.lines.green.power_used

      station_game = build_game("street_circle", :double_station)

      assert {:ok, station_player} =
               Rules.resolve_action(
                 station_game,
                 command("pass", "p1", %{power: :double_station, power_target: "r2c3"})
               )

      assert station_player.lines.green.doubled_station == "r2c3"
      assert station_player.lines.green.power_used

      assert {:error, :invalid_power_target} =
               Rules.resolve_action(
                 station_game,
                 command("pass", "p1", %{power: :double_station, power_target: "r0c0"})
               )
    end
  end

  describe "scoring and outcomes" do
    test "scores districts, Thames crossings, and Double Station exactly" do
      line = %{Game.initial_line() | edges: ["r2c3-r6c3"]}

      assert Rules.score_line(line, :green) == %{
               districts: 2,
               largest_district: 1,
               thames_crossings: 1,
               total: 4
             }

      doubled = %{line | doubled_station: "r6c3"}

      assert Rules.score_line(doubled, :green) == %{
               districts: 2,
               largest_district: 2,
               thames_crossings: 1,
               total: 6
             }
    end

    test "caps tourist marks, scores interchanges, objectives, and solo penalties" do
      tourist_edges =
        Enum.map(Ruleset.tourist_station_ids(), fn station_id ->
          Ruleset.edges()
          |> Map.values()
          |> Enum.find(&(&1.from == station_id or &1.to == station_id))
          |> Map.fetch!(:id)
        end)

      shared_edge = "r3c4-r3c5"

      player =
        Enum.reduce(Ruleset.colors(), Game.initial_player(), fn color, player ->
          put_in(player.lines[color].edges, Enum.uniq([shared_edge | tourist_edges]))
        end)

      game = %Game{
        players: %{"p1" => player},
        objectives: [:all_tourist_sites, :central_district],
        powers: %{}
      }

      score = Rules.score_player(game, player)

      assert score.tourist_marks == 10
      assert score.tourist_score == 25
      assert score.interchange_counts[4] >= 2
      assert :all_tourist_sites in score.achieved_objectives
      assert score.objective_score >= 10

      assert %{mode: :solo, rating_score: rating_score} = Rules.outcome(game)
      assert rating_score == score.total - 20
    end

    test "uses highest single line as the multiplayer tie breaker" do
      base = Game.initial_player()
      strong_line = put_in(base.lines.green.edges, ["r2c3-r6c3"])

      balanced =
        base
        |> put_in([Access.key!(:lines), :green, :edges], ["r2c3-r3c2"])
        |> put_in([Access.key!(:lines), :blue, :edges], ["r7c5-r7c8"])
        |> put_in([Access.key!(:lines), :pink, :edges], ["r0c7-r3c7"])

      game = %Game{players: %{"p1" => strong_line, "p2" => balanced}}
      scores = Rules.scores(game)

      assert scores["p1"].total == scores["p2"].total
      assert scores["p1"].lines.green.total == 4
      assert Enum.max(Enum.map(scores["p2"].lines, fn {_color, line} -> line.total end)) == 2

      assert %{mode: :multiplayer, winners: ["p1"], shared: false} = Rules.outcome(game)
    end
  end

  defp game_with_players(count) do
    players = Map.new(1..count, fn index -> {"p#{index}", Game.initial_player()} end)

    %Game{phase: :setup, players: players}
  end

  defp build_game(card_id, power \\ nil) do
    player = %{Game.initial_player() | status: :pending, pencil_offset: 0}

    powers =
      if power,
        do: %{green: power, blue: :double_section, pink: :joker, purple: :double_station},
        else: nil

    %Game{
      phase: :turn,
      round: 1,
      players: %{"p1" => player},
      pencil_cycle: [:green, :blue, :pink, :purple],
      powers: powers,
      draws: [%{cards: [card_id]}]
    }
  end

  defp valid_round_setup(game) do
    player_ids = Map.keys(game.players)

    %{
      deck: Ruleset.card_ids(),
      pencil_cycle: [:green, :blue, :pink, :purple],
      pencil_offsets: player_ids |> Enum.with_index() |> Map.new(),
      objectives: if(game.objectives == [], do: [:all_districts, :central_district], else: nil),
      powers:
        if(game.powers == %{},
          do: %{
            green: :double_section,
            blue: :joker,
            pink: :railroad_switch,
            purple: :double_station
          },
          else: nil
        )
    }
  end

  defp draw_command(player_id, sections, opts \\ []) do
    command("draw", player_id, %{
      sections: sections,
      power: Keyword.get(opts, :power),
      chosen_symbol: Keyword.get(opts, :chosen_symbol),
      power_target: Keyword.get(opts, :power_target)
    })
  end

  defp command(event, actor_id, attrs \\ %{}) do
    %Command{event: event, actor_id: actor_id, attrs: attrs}
  end
end
