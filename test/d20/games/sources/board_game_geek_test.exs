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

  describe "fetch_game/1" do
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

      assert {:ok, %{name: "Example Trade Game"}} = BoardGameGeek.fetch_game(999_999)
    end

    test "returns a configuration error without an HTTP request when the API key is unavailable" do
      Application.delete_env(:d20, BoardGameGeek)
      assert BoardGameGeek.fetch_game(999_999) == {:error, :api_key_not_configured}

      Application.put_env(:d20, BoardGameGeek, api_key: nil)
      assert BoardGameGeek.fetch_game(999_999) == {:error, :api_key_not_configured}

      Application.put_env(:d20, BoardGameGeek, api_key: "")
      assert BoardGameGeek.fetch_game(999_999) == {:error, :api_key_not_configured}
    end

    test "returns http errors without parsing the response body" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 401, "Unauthorized") end)

      assert BoardGameGeek.fetch_game(999_999) == {:error, {:http_error, 401}}
    end

    test "returns transport errors" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.expect(__MODULE__, &Req.Test.transport_error(&1, :timeout))

      assert BoardGameGeek.fetch_game(999_999) == {:error, %Req.TransportError{reason: :timeout}}
    end

    test "returns not found when BGG returns no items" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "<items />") end)

      assert BoardGameGeek.fetch_game(999_999) == {:error, :game_not_found}
    end

    test "returns parse errors for invalid XML" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "not xml") end)

      assert {:error, _reason} = BoardGameGeek.fetch_game(999_999)
    end
  end

  test "fetch_game sends string values verbatim and trusts one parsed returned identity" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    for id <- ["001", "provider-alias", "", "-1", "+1", " 1 ", "1,2", "1&stats=0?x=2"] do
      Req.Test.expect(__MODULE__, fn conn ->
        assert conn.request_path == "/xmlapi2/thing"
        assert conn.params == %{"id" => id, "type" => "boardgame", "stats" => "1"}
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-token"]
        Req.Test.text(conn, details_xml([42]))
      end)

      assert {:ok, %{bgg_id: 42}} = BoardGameGeek.fetch_game(id)
    end
  end

  test "fetch_game string requests require exactly one valid parsed game" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    for xml <- [
          "<items />",
          details_xml([1, 2]),
          details_xml([1, 1]),
          ~s(<items><item id="0"/><item id="bad"/><item id="3junk"/></items>)
        ] do
      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, xml) end)
      assert {:error, :game_not_found} = BoardGameGeek.fetch_game("raw-id")
    end
  end

  test "fetch_game string requests preserve configuration, HTTP, transport, and parser errors" do
    Application.delete_env(:d20, BoardGameGeek)
    assert {:error, :api_key_not_configured} = BoardGameGeek.fetch_game("raw-id")
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)
    assert {:error, {:http_error, 503}} = BoardGameGeek.fetch_game("raw-id")

    Req.Test.expect(__MODULE__, &Req.Test.transport_error(&1, :timeout))
    assert {:error, %Req.TransportError{reason: :timeout}} = BoardGameGeek.fetch_game("raw-id")

    Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "not xml") end)
    assert {:error, _reason} = BoardGameGeek.fetch_game("raw-id")
  end

  test "fetch_game serializes scalar values and accepts the returned identity" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    for id <- [0, -1, nil, 1.5, :provider_id] do
      Req.Test.expect(__MODULE__, fn conn ->
        assert conn.params["id"] == to_string(id)
        Req.Test.text(conn, details_xml([42]))
      end)

      assert {:ok, %{bgg_id: 42}} = BoardGameGeek.fetch_game(id)
    end
  end

  test "fetch_game integer requests reject ambiguous provider results" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    for ids <- [[1, 2], [1, 1]] do
      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, details_xml(ids)) end)
      assert {:error, :game_not_found} = BoardGameGeek.fetch_game(1)
    end
  end

  test "fetch_games retains its list result for a scalar identity" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, details_xml([1])) end)
    assert {:ok, [%{bgg_id: 1}]} = BoardGameGeek.fetch_games(1)
    Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "<items/>") end)
    assert BoardGameGeek.fetch_games(1) == {:ok, []}
  end

  describe "fetch_games/1" do
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

      assert {:ok, games} = BoardGameGeek.fetch_games([350_736, 373_106])

      assert Enum.map(games, &{&1.bgg_id, &1.name}) == [
               {350_736, "Voyages"},
               {373_106, "Sky Team"}
             ]
    end

    test "does not request metadata for an empty catalog" do
      Application.delete_env(:d20, BoardGameGeek)
      assert BoardGameGeek.fetch_games([]) == {:ok, []}
    end
  end

  test "fetch_games serializes mixed values and only deduplicates exact request values" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.params["id"] == "1,1,0,-1,1.5,,raw-id"
      Req.Test.text(conn, details_xml([42, 99]))
    end)

    assert {:ok, games} = BoardGameGeek.fetch_games([1, "1", 0, -1, 1.5, nil, "raw-id", 1, "1"])
    assert Enum.map(games, & &1.bgg_id) == [42, 99]
  end

  test "fetch_games accepts raw scalar values including nil" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    for id <- ["001", "raw-id", 0, -1, 1.5, nil] do
      Req.Test.expect(__MODULE__, fn conn ->
        assert conn.params["id"] == to_string(id)
        Req.Test.text(conn, "<items />")
      end)

      assert {:ok, []} = BoardGameGeek.fetch_games(id)
    end
  end

  test "deduplicates request values and preserves valid provider items in response order" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.params["id"] == "2,1,3"

      Req.Test.text(
        conn,
        "<items><item id='1'/><item id='99'/><item/><item id='bad'/><item id='3junk'/><item id='0'/><item id='2'/><item id='2'/></items>"
      )
    end)

    assert {:ok, games} = BoardGameGeek.fetch_games([2, 1, 2, 3])
    assert Enum.map(games, & &1.bgg_id) == [1, 99, 2, 2]
  end

  test "runs at most two twenty-ID batches and preserves batch and provider response order" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    owner = self()

    Req.Test.stub(__MODULE__, fn conn ->
      ids = conn.params["id"] |> String.split(",") |> Enum.map(&String.to_integer/1)
      send(owner, {:batch, self(), ids})

      receive do
        :respond -> Req.Test.text(conn, details_xml(Enum.reverse(ids)))
      end
    end)

    task = Task.async(fn -> BoardGameGeek.fetch_games(Enum.to_list(1..45)) end)
    assert_receive {:batch, first, first_ids}, 1_000
    assert_receive {:batch, second, second_ids}, 1_000
    assert Enum.sort([length(first_ids), length(second_ids)]) == [20, 20]
    refute_received {:batch, _, _}
    send(second, :respond)
    send(first, :respond)
    assert_receive {:batch, third, third_ids}, 1_000
    assert third_ids == Enum.to_list(41..45)
    send(third, :respond)

    assert {:ok, games} = Task.await(task)

    assert Enum.map(games, & &1.bgg_id) ==
             Enum.to_list(20..1//-1) ++ Enum.to_list(40..21//-1) ++ Enum.to_list(45..41//-1)
  end

  test "a failed batch returns an error and terminates pending detail work" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    owner = self()

    Req.Test.stub(__MODULE__, fn conn ->
      send(owner, {:pending, self(), conn.params["id"]})

      receive do
        :fail -> Plug.Conn.send_resp(conn, 503, "Unavailable")
      end
    end)

    task = Task.async(fn -> BoardGameGeek.fetch_games(Enum.to_list(1..32)) end)
    assert_receive {:pending, first, first_ids}, 1_000
    assert_receive {:pending, second, second_ids}, 1_000
    first_monitor = Process.monitor(first)
    second_monitor = Process.monitor(second)

    {failed, _ids} =
      Enum.find([{first, first_ids}, {second, second_ids}], fn {_pid, ids} ->
        String.starts_with?(ids, "1,")
      end)

    send(failed, :fail)
    assert Task.await(task) == {:error, {:http_error, 503}}
    assert_receive {:DOWN, ^first_monitor, :process, ^first, _reason}
    assert_receive {:DOWN, ^second_monitor, :process, ^second, _reason}
  end

  @tag timeout: 20_000
  test "terminates timed-out detail work and returns an error without exiting the caller" do
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    owner = self()

    Req.Test.expect(__MODULE__, fn _conn ->
      send(owner, {:waiting, self()})

      receive do
        :never -> raise "unexpected message"
      end
    end)

    task = Task.async(fn -> BoardGameGeek.fetch_games(1) end)
    assert_receive {:waiting, pending}, 1_000
    monitor = Process.monitor(pending)
    assert Task.await(task, 17_000) == {:error, :timeout}
    assert_receive {:DOWN, ^monitor, :process, ^pending, _reason}
  end

  describe "fetch_hot_games/1" do
    test "selects only unique positive Hot identities and preserves missing detail membership" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
      owner = self()

      Req.Test.expect(__MODULE__, fn conn ->
        assert conn.request_path == "/xmlapi2/hot"
        assert conn.params == %{"type" => "boardgame"}
        assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-token"]
        assert Plug.Conn.get_req_header(conn, "accept") == ["application/xml"]

        Req.Test.text(
          conn,
          "<items><item id='2'/><item id='1'/><item id='2'/><item id='0'/><item id='-1'/><item id='bad'/><item/></items>"
        )
      end)

      Req.Test.expect(__MODULE__, fn conn ->
        ids = conn.params["id"] |> String.split(",") |> Enum.map(&String.to_integer/1)
        send(owner, {:selected, ids})

        Req.Test.text(
          conn,
          "<items><item id='2'><name type='primary' value='Example'/></item></items>"
        )
      end)

      assert {:ok, games} = BoardGameGeek.fetch_hot_games(limit: 100)
      assert_receive {:selected, selected}
      assert Enum.sort(selected) == [1, 2]
      assert Enum.map(games, & &1.bgg_id) == selected
      assert %{bgg_id: 1} in games
      assert Enum.find(games, &(&1.bgg_id == 2)).name == "Example"
    end

    test "uses default and normalized limits without padding or unsupported remote params" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

      Req.Test.stub(__MODULE__, fn conn ->
        case conn.request_path do
          "/xmlapi2/hot" ->
            assert conn.params == %{"type" => "boardgame"}
            Req.Test.text(conn, details_xml(Enum.to_list(1..105)))

          "/xmlapi2/thing" ->
            ids = conn.params["id"] |> String.split(",") |> Enum.map(&String.to_integer/1)
            assert Enum.count(ids) <= 20
            Req.Test.text(conn, details_xml(ids))
        end
      end)

      for {options, count} <- [
            {[], 32},
            {[limit: nil], 32},
            {[limit: -1], 32},
            {[limit: 0], 32},
            {[limit: "5"], 32},
            {[limit: 3, where: :ignored], 3},
            {[limit: 101], 100}
          ] do
        assert {:ok, games} = BoardGameGeek.fetch_hot_games(options)
        ids = Enum.map(games, & &1.bgg_id)
        assert length(ids) == count
        assert length(Enum.uniq(ids)) == count
        assert Enum.all?(ids, &(&1 in 1..105))
      end
    end

    test "requires credentials when a zero limit uses the default" do
      Application.delete_env(:d20, BoardGameGeek)
      assert BoardGameGeek.fetch_hot_games(limit: 0) == {:error, :api_key_not_configured}
    end

    test "empty Hot membership avoids detail requests" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "<items/>") end)
      assert BoardGameGeek.fetch_hot_games() == {:ok, []}
    end

    test "rejects the wrong root and malformed XML" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "<error/>") end)
      assert BoardGameGeek.fetch_hot_games() == {:error, :invalid_hot_response}
      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, "not xml") end)
      assert {:error, _reason} = BoardGameGeek.fetch_hot_games()
    end

    test "returns Hot configuration and HTTP failures" do
      Application.delete_env(:d20, BoardGameGeek)
      assert BoardGameGeek.fetch_hot_games() == {:error, :api_key_not_configured}
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
      Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)
      assert BoardGameGeek.fetch_hot_games() == {:error, {:http_error, 503}}
    end

    test "propagates errors when selected game details fail" do
      Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
      Req.Test.expect(__MODULE__, fn conn -> Req.Test.text(conn, details_xml([1, 2])) end)
      Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)

      assert BoardGameGeek.fetch_hot_games() == {:error, {:http_error, 503}}
    end
  end

  defp details_xml(ids) do
    "<items>" <> Enum.map_join(ids, &"<item id='#{&1}'/>") <> "</items>"
  end
end
