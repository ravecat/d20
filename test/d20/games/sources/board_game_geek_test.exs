defmodule D20.Games.Sources.BoardGameGeekTest do
  use ExUnit.Case, async: true

  alias D20.Games.Sources.BoardGameGeek

  @fixture Path.expand("../../../support/fixtures/games/board_game_geek_game.xml", __DIR__)

  test "parses core game details into normalized game attrs" do
    assert {:ok, [attrs]} = @fixture |> File.read!() |> BoardGameGeek.parse_game_details()

    assert %{
             external_id: 999_999,
             slug: nil,
             name: "Example Trade Game",
             alternate_names: ["Example Settlers"],
             description: "Trade, build, and settle.",
             thumbnail_url: "https://example.invalid/thumb.jpg",
             image_url: "https://example.invalid/image.jpg",
             year_published: 1995,
             min_players: 3,
             max_players: 4,
             playing_time: 120,
             min_play_time: 60,
             max_play_time: 120,
             min_age: 10
           } = attrs

    refute Map.has_key?(attrs, :ratings)
    refute Map.has_key?(attrs, :links)
    refute Map.has_key?(attrs, :versions)
  end

  test "returns an empty list when the response has no items" do
    assert BoardGameGeek.parse_game_details("<items />") == {:ok, []}
  end
end
