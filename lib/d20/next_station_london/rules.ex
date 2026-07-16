defmodule D20.NextStationLondon.Rules do
  @moduledoc """
  State-dependent legality, candidate application, and scoring for Next Station: London.
  """

  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Ruleset

  @type reason ::
          :player_limit_reached
          | :not_joined
          | :not_ready
          | :system_only
          | :invalid_system_setup
          | :already_submitted
          | :invalid_power
          | :power_already_used
          | :invalid_power_target
          | :invalid_section_count
          | :invalid_origin
          | :invalid_section
          | :station_revisited
          | :section_reused
          | :section_crossing
          | :invalid_destination
          | :invalid_choice

  @type instruction :: %{
          required(:turn) => pos_integer(),
          required(:cards) => [Ruleset.card_id()],
          required(:destination) => Ruleset.destination(),
          required(:switch) => boolean(),
          required(:final) => boolean()
        }

  @spec ready_to_start?(Game.t()) :: boolean()
  def ready_to_start?(%{players: players}), do: map_size(players) in Ruleset.player_range()

  @spec participant?(Game.t(), term()) :: boolean()
  def participant?(%{players: players}, player_id) when is_binary(player_id),
    do: Map.has_key?(players, player_id)

  def participant?(_game, _player_id), do: false

  @spec submit_allowed?(Game.t(), term()) :: boolean()
  def submit_allowed?(%{phase: :build} = game, player_id) do
    case Map.fetch(game.players, player_id) do
      {:ok, %{status: :pending}} -> true
      _ -> false
    end
  end

  def submit_allowed?(_game, _player_id), do: false

  @spec available_power(Game.t(), D20.Actors.Actor.id()) ::
          {:ok, Ruleset.power_id()} | :error
  def available_power(game, player_id) do
    with true <- submit_allowed?(game, player_id),
         true <- is_map(game.powers),
         {:ok, player} <- Map.fetch(game.players, player_id),
         {:ok, color} <- current_color(game, player_id),
         %{power_used: false} <- Map.fetch!(player.lines, color),
         power when not is_nil(power) <- Map.get(game.powers, color) do
      {:ok, power}
    else
      _error -> :error
    end
  end

  @spec draw_available?(Game.t(), D20.Actors.Actor.id()) :: boolean()
  def draw_available?(game, player_id) do
    submit_allowed?(game, player_id) and
      (legal_sections(game, player_id) != [] or powered_sections_available?(game, player_id))
  end

  @spec validate(Game.t(), D20.Command.t()) :: :ok | {:error, reason()}
  def validate(game, %D20.Command{event: "join", actor_id: player_id}) do
    if participant?(game, player_id) or map_size(game.players) < 4,
      do: :ok,
      else: {:error, :player_limit_reached}
  end

  def validate(_game, %D20.Command{event: "leave"}), do: :ok

  def validate(game, %D20.Command{event: "start", actor_id: player_id}) do
    with :ok <- require_participant(game, player_id),
         :ok <- require_ready(game) do
      :ok
    end
  end

  def validate(game, %D20.Command{event: "prepare_round", actor_id: actor_id, attrs: attrs}) do
    with :ok <- require_system_actor(actor_id),
         :ok <- validate_round_setup(game, attrs) do
      :ok
    end
  end

  @spec resolve_action(Game.t(), D20.Command.t()) :: {:ok, Game.player()} | {:error, reason()}
  def resolve_action(game, %D20.Command{event: event, actor_id: player_id, attrs: attrs})
      when event in ["draw_sections", "pass"] do
    with :ok <- require_participant(game, player_id),
         {:ok, player} <- require_pending_player(game, player_id),
         {:ok, color} <- current_color(game, player_id),
         :ok <- validate_power(game, player, color, event, attrs),
         :ok <- validate_section_count(event, attrs),
         {:ok, player} <- apply_action(game, player, color, event, attrs) do
      {:ok, player}
    end
  end

  @spec validate_round_setup(Game.t(), map()) :: :ok | {:error, :invalid_system_setup}
  def validate_round_setup(game, attrs) do
    valid? =
      Ruleset.valid_deck_permutation?(attrs.deck) and valid_pencil_setup?(game, attrs) and
        valid_objective_setup?(game, attrs.objectives) and valid_power_setup?(game, attrs.powers)

    if valid?, do: :ok, else: {:error, :invalid_system_setup}
  end

  @spec current_color(Game.t(), D20.Actors.Actor.id()) ::
          {:ok, Ruleset.color()} | {:error, :not_joined | :invalid_system_setup}
  def current_color(game, player_id) do
    with {:ok, player} <- Map.fetch(game.players, player_id),
         offset when is_integer(offset) <- player.pencil_offset,
         true <- length(game.pencil_cycle) == 4 do
      {:ok, Enum.at(game.pencil_cycle, rem(offset + game.round - 1, 4))}
    else
      :error -> {:error, :not_joined}
      _error -> {:error, :invalid_system_setup}
    end
  end

  @spec current_instruction(Game.t()) :: instruction() | nil
  def current_instruction(%{draws: []}), do: nil

  def current_instruction(%{draws: draws}) do
    %{cards: cards} = List.last(draws)
    destination_card = cards |> List.last() |> Ruleset.card!()

    %{
      turn: length(draws),
      cards: cards,
      destination: destination_card.destination,
      switch: length(cards) == 2 and length(draws) > 2,
      final: underground_count(draws) == 5
    }
  end

  @spec underground_count([Game.draw()]) :: non_neg_integer()
  def underground_count(draws) do
    draws
    |> Enum.flat_map(& &1.cards)
    |> Enum.count(&Ruleset.underground?/1)
  end

  @spec turn_complete?(Game.t()) :: boolean()
  def turn_complete?(game) do
    map_size(game.players) > 0 and
      Enum.all?(game.players, fn {_id, player} -> player.status == :submitted end)
  end

  @spec line_nodes(Game.line(), Ruleset.color()) :: MapSet.t(Ruleset.station_id())
  def line_nodes(line, color) do
    departure = Map.fetch!(Ruleset.departure_stations(), color)

    Enum.reduce(line.edges, MapSet.new([departure]), fn edge_id, nodes ->
      edge = edge_by_id!(edge_id)
      nodes |> MapSet.put(edge.from) |> MapSet.put(edge.to)
    end)
  end

  @spec legal_origins(Game.line(), Ruleset.color(), boolean()) :: [Ruleset.station_id()]
  def legal_origins(line, color, switch?) do
    nodes = line_nodes(line, color)

    cond do
      line.edges == [] -> MapSet.to_list(nodes)
      switch? -> MapSet.to_list(nodes)
      true -> degree_one_nodes(line)
    end
  end

  @spec legal_sections(Game.t(), D20.Actors.Actor.id(), keyword()) :: [map()]
  def legal_sections(game, player_id, opts \\ []) do
    with {:ok, player} <- Map.fetch(game.players, player_id),
         {:ok, color} <- current_color(game, player_id),
         %{} = instruction <- current_instruction(game) do
      switch? = Keyword.get(opts, :switch, instruction.switch)
      destination = Keyword.get(opts, :destination, instruction.destination)
      chosen_symbol = Keyword.get(opts, :chosen_symbol)

      player
      |> Map.fetch!(:lines)
      |> Map.fetch!(color)
      |> candidate_sections(color, switch?)
      |> Enum.filter(fn section ->
        match?(
          {:ok, _player},
          apply_sections(game, player, color, [section], destination, chosen_symbol, switch?)
        )
      end)
    else
      _error -> []
    end
  end

  @spec legal_double_sections(Game.t(), D20.Actors.Actor.id()) :: [map()]
  def legal_double_sections(game, player_id) do
    with {:ok, player} <- Map.fetch(game.players, player_id),
         {:ok, color} <- current_color(game, player_id),
         %{} = instruction <- current_instruction(game) do
      chosen_symbols =
        if instruction.destination == :joker, do: Ruleset.ordinary_symbols(), else: [nil]

      Enum.flat_map(chosen_symbols, fn chosen_symbol ->
        double_section_sequences(
          game,
          player,
          color,
          instruction.destination,
          chosen_symbol,
          instruction.switch
        )
      end)
    else
      _error -> []
    end
  end

  @spec double_station_targets(Game.t(), D20.Actors.Actor.id()) :: [Ruleset.station_id()]
  def double_station_targets(game, player_id) do
    with {:ok, player} <- Map.fetch(game.players, player_id),
         {:ok, color} <- current_color(game, player_id) do
      line = Map.fetch!(player.lines, color)

      line |> line_nodes(color) |> MapSet.to_list() |> Enum.sort()
    else
      _error -> []
    end
  end

  @spec double_station_section_options(Game.t(), D20.Actors.Actor.id()) :: [map()]
  def double_station_section_options(game, player_id) do
    with {:ok, player} <- Map.fetch(game.players, player_id),
         {:ok, color} <- current_color(game, player_id) do
      line = Map.fetch!(player.lines, color)
      existing = MapSet.to_list(line_nodes(line, color))

      game
      |> legal_sections(player_id)
      |> Enum.map(fn section ->
        %{section: section, targets: Enum.sort(Enum.uniq([section.to | existing]))}
      end)
    else
      _error -> []
    end
  end

  @spec score_line(Game.line(), Ruleset.color()) :: map()
  def score_line(line, color) do
    nodes = line_nodes(line, color)
    district_counts = nodes |> Enum.map(&Ruleset.station!(&1).district) |> Enum.frequencies()

    district_counts =
      case line.doubled_station do
        nil ->
          district_counts

        station_id ->
          Map.update!(district_counts, Ruleset.station!(station_id).district, &(&1 + 1))
      end

    district_count = map_size(district_counts)
    largest_district = district_counts |> Map.values() |> Enum.max()

    thames_crossings =
      Enum.count(line.edges, fn edge_id -> edge_by_id!(edge_id).crosses_thames end)

    %{
      districts: district_count,
      largest_district: largest_district,
      thames_crossings: thames_crossings,
      total: district_count * largest_district + 2 * thames_crossings
    }
  end

  @spec score_player(Game.t(), Game.player()) :: map()
  def score_player(game, player) do
    line_scores = Map.new(player.lines, fn {color, line} -> {color, score_line(line, color)} end)
    line_total = line_scores |> Map.values() |> Enum.map(& &1.total) |> Enum.sum()

    tourist_marks =
      player.lines
      |> Enum.flat_map(fn {color, line} -> MapSet.to_list(line_nodes(line, color)) end)
      |> Enum.count(&Ruleset.station!(&1).tourist)
      |> min(10)

    tourist_score = Ruleset.tourist_score(tourist_marks)
    interchange_counts = interchange_counts(player)

    interchange_score =
      Enum.reduce(interchange_counts, 0, fn {line_count, count}, total ->
        total + count * Ruleset.interchange_score(line_count)
      end)

    achieved_objectives = achieved_objectives(game.objectives || [], player)
    objective_score = length(achieved_objectives) * Ruleset.objective_score()

    %{
      lines: line_scores,
      line_total: line_total,
      tourist_marks: tourist_marks,
      tourist_score: tourist_score,
      interchange_counts: interchange_counts,
      interchange_score: interchange_score,
      achieved_objectives: achieved_objectives,
      objective_score: objective_score,
      total: line_total + tourist_score + interchange_score + objective_score
    }
  end

  @spec scores(Game.t()) :: %{D20.Actors.Actor.id() => map()}
  def scores(game),
    do: Map.new(game.players, fn {id, player} -> {id, score_player(game, player)} end)

  @spec outcome(Game.t()) :: map()
  def outcome(game) when map_size(game.players) == 1 do
    [{player_id, score}] = Map.to_list(scores(game))
    penalty_count = Enum.count([game.objectives, game.powers], &(not is_nil(&1)))
    rating_score = score.total - penalty_count * Ruleset.module_penalty()

    %{
      mode: :solo,
      player_id: player_id,
      score: score.total,
      rating_score: rating_score,
      rating: Ruleset.solo_band(rating_score)
    }
  end

  def outcome(game) do
    scores = scores(game)
    highest_total = scores |> Map.values() |> Enum.map(& &1.total) |> Enum.max()
    candidates = Enum.filter(scores, fn {_id, score} -> score.total == highest_total end)

    highest_line =
      candidates
      |> Enum.map(fn {_id, score} ->
        score.lines |> Map.values() |> Enum.map(& &1.total) |> Enum.max()
      end)
      |> Enum.max()

    winners =
      candidates
      |> Enum.filter(fn {_id, score} ->
        score.lines |> Map.values() |> Enum.any?(&(&1.total == highest_line))
      end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    %{mode: :multiplayer, winners: winners, shared: length(winners) > 1}
  end

  @spec achieved_objectives([Ruleset.objective_id()], Game.player()) :: [Ruleset.objective_id()]
  def achieved_objectives(objective_ids, player) do
    Enum.filter(objective_ids, &objective_achieved?(&1, player))
  end

  defp require_participant(game, player_id) do
    if participant?(game, player_id), do: :ok, else: {:error, :not_joined}
  end

  defp powered_sections_available?(game, player_id) do
    case available_power(game, player_id) do
      {:ok, :double_section} -> legal_double_sections(game, player_id) != []
      {:ok, :joker} -> legal_sections(game, player_id, destination: :joker) != []
      {:ok, :railroad_switch} -> legal_sections(game, player_id, switch: true) != []
      {:ok, :double_station} -> legal_sections(game, player_id) != []
      :error -> false
    end
  end

  defp require_ready(game) do
    if ready_to_start?(game), do: :ok, else: {:error, :not_ready}
  end

  defp require_system_actor(nil), do: :ok
  defp require_system_actor(_actor_id), do: {:error, :system_only}

  defp require_pending_player(game, player_id) do
    case Map.fetch(game.players, player_id) do
      {:ok, %{status: :pending} = player} -> {:ok, player}
      {:ok, _player} -> {:error, :already_submitted}
      :error -> {:error, :not_joined}
    end
  end

  defp valid_pencil_setup?(%{round: 1} = game, attrs) do
    player_count = map_size(game.players)
    offsets = attrs.pencil_offsets
    expected_offsets = 0..3 |> Enum.take(player_count) |> MapSet.new()

    player_count in Ruleset.player_range() and is_list(attrs.pencil_cycle) and
      length(attrs.pencil_cycle) == 4 and
      MapSet.new(attrs.pencil_cycle) == MapSet.new(Ruleset.colors()) and is_map(offsets) and
      MapSet.new(Map.keys(offsets)) == MapSet.new(Map.keys(game.players)) and
      MapSet.new(Map.values(offsets)) == expected_offsets
  end

  defp valid_pencil_setup?(_game, attrs) do
    is_nil(attrs.pencil_cycle) and is_nil(attrs.pencil_offsets)
  end

  defp valid_objective_setup?(%{round: 1, objectives: nil}, nil), do: true

  defp valid_objective_setup?(%{round: 1, objectives: []}, objective_ids) do
    is_list(objective_ids) and length(objective_ids) == 2 and
      MapSet.size(MapSet.new(objective_ids)) == 2 and
      Enum.all?(objective_ids, &(&1 in Ruleset.objective_ids()))
  end

  defp valid_objective_setup?(%{round: 1}, _objective_ids), do: false
  defp valid_objective_setup?(_game, nil), do: true
  defp valid_objective_setup?(_game, _objective_ids), do: false

  defp valid_power_setup?(%{round: 1, powers: nil}, nil), do: true

  defp valid_power_setup?(%{round: 1, powers: %{}}, powers) do
    is_map(powers) and MapSet.new(Map.keys(powers)) == MapSet.new(Ruleset.colors()) and
      MapSet.new(Map.values(powers)) == MapSet.new(Ruleset.power_ids())
  end

  defp valid_power_setup?(%{round: 1}, _powers), do: false
  defp valid_power_setup?(_game, nil), do: true
  defp valid_power_setup?(_game, _powers), do: false

  defp validate_power(game, player, color, event, attrs) do
    power = attrs.power
    line = Map.fetch!(player.lines, color)

    cond do
      event == "pass" and power not in [nil, :double_station] ->
        {:error, :invalid_power}

      is_nil(power) and not is_nil(attrs.power_target) ->
        {:error, :invalid_power_target}

      power != :double_station and not is_nil(attrs.power_target) ->
        {:error, :invalid_power_target}

      is_nil(power) ->
        :ok

      line.power_used ->
        {:error, :power_already_used}

      not is_map(game.powers) or Map.get(game.powers, color) != power ->
        {:error, :invalid_power}

      true ->
        :ok
    end
  end

  defp validate_section_count("pass", _attrs), do: :ok

  defp validate_section_count("draw_sections", attrs) do
    expected = if attrs.power == :double_section, do: 2, else: 1
    if length(attrs.sections) == expected, do: :ok, else: {:error, :invalid_section_count}
  end

  defp apply_action(_game, player, color, "pass", attrs) do
    apply_power_result(player, color, attrs.power, attrs.power_target)
  end

  defp apply_action(game, player, color, "draw_sections", attrs) do
    instruction = current_instruction(game)
    destination = if attrs.power == :joker, do: :joker, else: instruction.destination
    switch? = instruction.switch or attrs.power == :railroad_switch

    with :ok <- validate_choice(destination, attrs.power, attrs.chosen_symbol),
         {:ok, player} <-
           apply_sections(
             game,
             player,
             color,
             attrs.sections,
             destination,
             attrs.chosen_symbol,
             switch?
           ),
         {:ok, player} <- apply_power_result(player, color, attrs.power, attrs.power_target) do
      {:ok, player}
    end
  end

  defp validate_choice(:joker, :double_section, symbol)
       when symbol in [:circle, :square, :triangle, :pentagon],
       do: :ok

  defp validate_choice(:joker, :double_section, _symbol), do: {:error, :invalid_choice}
  defp validate_choice(:joker, _power, nil), do: :ok

  defp validate_choice(:joker, _power, symbol)
       when symbol in [:circle, :square, :triangle, :pentagon],
       do: :ok

  defp validate_choice(_destination, _power, nil), do: :ok
  defp validate_choice(_destination, _power, _symbol), do: {:error, :invalid_choice}

  defp apply_sections(game, player, color, sections, destination, chosen_symbol, switch?) do
    sections
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, player}, fn {section, index}, {:ok, candidate} ->
      section_switch? = switch? and index == 0

      case apply_section(
             game,
             candidate,
             color,
             section,
             destination,
             chosen_symbol,
             section_switch?
           ) do
        {:ok, candidate} -> {:cont, {:ok, candidate}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp double_section_sequences(game, player, color, destination, chosen_symbol, switch?) do
    line = Map.fetch!(player.lines, color)

    line
    |> candidate_sections(color, switch?)
    |> Enum.filter(fn first ->
      match?(
        {:ok, _candidate},
        apply_sections(game, player, color, [first], destination, chosen_symbol, switch?)
      )
    end)
    |> Enum.flat_map(fn first ->
      {:ok, candidate} =
        apply_sections(game, player, color, [first], destination, chosen_symbol, switch?)

      candidate.lines
      |> Map.fetch!(color)
      |> candidate_sections(color, false)
      |> Enum.filter(fn second ->
        match?(
          {:ok, _candidate},
          apply_sections(
            game,
            player,
            color,
            [first, second],
            destination,
            chosen_symbol,
            switch?
          )
        )
      end)
      |> Enum.map(fn second -> %{sections: [first, second], chosen_symbol: chosen_symbol} end)
    end)
  end

  defp apply_section(_game, player, color, section, destination, chosen_symbol, switch?) do
    line = Map.fetch!(player.lines, color)
    origins = legal_origins(line, color, switch?)
    edge_id = Ruleset.edge_id(section.from, section.to)

    with :ok <- require_true(section.from in origins, :invalid_origin),
         {:ok, _edge} <- normalize_edge_error(Ruleset.fetch_edge(edge_id)),
         :ok <-
           require_false(MapSet.member?(line_nodes(line, color), section.to), :station_revisited),
         :ok <- require_false(edge_used?(player, edge_id), :section_reused),
         :ok <- require_false(crosses_network?(player, edge_id), :section_crossing),
         :ok <-
           require_true(
             destination_matches?(section.to, destination, chosen_symbol),
             :invalid_destination
           ) do
      updated_line = %{line | edges: line.edges ++ [edge_id]}
      {:ok, put_in(player.lines[color], updated_line)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_edge_error({:ok, edge}), do: {:ok, edge}
  defp normalize_edge_error(:error), do: {:error, :invalid_section}

  defp require_true(true, _reason), do: :ok
  defp require_true(false, reason), do: {:error, reason}

  defp require_false(false, _reason), do: :ok
  defp require_false(true, reason), do: {:error, reason}

  defp apply_power_result(player, _color, nil, nil), do: {:ok, player}

  defp apply_power_result(player, color, :double_station, station_id) do
    line = Map.fetch!(player.lines, color)

    if is_binary(station_id) and MapSet.member?(line_nodes(line, color), station_id) do
      updated_line = %{line | power_used: true, doubled_station: station_id}
      {:ok, put_in(player.lines[color], updated_line)}
    else
      {:error, :invalid_power_target}
    end
  end

  defp apply_power_result(player, color, _power, nil) do
    {:ok, update_in(player.lines[color], &%{&1 | power_used: true})}
  end

  defp degree_one_nodes(line) do
    line.edges
    |> Enum.flat_map(fn edge_id ->
      edge = edge_by_id!(edge_id)
      [edge.from, edge.to]
    end)
    |> Enum.frequencies()
    |> Enum.filter(fn {_station_id, degree} -> degree == 1 end)
    |> Enum.map(&elem(&1, 0))
  end

  defp candidate_sections(line, color, switch?) do
    line
    |> legal_origins(color, switch?)
    |> Enum.flat_map(&incident_sections/1)
    |> Enum.uniq()
  end

  defp incident_sections(station_id) do
    Ruleset.edges()
    |> Map.values()
    |> Enum.flat_map(fn edge ->
      cond do
        edge.from == station_id -> [%{from: station_id, to: edge.to}]
        edge.to == station_id -> [%{from: station_id, to: edge.from}]
        true -> []
      end
    end)
  end

  defp destination_matches?(station_id, _destination, _chosen_symbol)
       when station_id == "r3c5",
       do: true

  defp destination_matches?(station_id, :joker, nil) do
    Ruleset.station!(station_id).symbol in Ruleset.ordinary_symbols()
  end

  defp destination_matches?(station_id, :joker, chosen_symbol) do
    Ruleset.station!(station_id).symbol == chosen_symbol
  end

  defp destination_matches?(station_id, destination, _chosen_symbol) do
    Ruleset.station!(station_id).symbol == destination
  end

  defp edge_used?(player, edge_id) do
    Enum.any?(player.lines, fn {_color, line} -> edge_id in line.edges end)
  end

  defp crosses_network?(player, candidate_edge_id) do
    player.lines
    |> Enum.flat_map(fn {_color, line} -> line.edges end)
    |> Enum.any?(&edges_cross?(candidate_edge_id, &1))
  end

  defp edges_cross?(left_id, right_id) do
    left = edge_by_id!(left_id)
    right = edge_by_id!(right_id)

    shared =
      MapSet.intersection(MapSet.new([left.from, left.to]), MapSet.new([right.from, right.to]))

    if MapSet.size(shared) > 0 do
      false
    else
      segments_intersect?(left, right)
    end
  end

  defp segments_intersect?(left, right) do
    a = Ruleset.station!(left.from)
    b = Ruleset.station!(left.to)
    c = Ruleset.station!(right.from)
    d = Ruleset.station!(right.to)

    o1 = orientation(a, b, c)
    o2 = orientation(a, b, d)
    o3 = orientation(c, d, a)
    o4 = orientation(c, d, b)

    (o1 != o2 and o3 != o4) or (o1 == 0 and on_segment?(a, c, b)) or
      (o2 == 0 and on_segment?(a, d, b)) or (o3 == 0 and on_segment?(c, a, d)) or
      (o4 == 0 and on_segment?(c, b, d))
  end

  defp orientation(a, b, c) do
    value = (b.column - a.column) * (c.row - a.row) - (b.row - a.row) * (c.column - a.column)

    cond do
      value > 0 -> 1
      value < 0 -> -1
      true -> 0
    end
  end

  defp on_segment?(a, point, b) do
    point.row >= min(a.row, b.row) and point.row <= max(a.row, b.row) and
      point.column >= min(a.column, b.column) and point.column <= max(a.column, b.column)
  end

  defp edge_by_id!(edge_id) do
    {:ok, edge} = Ruleset.fetch_edge(edge_id)
    edge
  end

  defp interchange_counts(player) do
    station_lines =
      Enum.reduce(player.lines, %{}, fn {color, line}, stations ->
        Enum.reduce(line_nodes(line, color), stations, fn station_id, stations ->
          Map.update(stations, station_id, MapSet.new([color]), &MapSet.put(&1, color))
        end)
      end)

    station_lines
    |> Enum.map(fn {_station_id, colors} -> MapSet.size(colors) end)
    |> Enum.filter(&(&1 in 2..4))
    |> Enum.frequencies()
  end

  defp objective_achieved?(:eight_interchanges, player) do
    player
    |> interchange_counts()
    |> Map.values()
    |> Enum.sum() >= 8
  end

  defp objective_achieved?(:all_districts, player) do
    player |> network_nodes() |> Enum.map(&Ruleset.station!(&1).district) |> MapSet.new() ==
      MapSet.new(Ruleset.districts())
  end

  defp objective_achieved?(:all_tourist_sites, player) do
    MapSet.subset?(MapSet.new(Ruleset.tourist_station_ids()), network_nodes(player))
  end

  defp objective_achieved?(:central_district, player) do
    central =
      Ruleset.stations()
      |> Enum.filter(fn {_id, station} -> station.district == :central end)
      |> Enum.map(&elem(&1, 0))
      |> MapSet.new()

    MapSet.subset?(central, network_nodes(player))
  end

  defp objective_achieved?(:six_thames_crossings, player) do
    player.lines
    |> Enum.flat_map(fn {_color, line} -> line.edges end)
    |> Enum.count(&edge_by_id!(&1).crosses_thames) >= 6
  end

  defp network_nodes(player) do
    Enum.reduce(player.lines, MapSet.new(), fn {color, line}, nodes ->
      MapSet.union(nodes, line_nodes(line, color))
    end)
  end
end
