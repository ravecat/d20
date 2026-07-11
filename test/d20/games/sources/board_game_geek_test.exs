defmodule D20.Games.Sources.BoardGameGeekTest do
  use ExUnit.Case, async: false

  alias D20.Games.Sources.BoardGameGeek
  alias D20.Games.Sources.BoardGameGeek.Parser

  @fixture Path.expand("../../../support/fixtures/games/board_game_geek_game.xml", __DIR__)

  setup context do
    Req.Test.set_req_test_from_context(context)
    Req.Test.verify_on_exit!()

    original_config = Application.get_env(:d20, BoardGameGeek, :not_configured)
    original_req_options = Req.default_options()

    Req.default_options(plug: {Req.Test, __MODULE__})

    on_exit(fn ->
      Req.default_options(original_req_options)

      case original_config do
        :not_configured -> Application.delete_env(:d20, BoardGameGeek)
        config -> Application.put_env(:d20, BoardGameGeek, config)
      end
    end)
  end

  test "parses core game details into normalized game attrs" do
    assert {:ok, [attrs]} = @fixture |> File.read!() |> Parser.parse_game_details()

    assert %{
             bgg_id: 999_999,
             name: "Example Trade Game",
             alternate_names: ["Example Settlers"],
             categories: ["Negotiation", "Economic"],
             mechanics: ["Trading", "Dice Rolling"],
             description: "Trade, build, and settle.",
             thumbnail_url: "https://example.invalid/thumb.jpg",
             image_url: "https://example.invalid/image.jpg",
             year_published: 1995,
             min_players: 3,
             max_players: 4,
             playing_time: 120,
             min_play_time: 60,
             max_play_time: 120,
             min_age: 10,
             complexity: 2.14,
             rating: 7.42
           } = attrs

    refute Map.has_key?(attrs, :ratings)
    refute Map.has_key?(attrs, :links)
    refute Map.has_key?(attrs, :versions)
    refute Map.has_key?(attrs, :slug)
  end

  test "decodes BGG escaped HTML entities in descriptions" do
    xml = """
    <items>
      <item type="boardgame" id="999999">
        <description>Roll 1&amp;ndash;3 dice &amp;mdash; then score &amp;amp; settle &amp;quot;fast&amp;quot;.&amp;#10;Next line.</description>
      </item>
    </items>
    """

    assert {:ok, [%{description: description}]} = Parser.parse_game_details(xml)

    assert description ==
             "Roll 1#{<<0x2013::utf8>>}3 dice #{<<0x2014::utf8>>} then score & settle \"fast\".\nNext line."
  end

  test "returns an empty list when the response has no items" do
    assert Parser.parse_game_details("<items />") == {:ok, []}
  end

  describe "fetch_game_details/1" do
    test "fetches game details by BGG id with bearer authorization" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
      fixture = File.read!(@fixture)

      Req.Test.expect(__MODULE__, fn conn ->
        assert conn.method == "GET"
        assert conn.host == "boardgamegeek.com"
        assert conn.request_path == "/xmlapi2/thing"
        assert conn.params == %{"id" => "999999", "type" => "boardgame", "stats" => "1"}
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-token"]
        assert Plug.Conn.get_req_header(conn, "accept") == ["application/xml"]

        Req.Test.text(conn, fixture)
      end)

      assert {:ok, %{name: "Example Trade Game"}} = BoardGameGeek.fetch_game_details(999_999)
    end

    test "raises when source config is missing" do
      Application.delete_env(:d20, BoardGameGeek)

      assert_raise ArgumentError, fn -> BoardGameGeek.fetch_game_details(999_999) end
    end

    test "returns http errors without parsing the response body" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 401, "Unauthorized") end)

      assert BoardGameGeek.fetch_game_details(999_999) == {:error, {:http_error, 401}}
    end

    test "returns not found when BGG returns no items" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "<items />") end)

      assert BoardGameGeek.fetch_game_details(999_999) == {:error, :game_not_found}
    end

    test "returns parse errors for invalid XML" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "not xml") end)

      assert {:error, _reason} = BoardGameGeek.fetch_game_details(999_999)
    end
  end

  describe "fetch_games_details/1" do
    test "fetches multiple games in one request" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.expect(__MODULE__, fn conn ->
        assert conn.params == %{"id" => "350736,373106", "type" => "boardgame", "stats" => "1"}

        Req.Test.text(conn, """
        <items>
          <item type="boardgame" id="350736">
            <name type="primary" value="Voyages" />
          </item>
          <item type="boardgame" id="373106">
            <name type="primary" value="Sky Team" />
          </item>
        </items>
        """)
      end)

      assert {:ok, games} = BoardGameGeek.fetch_games_details([350_736, 373_106])

      assert Enum.map(games, &{&1.bgg_id, &1.name}) == [
               {350_736, "Voyages"},
               {373_106, "Sky Team"}
             ]
    end

    test "does not request metadata for an empty catalog" do
      assert BoardGameGeek.fetch_games_details([]) == {:ok, []}
    end
  end
end
