defmodule D20.NextStationLondon.Ruleset do
  @moduledoc """
  Static map, card, module, and scoring data for Next Station: London.
  """

  @colors [:green, :blue, :pink, :purple]
  @ordinary_symbols [:circle, :square, :triangle, :pentagon]
  @symbols @ordinary_symbols ++ [:wild]
  @objective_ids [
    :eight_interchanges,
    :all_districts,
    :all_tourist_sites,
    :central_district,
    :six_thames_crossings
  ]
  @power_ids [:double_section, :joker, :railroad_switch, :double_station]
  @tourist_scores %{
    0 => 0,
    1 => 1,
    2 => 2,
    3 => 4,
    4 => 6,
    5 => 8,
    6 => 11,
    7 => 14,
    8 => 17,
    9 => 21,
    10 => 25
  }
  @interchange_scores %{2 => 2, 3 => 5, 4 => 9}

  @station_rows [
    {0,
     [
       {0, :pentagon, []},
       {1, :triangle, []},
       {2, :square, []},
       {4, :triangle, []},
       {5, :circle, []},
       {7, :triangle, []},
       {9, :circle, []}
     ]},
    {1,
     [
       {1, :pentagon, []},
       {3, :square, []},
       {6, :pentagon, [tourist: true]},
       {8, :square, []},
       {9, :pentagon, []}
     ]},
    {2,
     [{0, :circle, []}, {3, :triangle, [departure: :green]}, {6, :square, []}, {9, :triangle, []}]},
    {3,
     [
       {0, :square, [tourist: true]},
       {2, :pentagon, []},
       {4, :triangle, []},
       {5, :wild, [tourist: true]},
       {6, :circle, []},
       {7, :circle, [departure: :pink]},
       {9, :square, []}
     ]},
    {4,
     [
       {1, :triangle, []},
       {2, :square, []},
       {4, :pentagon, []},
       {5, :square, []},
       {8, :pentagon, []}
     ]},
    {5,
     [{0, :pentagon, []}, {2, :square, [departure: :purple]}, {4, :circle, []}, {7, :circle, []}]},
    {6,
     [
       {3, :pentagon, []},
       {4, :triangle, []},
       {6, :square, []},
       {7, :triangle, []},
       {9, :triangle, [tourist: true]}
     ]},
    {7,
     [
       {0, :circle, []},
       {2, :square, []},
       {3, :circle, []},
       {5, :pentagon, [departure: :blue]},
       {8, :circle, []},
       {9, :pentagon, []}
     ]},
    {8, [{1, :circle, []}, {6, :pentagon, []}, {8, :triangle, []}]},
    {9,
     [
       {0, :triangle, []},
       {1, :square, []},
       {3, :pentagon, []},
       {4, :circle, [tourist: true]},
       {5, :triangle, []},
       {7, :circle, []},
       {9, :square, []}
     ]}
  ]

  @stations (
              district = fn row, column ->
                cond do
                  row == 0 and column == 0 -> :outer_northwest
                  row == 0 and column == 9 -> :outer_northeast
                  row == 9 and column == 0 -> :outer_southwest
                  row == 9 and column == 9 -> :outer_southeast
                  row <= 2 and column <= 2 -> :northwest
                  row <= 2 and column <= 6 -> :north
                  row <= 2 -> :northeast
                  row <= 6 and column <= 2 -> :west
                  row <= 6 and column <= 6 -> :central
                  row <= 6 -> :east
                  column <= 2 -> :southwest
                  column <= 6 -> :south
                  true -> :southeast
                end
              end

              for {row, entries} <- @station_rows, {column, symbol, opts} <- entries, into: %{} do
                id = "r#{row}c#{column}"

                {id,
                 %{
                   id: id,
                   row: row,
                   column: column,
                   symbol: symbol,
                   district: district.(row, column),
                   tourist: Keyword.get(opts, :tourist, false),
                   departure_color: Keyword.get(opts, :departure)
                 }}
              end
            )

  @thames_edge_ids MapSet.new([
                     "r2c0-r4c2",
                     "r3c0-r5c0",
                     "r3c0-r4c1",
                     "r1c1-r4c1",
                     "r3c2-r4c1",
                     "r3c2-r4c2",
                     "r4c2-r4c4",
                     "r3c4-r5c2",
                     "r5c2-r5c4",
                     "r2c3-r6c3",
                     "r5c4-r6c3",
                     "r4c4-r6c6",
                     "r5c4-r6c4",
                     "r5c4-r5c7",
                     "r3c7-r6c4",
                     "r3c5-r5c7",
                     "r4c5-r7c5",
                     "r4c5-r6c7",
                     "r3c6-r6c6",
                     "r3c6-r6c9",
                     "r3c7-r5c7",
                     "r4c8-r5c7",
                     "r4c8-r7c8",
                     "r3c9-r6c9"
                   ])

  @edges (
           stations = Map.values(@stations)

           aligned? = fn left, right ->
             row_delta = right.row - left.row
             column_delta = right.column - left.column

             row_delta == 0 or column_delta == 0 or abs(row_delta) == abs(column_delta)
           end

           between? = fn point, left, right ->
             cross =
               (point.column - left.column) * (right.row - left.row) -
                 (point.row - left.row) * (right.column - left.column)

             inside_rows =
               point.row >= min(left.row, right.row) and point.row <= max(left.row, right.row)

             inside_columns =
               point.column >= min(left.column, right.column) and
                 point.column <= max(left.column, right.column)

             cross == 0 and inside_rows and inside_columns and point.id not in [left.id, right.id]
           end

           stations
           |> Enum.with_index()
           |> Enum.flat_map(fn {left, index} ->
             stations
             |> Enum.drop(index + 1)
             |> Enum.filter(fn right ->
               aligned?.(left, right) and not Enum.any?(stations, &between?.(&1, left, right))
             end)
             |> Enum.map(fn right ->
               [from, to] = Enum.sort([left.id, right.id])
               id = "#{from}-#{to}"

               {id,
                %{
                  id: id,
                  from: from,
                  to: to,
                  crosses_thames: MapSet.member?(@thames_edge_ids, id)
                }}
             end)
           end)
           |> Map.new()
         )

  @cards [
    %{id: "street_circle", kind: :street, destination: :circle},
    %{id: "street_square", kind: :street, destination: :square},
    %{id: "street_triangle", kind: :street, destination: :triangle},
    %{id: "street_pentagon", kind: :street, destination: :pentagon},
    %{id: "street_joker", kind: :street, destination: :joker},
    %{id: "street_railroad_switch", kind: :street, destination: :railroad_switch},
    %{id: "underground_circle", kind: :underground, destination: :circle},
    %{id: "underground_square", kind: :underground, destination: :square},
    %{id: "underground_triangle", kind: :underground, destination: :triangle},
    %{id: "underground_pentagon", kind: :underground, destination: :pentagon},
    %{id: "underground_joker", kind: :underground, destination: :joker}
  ]
  @cards_by_id Map.new(@cards, &{&1.id, &1})
  @districts @stations |> Map.values() |> Enum.map(& &1.district) |> Enum.uniq()

  @type color :: :green | :blue | :pink | :purple
  @type ordinary_symbol :: :circle | :square | :triangle | :pentagon
  @type symbol :: ordinary_symbol() | :wild
  @type destination :: ordinary_symbol() | :joker | :railroad_switch
  @type card_kind :: :street | :underground
  @type card_id :: String.t()
  @type station_id :: String.t()
  @type edge_id :: String.t()
  @type district :: atom()
  @type objective_id ::
          :eight_interchanges
          | :all_districts
          | :all_tourist_sites
          | :central_district
          | :six_thames_crossings
  @type power_id :: :double_section | :joker | :railroad_switch | :double_station
  @type station :: %{
          required(:id) => station_id(),
          required(:row) => 0..9,
          required(:column) => 0..9,
          required(:symbol) => symbol(),
          required(:district) => district(),
          required(:tourist) => boolean(),
          required(:departure_color) => color() | nil
        }
  @type edge :: %{
          required(:id) => edge_id(),
          required(:from) => station_id(),
          required(:to) => station_id(),
          required(:crosses_thames) => boolean()
        }
  @type card :: %{
          required(:id) => card_id(),
          required(:kind) => card_kind(),
          required(:destination) => destination()
        }

  @spec colors() :: [color()]
  def colors, do: @colors

  @spec ordinary_symbols() :: [ordinary_symbol()]
  def ordinary_symbols, do: @ordinary_symbols

  @spec symbols() :: [symbol()]
  def symbols, do: @symbols

  @spec rounds() :: 4
  def rounds, do: 4

  @spec player_range() :: Range.t()
  def player_range, do: 1..4

  @spec stations() :: %{station_id() => station()}
  def stations, do: @stations

  @spec fetch_station(station_id()) :: {:ok, station()} | :error
  def fetch_station(id), do: Map.fetch(@stations, id)

  @spec station!(station_id()) :: station()
  def station!(id), do: Map.fetch!(@stations, id)

  @spec districts() :: [district()]
  def districts, do: @districts

  @spec tourist_station_ids() :: [station_id()]
  def tourist_station_ids do
    @stations
    |> Enum.filter(fn {_id, station} -> station.tourist end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  @spec departure_stations() :: %{color() => station_id()}
  def departure_stations do
    @stations
    |> Enum.reject(fn {_id, station} -> is_nil(station.departure_color) end)
    |> Map.new(fn {id, station} -> {station.departure_color, id} end)
  end

  @spec edges() :: %{edge_id() => edge()}
  def edges, do: @edges

  @spec edge_id(station_id(), station_id()) :: edge_id()
  def edge_id(left, right) do
    [from, to] = Enum.sort([left, right])
    "#{from}-#{to}"
  end

  @spec fetch_edge(station_id(), station_id()) :: {:ok, edge()} | :error
  def fetch_edge(left, right), do: Map.fetch(@edges, edge_id(left, right))

  @spec fetch_edge(edge_id()) :: {:ok, edge()} | :error
  def fetch_edge(id), do: Map.fetch(@edges, id)

  @spec cards() :: [card()]
  def cards, do: @cards

  @spec card_ids() :: [card_id()]
  def card_ids, do: Enum.map(@cards, & &1.id)

  @spec fetch_card(card_id()) :: {:ok, card()} | :error
  def fetch_card(id), do: Map.fetch(@cards_by_id, id)

  @spec card!(card_id()) :: card()
  def card!(id), do: Map.fetch!(@cards_by_id, id)

  @spec underground?(card_id()) :: boolean()
  def underground?(id) do
    case fetch_card(id) do
      {:ok, %{kind: :underground}} -> true
      _ -> false
    end
  end

  @spec railroad_switch?(card_id()) :: boolean()
  def railroad_switch?(id) do
    case fetch_card(id) do
      {:ok, %{destination: :railroad_switch}} -> true
      _ -> false
    end
  end

  @spec valid_deck_permutation?(term()) :: boolean()
  def valid_deck_permutation?(ids) when is_list(ids) do
    length(ids) == length(@cards) and Enum.sort(ids) == Enum.sort(card_ids())
  end

  def valid_deck_permutation?(_ids), do: false

  @spec objective_ids() :: [objective_id()]
  def objective_ids, do: @objective_ids

  @spec power_ids() :: [power_id()]
  def power_ids, do: @power_ids

  @spec tourist_score(0..10) :: non_neg_integer()
  def tourist_score(marks), do: Map.fetch!(@tourist_scores, marks)

  @spec interchange_score(2..4) :: pos_integer()
  def interchange_score(lines), do: Map.fetch!(@interchange_scores, lines)

  @spec objective_score() :: 10
  def objective_score, do: 10

  @spec module_penalty() :: 10
  def module_penalty, do: 10

  @spec solo_band(integer()) ::
          :under_90
          | :from_90_to_105
          | :from_106_to_120
          | :from_121_to_135
          | :from_136_to_150
          | :over_150
  def solo_band(score) when score < 90, do: :under_90
  def solo_band(score) when score <= 105, do: :from_90_to_105
  def solo_band(score) when score <= 120, do: :from_106_to_120
  def solo_band(score) when score <= 135, do: :from_121_to_135
  def solo_band(score) when score <= 150, do: :from_136_to_150
  def solo_band(_score), do: :over_150

  @spec static_data() :: map()
  def static_data do
    %{
      stations: @stations,
      edges: @edges,
      cards: @cards,
      tourist_scores: @tourist_scores,
      interchange_scores: @interchange_scores
    }
  end

  @spec validate_static(map()) :: :ok | {:error, atom()}
  def validate_static(data \\ static_data()) do
    with :ok <- validate_stations(data[:stations]),
         :ok <- validate_edges(data[:edges]),
         :ok <- validate_cards(data[:cards]) do
      validate_scores(data[:tourist_scores], data[:interchange_scores])
    end
  end

  defp validate_stations(stations) when is_map(stations) do
    symbol_counts = stations |> Map.values() |> Enum.frequencies_by(& &1.symbol)
    district_counts = stations |> Map.values() |> Enum.frequencies_by(& &1.district)

    expected_district_counts = %{
      northwest: 4,
      north: 6,
      northeast: 4,
      west: 6,
      central: 9,
      east: 6,
      southwest: 4,
      south: 6,
      southeast: 4,
      outer_northwest: 1,
      outer_northeast: 1,
      outer_southwest: 1,
      outer_southeast: 1
    }

    valid_ids? = Enum.all?(stations, fn {id, station} -> id == station.id end)

    if map_size(stations) == 53 and
         symbol_counts == %{circle: 13, square: 13, triangle: 13, pentagon: 13, wild: 1} and
         district_counts == expected_district_counts and valid_ids? do
      :ok
    else
      {:error, :invalid_stations}
    end
  end

  defp validate_stations(_stations), do: {:error, :invalid_stations}

  defp validate_edges(edges) when is_map(edges) do
    known_stations = Map.keys(@stations) |> MapSet.new()

    valid? =
      Enum.all?(edges, fn {id, edge} ->
        id == edge.id and id == edge_id(edge.from, edge.to) and edge.from != edge.to and
          MapSet.member?(known_stations, edge.from) and MapSet.member?(known_stations, edge.to) and
          edge.crosses_thames == MapSet.member?(@thames_edge_ids, id)
      end)

    thames_count = Enum.count(edges, fn {_id, edge} -> edge.crosses_thames end)

    if map_size(edges) == 155 and valid? and thames_count == 24 and
         MapSet.new(Map.keys(edges)) == MapSet.new(Map.keys(@edges)) do
      :ok
    else
      {:error, :invalid_edges}
    end
  end

  defp validate_edges(_edges), do: {:error, :invalid_edges}

  defp validate_cards(cards) when is_list(cards) do
    ids = Enum.map(cards, & &1.id)

    if Enum.count_until(cards, 12) == 11 and MapSet.size(MapSet.new(ids)) == 11 and
         Enum.sort(ids) == Enum.sort(card_ids()) do
      :ok
    else
      {:error, :invalid_cards}
    end
  end

  defp validate_cards(_cards), do: {:error, :invalid_cards}

  defp validate_scores(tourist_scores, interchange_scores) do
    if tourist_scores == @tourist_scores and interchange_scores == @interchange_scores do
      :ok
    else
      {:error, :invalid_scores}
    end
  end
end
