defmodule D20.Games.Sources.BoardGameGeekTest do
  use ExUnit.Case, async: false

  alias D20.Games.Sources.BoardGameGeek

  @fixture Path.expand("../../../support/fixtures/games/board_game_geek_game.xml", __DIR__)

  setup do
    original_config = Application.get_env(:d20, BoardGameGeek, :not_configured)

    on_exit(fn ->
      case original_config do
        :not_configured -> Application.delete_env(:d20, BoardGameGeek)
        config -> Application.put_env(:d20, BoardGameGeek, config)
      end
    end)
  end

  describe "api_key/0" do
    test "returns the configured runtime API key as is" do
      Application.put_env(:d20, BoardGameGeek, api_key: " test-key ")

      assert BoardGameGeek.api_key() == {:ok, " test-key "}
    end

    test "returns an error when the runtime API key is missing" do
      Application.put_env(:d20, BoardGameGeek, api_key: nil)

      assert BoardGameGeek.api_key() == {:error, :missing_api_key}
    end

    test "returns an empty configured runtime API key as is" do
      Application.put_env(:d20, BoardGameGeek, api_key: "")

      assert BoardGameGeek.api_key() == {:ok, ""}
    end
  end

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
