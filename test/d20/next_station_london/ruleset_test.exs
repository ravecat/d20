defmodule D20.NextStationLondon.RulesetTest do
  use ExUnit.Case, async: true

  alias D20.NextStationLondon.Ruleset

  test "encodes the exact station inventory and special stations" do
    stations = Ruleset.stations()

    assert map_size(stations) == 53

    assert stations |> Map.values() |> Enum.frequencies_by(& &1.symbol) == %{
             circle: 13,
             square: 13,
             triangle: 13,
             pentagon: 13,
             wild: 1
           }

    assert Ruleset.tourist_station_ids() == ["r1c6", "r3c0", "r3c5", "r6c9", "r9c4"]

    assert Ruleset.departure_stations() == %{
             green: "r2c3",
             pink: "r3c7",
             purple: "r5c2",
             blue: "r7c5"
           }

    assert %{symbol: :wild, district: :central, tourist: true} = Ruleset.station!("r3c5")
  end

  test "assigns every station to one of the thirteen districts" do
    assert Ruleset.stations() |> Map.values() |> Enum.frequencies_by(& &1.district) == %{
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
  end

  test "builds the exact nearest-station graph and Thames flags" do
    edges = Ruleset.edges()

    assert map_size(edges) == 155
    assert Enum.count(edges, fn {_id, edge} -> edge.crosses_thames end) == 24

    assert {:ok, %{crosses_thames: true}} = Ruleset.fetch_edge("r2c3", "r6c3")
    assert {:ok, %{crosses_thames: false}} = Ruleset.fetch_edge("r0c0", "r0c1")
    assert {:ok, %{from: "r0c2", to: "r0c4"}} = Ruleset.fetch_edge("r0c2", "r0c4")
    assert :error = Ruleset.fetch_edge("r0c1", "r0c4")
  end

  test "validates static integrity and rejects altered fixtures" do
    assert :ok = Ruleset.validate_static()

    data = Ruleset.static_data()
    assert {:error, :invalid_stations} = Ruleset.validate_static(%{data | stations: %{}})
    assert {:error, :invalid_edges} = Ruleset.validate_static(%{data | edges: %{}})
    assert {:error, :invalid_cards} = Ruleset.validate_static(%{data | cards: []})

    assert {:error, :invalid_scores} =
             Ruleset.validate_static(%{data | tourist_scores: %{0 => 1}})
  end

  test "exposes the exact Station deck" do
    cards = Ruleset.cards()

    assert Enum.count_until(cards, 12) == 11
    assert Enum.count(cards, &(&1.kind == :street)) == 6
    assert Enum.count(cards, &(&1.kind == :underground)) == 5
    assert Enum.count(cards, &(&1.destination == :joker)) == 2
    assert Enum.count(cards, &(&1.destination == :railroad_switch)) == 1
    assert Ruleset.valid_deck_permutation?(Enum.reverse(Ruleset.card_ids()))
    refute Ruleset.valid_deck_permutation?(tl(Ruleset.card_ids()))
    refute Ruleset.valid_deck_permutation?(Ruleset.card_ids() ++ ["street_circle"])
  end

  test "exposes scoring tables and continuous solo bands" do
    assert Enum.map(0..10, &Ruleset.tourist_score/1) == [0, 1, 2, 4, 6, 8, 11, 14, 17, 21, 25]
    assert Enum.map(2..4, &Ruleset.interchange_score/1) == [2, 5, 9]
    assert Ruleset.objective_score() == 10
    assert Ruleset.module_penalty() == 10

    assert Ruleset.solo_band(89) == :under_90
    assert Ruleset.solo_band(90) == :from_90_to_105
    assert Ruleset.solo_band(105) == :from_90_to_105
    assert Ruleset.solo_band(106) == :from_106_to_120
    assert Ruleset.solo_band(120) == :from_106_to_120
    assert Ruleset.solo_band(121) == :from_121_to_135
    assert Ruleset.solo_band(135) == :from_121_to_135
    assert Ruleset.solo_band(136) == :from_136_to_150
    assert Ruleset.solo_band(150) == :from_136_to_150
    assert Ruleset.solo_band(151) == :over_150
  end
end
