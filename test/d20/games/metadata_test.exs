defmodule D20.Games.MetadataTest do
  use ExUnit.Case, async: true

  alias D20.Games.Metadata

  test "builds runtime metadata from BGG attrs" do
    assert {:ok, %Metadata{} = metadata} =
             Metadata.new(%{
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

    assert metadata.name == "Qwinto"
    assert metadata.alternate_names == ["Qwinto: Das Kartenspiel"]
    assert metadata.categories == ["Dice", "Number"]
    assert metadata.mechanics == ["Dice Rolling", "Paper-and-Pencil"]
    assert metadata.description == "Resolved from BGG."
    assert metadata.thumbnail_url == "https://example.invalid/thumb.jpg"
    assert metadata.image_url == "https://example.invalid/image.jpg"
    assert metadata.complexity == 2.1
    assert metadata.rating == 7.4
    refute Map.has_key?(metadata, :bgg_id)
    refute Map.has_key?(metadata, :slug)
  end

  test "does not require provider metadata fields" do
    assert {:ok, %Metadata{} = metadata} = Metadata.new(%{})

    assert metadata.name == nil
    assert metadata.categories == []
    assert metadata.mechanics == []
    assert metadata.description == nil
    assert metadata.image_url == nil
    assert metadata.complexity == nil
    assert metadata.rating == nil
  end

  test "empty metadata is available" do
    assert %Metadata{name: nil} = Metadata.empty()
  end
end
