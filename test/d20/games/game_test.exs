defmodule D20.Games.GameTest do
  use ExUnit.Case, async: true

  alias D20.Games.Game

  test "builds a game from runtime metadata attrs" do
    assert {:ok, %Game{} = game} =
             Game.new(%{
               bgg_id: 183_006,
               name: "Qwinto",
               alternate_names: ["Qwinto: Das Kartenspiel"],
               categories: ["Dice", "Number"],
               mechanics: ["Dice Rolling", "Paper-and-Pencil"],
               description: "Resolved from BGG.",
               thumbnail_url: "https://example.invalid/thumb.jpg",
               image_url: "https://example.invalid/image.jpg",
               year_published: 2015,
               min_players: 2,
               max_players: 6,
               playing_time: 15,
               min_play_time: 15,
               max_play_time: 15,
               min_age: 8,
               complexity: 2.1,
               rating: 7.4
             })

    assert game.name == "Qwinto"
    assert game.alternate_names == ["Qwinto: Das Kartenspiel"]
    assert game.categories == ["Dice", "Number"]
    assert game.mechanics == ["Dice Rolling", "Paper-and-Pencil"]
    assert game.description == "Resolved from BGG."
    assert game.thumbnail_url == "https://example.invalid/thumb.jpg"
    assert game.image_url == "https://example.invalid/image.jpg"
    assert game.complexity == 2.1
    assert game.rating == 7.4
    refute Map.has_key?(game, :bgg_id)
    refute Map.has_key?(game, :slug)
  end

  test "does not invent a fallback title" do
    assert {:ok, %Game{} = game} = Game.new(%{name: nil})

    assert game.name == nil
  end

  test "does not require provider metadata fields" do
    assert {:ok, %Game{} = game} = Game.new(%{})

    assert game.name == nil
    assert game.categories == []
    assert game.mechanics == []
    assert game.description == nil
    assert game.image_url == nil
    assert game.complexity == nil
    assert game.rating == nil
  end
end
