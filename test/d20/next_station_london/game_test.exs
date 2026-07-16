defmodule D20.NextStationLondon.GameTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Rules
  alias D20.NextStationLondon.Ruleset
  alias D20.NextStationLondon.Server

  describe "D20.Game behaviour" do
    test "initializes top-level optional modules and encodes the aggregate without roster order" do
      assert {:ok, %Game{phase: :setup, objectives: nil, powers: nil} = base} =
               D20.Game.init(Game)

      assert {:ok, %Game{objectives: [], powers: %{}} = enabled} =
               D20.Game.init(Game, %{"objectives" => true, "powers" => true})

      assert {:error, %Ecto.Changeset{valid?: false}} =
               D20.Game.init(Game, %{"objectives" => "yes"})

      decoded = enabled |> Jason.encode!() |> Jason.decode!()

      assert decoded["objectives"] == []
      assert decoded["powers"] == %{}
      refute Map.has_key?(decoded, "variants")
      refute Map.has_key?(decoded, "participants")
      refute Map.has_key?(decoded, "order")
      assert base.players == %{}
      assert D20.Game.server(Game) == Server
    end

    test "reports the explicit terminal state" do
      refute Game.finished?(%Game{phase: :build})
      assert Game.finished?(%Game{phase: :finished})
    end
  end

  describe "setup roster" do
    test "uses players as the only unordered roster and recomputes readiness" do
      {:ok, game} = D20.Game.init(Game)

      assert {:ok, %Game{phase: :ready} = game} = dispatch(game, "join", "p1")
      assert {:ok, ^game} = dispatch(game, "join", "p1")

      game =
        Enum.reduce(2..4, game, fn index, game ->
          {:ok, game} = dispatch(game, "join", "p#{index}")
          game
        end)

      assert MapSet.new(Map.keys(game.players)) == MapSet.new(~w(p1 p2 p3 p4))
      assert {:error, :player_limit_reached} = dispatch(game, "join", "p5")
      assert map_size(game.players) == 4

      assert {:ok, %Game{phase: :ready} = game} = dispatch(game, "leave", "p4")
      assert {:ok, %Game{phase: :ready} = game} = dispatch(game, "leave", "p3")
      assert {:ok, %Game{phase: :ready} = game} = dispatch(game, "leave", "p2")
      assert {:ok, %Game{phase: :setup, players: %{}}} = dispatch(game, "leave", "p1")
    end

    test "requires the starting actor to be joined and defers pencil assignment" do
      game = joined_game(1)

      assert {:error, :not_joined} = dispatch(game, "start", "spectator")

      assert {:ok, %Game{phase: :preparing_round, round: 1, pencil_cycle: []} = started} =
               dispatch(game, "start", "p1")

      assert started.players["p1"].pencil_offset == nil
    end

    test "starts and prepares games with one through four players" do
      Enum.each(1..4, fn count ->
        game = started_game(count)
        attrs = prepare_attrs(game)

        assert {:ok, %Game{phase: :build, round: 1} = prepared} =
                 dispatch(game, "prepare_round", nil, attrs)

        assert map_size(prepared.players) == count
        assert Enum.all?(prepared.players, fn {_id, player} -> player.status == :pending end)
        assert length(prepared.draws) == 1
        assert length(prepared.remaining_deck) == 10

        offsets = prepared.players |> Map.values() |> Enum.map(& &1.pencil_offset)
        assert MapSet.new(offsets) == MapSet.new(0..(count - 1))
        assert MapSet.new(prepared.pencil_cycle) == MapSet.new(Ruleset.colors())

        current_colors =
          Enum.map(Map.keys(prepared.players), fn player_id ->
            assert {:ok, color} = Rules.current_color(prepared, player_id)
            color
          end)

        assert length(current_colors) == MapSet.size(MapSet.new(current_colors))
      end)
    end
  end

  describe "round preparation" do
    test "commits first-round assignments once and keeps future cards private in state history" do
      {:ok, game} = D20.Game.init(Game, %{"objectives" => true, "powers" => true})
      {:ok, game} = dispatch(game, "join", "p1")

      {:ok, game} = dispatch(game, "start", "p1")

      attrs = prepare_attrs(game)

      assert {:ok, %Game{phase: :build} = game} = dispatch(game, "prepare_round", nil, attrs)

      assert game.objectives == [:all_districts, :central_district]

      assert game.powers == %{
               green: :double_section,
               blue: :joker,
               pink: :railroad_switch,
               purple: :double_station
             }

      assert [%{cards: ["underground_square"]}] = game.draws
      assert {:error, :invalid_phase} = dispatch(game, "prepare_round", nil, attrs)

      assert {:error, :invalid_phase} = dispatch(game, "prepare_round", "p1", attrs)
    end

    test "rejects client preparation before committing any random state" do
      game = started_game(2)

      assert {:error, :system_only} = dispatch(game, "prepare_round", "p1", prepare_attrs(game))

      assert game.phase == :preparing_round
      assert game.draws == []
      assert game.remaining_deck == []
    end
  end

  describe "simultaneous instructions" do
    test "waits for every frozen player and reveals exactly one next instruction" do
      game = 2 |> started_game() |> prepare_game()
      first_draw = game.draws

      assert {:ok, %Game{phase: :build} = game} = dispatch(game, "pass", "p1")
      assert game.players["p1"].status == :submitted
      assert game.players["p2"].status == :pending
      assert game.draws == first_draw

      assert {:error, :already_submitted} = dispatch(game, "pass", "p1")

      assert {:ok, %Game{phase: :build} = game} = dispatch(game, "pass", "p2")
      assert length(game.draws) == 2
      assert Enum.all?(game.players, fn {_id, player} -> player.status == :pending end)
    end

    test "freezes players across reconnects and late spectators" do
      game = 2 |> started_game() |> prepare_game()

      assert {:ok, ^game} = dispatch(game, "leave", "p1")
      assert {:ok, ^game} = dispatch(game, "join", "p1")
      assert {:ok, ^game} = dispatch(game, "join", "spectator")
      assert {:error, :not_joined} = dispatch(game, "pass", "spectator")
      assert MapSet.new(Map.keys(game.players)) == MapSet.new(~w(p1 p2))
    end

    test "commits valid network changes and preserves old state for rejected commands" do
      game = 1 |> started_game() |> prepare_game()

      assert {:error, :invalid_destination} =
               dispatch(game, "draw_sections", "p1", %{
                 "sections" => [%{"from" => "r2c3", "to" => "r0c5"}]
               })

      assert game.players["p1"].lines.green.edges == []
      assert game.players["p1"].status == :pending
      assert length(game.draws) == 1

      assert {:ok, game} =
               dispatch(game, "draw_sections", "p1", %{
                 "sections" => [%{"from" => "r2c3", "to" => "r1c3"}]
               })

      assert game.players["p1"].lines.green.edges == ["r1c3-r2c3"]
      assert length(game.draws) == 2
    end

    test "ends on the fifth Underground card and finishes only after round four" do
      round_one = 1 |> started_game() |> prepare_game()
      after_round_one = submit_passes_until_round_ends(round_one)

      assert after_round_one.phase == :preparing_round
      assert after_round_one.round == 2
      assert after_round_one.draws == []
      assert after_round_one.remaining_deck == []
      assert after_round_one.players["p1"].status == :ready

      round_four =
        %{after_round_one | round: 4} |> prepare_game() |> submit_passes_until_round_ends()

      assert round_four.phase == :finished
      assert round_four.round == 4
      assert round_four.remaining_deck == []
      assert Game.finished?(round_four)
      assert %{mode: :solo, player_id: "p1"} = Rules.outcome(round_four)
      assert {:error, :finished} = dispatch(round_four, "pass", "p1")
    end
  end

  defp joined_game(count) do
    {:ok, game} = D20.Game.init(Game)

    Enum.reduce(1..count, game, fn index, game ->
      {:ok, game} = dispatch(game, "join", "p#{index}")
      game
    end)
  end

  defp started_game(count) do
    joined_game(count)
    |> then(fn game ->
      {:ok, game} = dispatch(game, "start", "p1")
      game
    end)
  end

  defp prepare_game(%Game{phase: :preparing_round} = game) do
    {:ok, game} = dispatch(game, "prepare_round", nil, prepare_attrs(game))
    game
  end

  defp submit_passes_until_round_ends(game) do
    Enum.reduce_while(1..11, game, fn _index, game ->
      if game.phase == :build do
        {:ok, game} = dispatch(game, "pass", "p1")
        {:cont, game}
      else
        {:halt, game}
      end
    end)
  end

  defp prepare_attrs(game) do
    player_ids = Map.keys(game.players)

    attrs = %{"deck" => fixed_deck()}

    attrs =
      if game.round == 1 do
        attrs
        |> Map.put("pencil_cycle", color_names())
        |> Map.put("pencil_offsets", player_ids |> Enum.with_index() |> Map.new())
      else
        attrs
      end

    attrs =
      if game.objectives == [] do
        Map.put(attrs, "objectives", ~w(all_districts central_district))
      else
        attrs
      end

    if game.powers == %{} do
      Map.put(attrs, "powers", %{
        "green" => "double_section",
        "blue" => "joker",
        "pink" => "railroad_switch",
        "purple" => "double_station"
      })
    else
      attrs
    end
  end

  defp fixed_deck do
    ~w(
      underground_square
      underground_circle
      underground_triangle
      underground_pentagon
      underground_joker
      street_circle
      street_square
      street_triangle
      street_pentagon
      street_joker
      street_railroad_switch
    )
  end

  defp color_names, do: Enum.map(Ruleset.colors(), &Atom.to_string/1)

  defp dispatch(game, event, actor_id, attrs \\ %{}) do
    Game.dispatch(game, %Command{event: event, actor_id: actor_id, attrs: attrs})
  end
end
