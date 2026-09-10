defmodule D20.GamesTest do
  use D20.DataCase, async: false

  import ExUnit.CaptureLog

  alias D20.Games
  alias D20.Games.Game
  alias D20.Games.Metadata
  alias D20.Games.Sources.BoardGameGeek

  @qwinto_xml """
  <?xml version="1.0" encoding="utf-8"?>
  <items>
    <item type="boardgame" id="183006">
      <thumbnail>https://example.invalid/thumb.jpg</thumbnail>
      <image>https://example.invalid/image.jpg</image>
      <name type="primary" value="Qwinto" />
      <description>Resolved from BGG.</description>
      <yearpublished value="2015" />
      <minplayers value="2" />
      <maxplayers value="6" />
      <playingtime value="15" />
      <minage value="8" />
      <statistics page="1">
        <ratings>
          <average value="7.42" />
          <averageweight value="1.47" />
        </ratings>
      </statistics>
      <link type="boardgamecategory" id="1017" value="Dice" />
      <link type="boardgamecategory" id="1098" value="Number" />
      <link type="boardgamemechanic" id="2072" value="Dice Rolling" />
      <link type="boardgamemechanic" id="2055" value="Paper-and-Pencil" />
    </item>
  </items>
  """

  @ordered_bgg_ids [
    425_873,
    183_006,
    360_471,
    342_200,
    322_703,
    169_654,
    420_087,
    352_418,
    50,
    361_850,
    353_545,
    245_654,
    131_260,
    302_280,
    373_106,
    352_454,
    283_864,
    350_736,
    388_329
  ]

  @bgg_names %{
    "50" => "Lost Cities",
    "131260" => "Qwixx",
    "169654" => "Deep Sea Adventure",
    "183006" => "Qwinto",
    "245654" => "Railroad Ink: Deep Blue Edition",
    "283864" => "Trails of Tucana",
    "302280" => "Shifting Stones",
    "322703" => "Death Valley",
    "342200" => "Confusing Lands",
    "350736" => "Voyages",
    "352418" => "Fliptown",
    "352454" => "Trailblazers",
    "353545" => "Next Station: London",
    "360471" => "Aquamarine",
    "361850" => "Nimalia",
    "373106" => "Sky Team",
    "388329" => "Waypoints",
    "420087" => "Flip 7",
    "425873" => "Koala Rescue Club"
  }

  setup context do
    Req.Test.set_req_test_from_context(context)
    Req.Test.verify_on_exit!()

    original_config = Application.get_env(:d20, BoardGameGeek, :not_configured)

    original_stages = Application.fetch_env!(:d20, :visible_game_stages)

    original_req_options = Req.default_options()

    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    Req.default_options(plug: {Req.Test, __MODULE__})

    on_exit(fn ->
      Req.default_options(original_req_options)

      Application.put_env(:d20, :visible_game_stages, original_stages)

      case original_config do
        :not_configured -> Application.delete_env(:d20, BoardGameGeek)
        config -> Application.put_env(:d20, BoardGameGeek, config)
      end
    end)
  end

  test "fetches persisted game metadata by local id" do
    stub_bgg_game(@qwinto_xml)
    qwinto_id = game_id(183_006)

    assert {:ok, {%Game{id: ^qwinto_id, slug: "qwinto", bgg_id: 183_006}, %Metadata{} = metadata}} =
             Games.fetch_by_id(qwinto_id)

    assert metadata.name == "Qwinto"
    assert metadata.categories == ["Dice", "Number"]
    assert metadata.mechanics == ["Dice Rolling", "Paper-and-Pencil"]
    assert metadata.description == "Resolved from BGG."
    assert metadata.thumbnail_url == "https://example.invalid/thumb.jpg"
    assert metadata.min_age == 8
    assert metadata.complexity == 1.47
    assert metadata.rating == 7.42
    refute Map.has_key?(metadata, :slug)
  end

  test "fetches persisted game metadata by slug" do
    stub_bgg_game(@qwinto_xml)
    qwinto_id = game_id(183_006)

    assert {:ok,
            %{
              entry: %Game{id: ^qwinto_id, slug: "qwinto"},
              bgg_id: 183_006,
              slug: "qwinto",
              metadata: %Metadata{} = metadata
            }} = Games.fetch_by_slug("qwinto")

    assert metadata.name == "Qwinto"
    stub_bgg_game("<items />", "missing")
    assert {:error, :game_not_found} = Games.fetch_by_slug("missing")
  end

  test "numeric fallback normalizes the route without associating another local slug" do
    for slug <- ["183006", "00183006", "provider-alias"] do
      stub_bgg_game(@qwinto_xml, slug)

      assert {:ok,
              %{entry: nil, bgg_id: 183_006, slug: "183006", metadata: %Metadata{name: "Qwinto"}}} =
               Games.fetch_by_slug(slug)
    end

    assert {:ok, %Game{slug: "qwinto"}} = Games.get_by_slug("qwinto")
    assert {:error, :game_not_found} = Games.get_by_slug("183006")
  end

  test "exact numeric local slug precedes provider ID interpretation" do
    entry = Repo.insert!(%Game{slug: "900001", bgg_id: 900_002})

    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.params["id"] == "900002"
      Req.Test.text(conn, ~s(<items><item type="boardgame" id="900002" /></items>))
    end)

    assert {:ok, %{entry: ^entry, bgg_id: 900_002, slug: "900001", metadata: %Metadata{}}} =
             Games.fetch_by_slug("900001")
  end

  test "unmatched route values are sent unchanged and rely on provider absence" do
    for slug <- [
          "",
          "missing",
          "0",
          "000",
          "-1",
          "+1",
          "1.5",
          "1e3",
          "183006suffix",
          " 183006",
          "183006 ",
          "183006\n",
          "١٨٣٠٠٦"
        ] do
      stub_bgg_game("<items />", slug)
      assert {:error, :game_not_found} = Games.fetch_by_slug(slug)
    end
  end

  test "provider details work without local records and accept sparse metadata without persistence" do
    Repo.delete_all(Game)
    stub_bgg_game(~s(<items><item type="boardgame" id="183006" /></items>))

    assert {:ok, %{entry: nil, bgg_id: 183_006, slug: "183006", metadata: metadata}} =
             Games.fetch_by_slug("183006")

    assert metadata == Metadata.empty()
    assert Repo.aggregate(Game, :count) == 0
  end

  test "provider detail failures propagate instead of creating empty metadata" do
    stub_bgg_game("<items />")
    assert {:error, :game_not_found} = Games.fetch_by_slug("183006")

    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)
    assert {:error, {:http_error, 503}} = Games.fetch_by_slug("183006")

    stub_bgg_game("<items>")
    assert {:error, _reason} = Games.fetch_by_slug("183006")

    Application.delete_env(:d20, BoardGameGeek)
    assert {:error, :api_key_not_configured} = Games.fetch_by_slug("183006")
  end

  test "resolves persisted games by slug without metadata" do
    assert {:ok, %Game{slug: "qwinto"}} = Games.get_by_slug("qwinto")
    assert {:error, :game_not_found} = Games.get_by_slug("missing")
  end

  test "list normalizes limits before loading records and enriching metadata" do
    for bgg_id <- 900_001..900_110 do
      Repo.insert!(%Game{slug: "game-#{bgg_id}", bgg_id: bgg_id})
    end

    owner = self()

    Req.Test.stub(__MODULE__, fn conn ->
      ids = String.split(conn.params["id"], ",")
      send(owner, {:metadata_ids, ids})
      items = Enum.map_join(ids, &game_item_xml(&1, "Game #{&1}"))
      Req.Test.text(conn, "<items>#{items}</items>")
    end)

    for result <-
          [Games.list(), Games.list([])] ++
            Enum.map([nil, :infinity, 1.5, "32"], &Games.list(limit: &1)) do
      assert {:ok, games} = result
      assert Enum.count_until(games, 33) == 32
      assert Enum.uniq_by(games, & &1.id) == games
      assert_metadata_batches(games)
    end

    for limit <- [100, 101, 10_000] do
      assert {:ok, games} = Games.list(limit: limit)
      assert Enum.count_until(games, 101) == 100
      assert_metadata_batches(games)
    end
  end

  test "list_playable applies availability before caller ordering and limit" do
    stub_registered_bgg_games()

    for {stages, expected} <- [
          {[:released, :in_development], [425_873, 183_006, 352_418, 353_545]},
          {[:released], [425_873, 183_006]}
        ] do
      Application.put_env(:d20, :visible_game_stages, stages)
      assert {:ok, games} = Games.list_playable(limit: 8, order_by: [desc: :stage, asc: :id])
      assert Enum.map(games, & &1.id) == expected
    end

    assert {:ok, _game} = Games.update(game_fixture(425_873), %{enabled: false})
    assert {:ok, [game]} = Games.list_playable(limit: 1)
    assert game.id == 183_006
  end

  test "list_by_provider keeps external membership and merges only visible local matches" do
    Application.put_env(:d20, :visible_game_stages, [:released])
    assert {:ok, _game} = Games.update(game_fixture(183_006), %{enabled: false})
    ids = [900_001, 183_006, 353_545]
    stub_hot_games(ids)

    assert {:ok, games} = Games.list_by_provider(where: [bgg_id: -1], order_by: [:id])
    assert MapSet.new(games, & &1.id) == MapSet.new(ids)

    assert %{slug: "900001", stage: nil, metadata: %Metadata{name: "Game 900001"}} =
             Enum.find(games, &(&1.id == 900_001))

    assert %{slug: "qwinto", stage: :released} = Enum.find(games, &(&1.id == 183_006))
    assert %{slug: "353545", stage: nil} = Enum.find(games, &(&1.id == 353_545))
    refute Repo.get_by(Game, bgg_id: 900_001)
  end

  test "list_by_provider associates visible planned games without an engine" do
    Application.put_env(:d20, :visible_game_stages, [:released, :in_development])
    assert %Game{engine: nil} = game_fixture(350_736)
    stub_hot_games([350_736])

    assert {:ok, [%{id: 350_736, slug: "voyages", stage: :in_development}]} =
             Games.list_by_provider()
  end

  test "list_by_provider discovers games without local records or visible stages" do
    Repo.delete_all(Game)
    Application.put_env(:d20, :visible_game_stages, [])
    stub_hot_games([900_001, 900_002])

    for result <- [Games.list_by_provider(), Games.list_by_provider([])] do
      assert {:ok, games} = result
      assert MapSet.new(games, & &1.id) == MapSet.new([900_001, 900_002])
      assert Enum.all?(games, &(&1.slug == Integer.to_string(&1.id) and is_nil(&1.stage)))
    end

    assert Repo.aggregate(Game, :count) == 0
  end

  test "list_by_provider normalizes limits before selecting provider games" do
    stub_hot_games(Enum.to_list(900_001..900_110))

    for {options, count} <- [
          {[], 32},
          {[limit: nil], 32},
          {[limit: -1], 32},
          {[limit: 0], 32},
          {[limit: "8"], 32},
          {[limit: 2], 2},
          {[limit: 100], 100},
          {[limit: 101], 100}
        ] do
      assert {:ok, games} = Games.list_by_provider(options)
      assert length(games) == count
      assert Enum.uniq_by(games, & &1.id) == games
      assert Enum.all?(games, &(&1.metadata.name == "Game #{&1.id}"))
    end
  end

  test "list_by_provider requires credentials when a zero limit uses the default" do
    Application.delete_env(:d20, BoardGameGeek)
    assert {:error, :api_key_not_configured} = Games.list_by_provider(limit: 0)
  end

  test "list_by_provider propagates discovery errors" do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.request_path == "/xmlapi2/hot"
      Plug.Conn.send_resp(conn, 503, "Unavailable")
    end)

    assert {:error, {:http_error, 503}} = Games.list_by_provider()
  end

  test "list_by_provider propagates errors fetching selected game details" do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.request_path == "/xmlapi2/hot"
      Req.Test.text(conn, ~s(<items><item id="183006" /></items>))
    end)

    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.request_path == "/xmlapi2/thing"
      Plug.Conn.send_resp(conn, 503, "Unavailable")
    end)

    assert {:error, {:http_error, 503}} = Games.list_by_provider()
  end

  test "list_by_provider preserves selected identities and local fields when details are omitted" do
    stub_hot_games([183_006, 900_001], [])
    assert {:ok, games} = Games.list_by_provider()
    assert MapSet.new(games, & &1.id) == MapSet.new([183_006, 900_001])
    assert Enum.all?(games, &(&1.metadata == Metadata.empty()))
    assert %{slug: "qwinto", stage: :released} = Enum.find(games, &(&1.id == 183_006))
  end

  test "playable defaults retain eligible games" do
    stub_registered_bgg_games()
    Application.put_env(:d20, :visible_game_stages, [:released, :in_development])

    for result <- [Games.list_playable(), Games.list_playable([])] do
      assert {:ok, games} = result

      assert MapSet.new(games, & &1.id) == MapSet.new([425_873, 183_006, 352_418, 353_545])
    end
  end

  test "scoped options intersect keyword and dynamic filters before caller order and limit" do
    stub_registered_bgg_games()
    Application.put_env(:d20, :visible_game_stages, [:released, :in_development])
    condition = dynamic([game], game.stage == :in_development)

    for {listing, expected_bgg_id} <- [{&Games.list_playable/1, 352_418}],
        where <- [[stage: :in_development], condition] do
      assert {:ok, [game]} = listing.(where: where, order_by: [asc: :bgg_id], limit: 1)
      assert game.id == expected_bgg_id
    end

    assert {:ok, [game]} =
             Games.list_playable(where: condition, order_by: [desc: :bgg_id], limit: 1)

    assert game.id == 353_545
  end

  test "caller filters cannot bypass mandatory scoped predicates" do
    Application.put_env(:d20, :visible_game_stages, [:released])
    assert {:ok, _game} = Games.update(game_fixture(183_006), %{enabled: false})

    assert {:ok, []} = Games.list_playable(where: [enabled: false])

    assert {:ok, []} = Games.list_playable(where: [stage: :in_development])
    assert {:ok, []} = Games.list_playable(where: dynamic([game], game.stage == :in_development))
    assert {:ok, []} = Games.list_playable(where: [bgg_id: -1])
    assert {:ok, []} = Games.list_playable(limit: 0)
    assert {:ok, []} = Games.list_playable(limit: -1)

    stub_registered_bgg_games()
    permissive = dynamic([game], game.enabled == false or game.bgg_id > 0)
    assert {:ok, playable} = Games.list_playable(where: permissive)
    assert Enum.map(playable, & &1.id) == [425_873]

    Application.put_env(:d20, :visible_game_stages, [:released, :in_development])
    assert {:ok, playable} = Games.list_playable(where: permissive)
    assert MapSet.new(playable, & &1.id) == MapSet.new([425_873, 352_418, 353_545])
  end

  test "scoped limits use shared defaults and normalization before metadata enrichment" do
    for bgg_id <- 900_001..900_110 do
      Repo.insert!(%Game{
        slug: "game-#{bgg_id}",
        bgg_id: bgg_id,
        stage: :released,
        engine: D20.Qwinto.Game
      })
    end

    owner = self()

    Req.Test.stub(__MODULE__, fn conn ->
      ids = String.split(conn.params["id"], ",")
      send(owner, {:metadata_ids, ids})
      items = Enum.map_join(ids, &game_item_xml(&1, "Game #{&1}"))
      Req.Test.text(conn, "<items>#{items}</items>")
    end)

    for {options, expected_count} <- [
          {[], 32},
          {[limit: nil], 32},
          {[limit: "8"], 32},
          {[limit: 100], 100},
          {[limit: 101], 100}
        ] do
      assert {:ok, games} = Games.list_playable(options)
      assert length(games) == expected_count
      assert_metadata_batches(games)
    end
  end

  test "list accepts native Ecto dynamic ordering" do
    stub_registered_bgg_games()

    assert {:ok, games} =
             Games.list(
               order_by: [
                 desc: dynamic([game], game.stage == :released),
                 desc: dynamic([game], game.stage == :in_development),
                 asc: :id
               ]
             )

    assert Enum.count_until(games, 20) == 19

    assert Enum.map(games, & &1.id) == @ordered_bgg_ids

    qwinto_bgg_id = 183_006
    koala_bgg_id = 425_873
    next_station_bgg_id = 353_545
    voyages_bgg_id = 350_736

    assert %{stage: :released} = Enum.find(games, &(&1.id == qwinto_bgg_id))
    assert %{stage: :released} = Enum.find(games, &(&1.id == koala_bgg_id))
    assert %{stage: :in_development} = Enum.find(games, &(&1.id == next_station_bgg_id))
    assert %{stage: :in_development} = Enum.find(games, &(&1.id == voyages_bgg_id))
    assert %Metadata{name: "Qwinto"} = Enum.find(games, &(&1.id == qwinto_bgg_id)).metadata
  end

  test "list without options includes playable, engine-less, and disabled games" do
    stub_registered_bgg_games()
    assert {:ok, _game} = Games.update(game_fixture(183_006), %{enabled: false})

    assert {:ok, games} = Games.list([])

    assert Enum.sort(Enum.map(games, & &1.id)) == Enum.sort(@ordered_bgg_ids)

    assert %{stage: :released, metadata: %Metadata{name: "Qwinto"}} =
             Enum.find(games, &(&1.id == 183_006))

    assert %{stage: :in_development} = Enum.find(games, &(&1.id == 353_545))
    assert %{stage: :in_development} = Enum.find(games, &(&1.id == 350_736))
  end

  test "list composes native keyword conditions, ordering, and limit" do
    stub_registered_bgg_games()

    assert {:ok, games} =
             Games.list(
               where: [stage: :in_development, enabled: true],
               order_by: [desc: :bgg_id],
               limit: 2
             )

    assert Enum.map(games, & &1.id) == [420_087, 388_329]
  end

  test "list composes dynamic conditions over schema fields" do
    stub_registered_bgg_games()
    stages = [:released, :in_development]
    engines = Game.engines()

    condition =
      dynamic([game], game.enabled == true and game.stage in ^stages and game.engine in ^engines)

    assert {:ok, playable} =
             Games.list(where: condition, limit: 8, order_by: [desc: :stage, asc: :id])

    assert Enum.map(playable, & &1.id) == [425_873, 183_006, 352_418, 353_545]

    assert {:ok, capped} =
             Games.list(where: condition, limit: 2, order_by: [desc: :stage, asc: :id])

    assert Enum.map(capped, & &1.id) == [425_873, 183_006]

    assert {:ok, _game} = Games.update(game_fixture(183_006), %{enabled: false})

    assert {:ok, _game} =
             Games.update(game_fixture(353_545), %{stage: :in_development, engine: nil})

    assert {:ok, remaining} = Games.list(where: condition)
    assert MapSet.new(remaining, & &1.id) == MapSet.new([425_873, 352_418])
  end

  test "schema-field conditions do not imply launch policy" do
    stub_registered_bgg_games()
    Application.put_env(:d20, :visible_game_stages, [:released])
    next_station_bgg_id = 353_545

    assert {:ok, [%{id: ^next_station_bgg_id}]} =
             Games.list(where: [stage: :in_development, engine: D20.NextStationLondon.Game])

    assert {:ok, _game} = Games.update(game_fixture(183_006), %{enabled: false})
    qwinto_bgg_id = 183_006

    assert {:ok, [%{id: ^qwinto_bgg_id}]} = Games.list(where: [enabled: false, stage: :released])
  end

  test "list accepts dynamic exclusions and sorts before limiting" do
    stub_registered_bgg_games()
    playable_bgg_ids = [425_873, 183_006, 352_418, 353_545]
    condition = dynamic([game], game.bgg_id not in ^playable_bgg_ids)

    assert {:ok, browse} = Games.list(where: condition, order_by: [asc: :id], limit: 5)

    expected_bgg_ids =
      @ordered_bgg_ids
      |> Enum.reject(&(&1 in [425_873, 183_006, 352_418, 353_545]))
      |> Enum.take(5)

    assert Enum.map(browse, & &1.id) == expected_bgg_ids
    refute Enum.any?(browse, &(&1.id in playable_bgg_ids))

    assert {:ok, unfiltered} = Games.list(order_by: :id)
    assert Enum.map(unfiltered, & &1.id) == Enum.sort_by(@ordered_bgg_ids, &game_id/1)
  end

  test "list returns empty selections without fetching metadata" do
    assert {:ok, []} = Games.list(limit: 0)
    assert {:ok, []} = Games.list(where: [enabled: true], limit: 0)
    assert {:ok, []} = Games.list(where: [bgg_id: -1])

    Repo.delete_all(Game)
    assert {:ok, []} = Games.list()
  end

  test "list ignores unsupported keys while applying supported options" do
    stub_registered_bgg_games()

    assert {:ok, [game]} =
             Games.list(
               filters: [enabled: false],
               offset: 100,
               filter: :playable,
               where: [bgg_id: 350_736],
               order_by: [asc: :id],
               limit: 1
             )

    assert game.id == 350_736
  end

  test "list preserves native Ecto query validation" do
    assert_raise ArgumentError, fn -> Games.list(order_by: [sideways: :id]) end
  end

  test "list clamps negative limits to zero without fetching metadata" do
    for limit <- [-1, -100] do
      assert {:ok, []} = Games.list(limit: limit)
    end
  end

  test "returns BGG identity and local fields in the four-field catalog map" do
    stub_registered_bgg_games()
    assert {:ok, games} = Games.list()

    entry = Enum.find(games, &(&1.id == 183_006))
    assert entry == %{id: 183_006, slug: "qwinto", stage: :released, metadata: entry.metadata}
    assert %Metadata{name: "Qwinto"} = entry.metadata
    refute Map.has_key?(entry.metadata, :bgg_id)
    assert Enum.count_until(Enum.uniq(Enum.map(games, & &1.slug)), 20) == 19
  end

  test "keeps catalog membership when metadata is partially omitted" do
    stub_registered_bgg_games(%{}, ["183006"])

    log =
      capture_log([format: "$message $metadata\n", metadata: [:scope, :reason]], fn ->
        assert {:ok, games} = Games.list(order_by: [asc: :id])

        assert Enum.map(games, & &1.id) == Enum.sort_by(@ordered_bgg_ids, &game_id/1)

        assert Enum.find(games, &(&1.id == 183_006)) == %{
                 id: 183_006,
                 slug: "qwinto",
                 stage: :released,
                 metadata: Metadata.empty()
               }

        assert Enum.find(games, &(&1.id == 425_873)).metadata.name == "Koala Rescue Club"
      end)

    assert [[_warning]] = Regex.scan(~r/Failed to enrich game metadata/, log)
    assert log =~ "game_not_found"
    refute log =~ "scope=catalog"
  end

  test "keeps catalog membership when the metadata batch fails" do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)

    log =
      capture_log([format: "$message $metadata\n", metadata: [:scope, :reason]], fn ->
        assert {:ok, games} = Games.list(order_by: [asc: :id])
        assert Enum.map(games, & &1.id) == Enum.sort_by(@ordered_bgg_ids, &game_id/1)
        assert Enum.all?(games, &(&1.metadata == Metadata.empty()))

        assert Enum.find(games, &(&1.id == 183_006)) == %{
                 id: 183_006,
                 slug: "qwinto",
                 stage: :released,
                 metadata: Metadata.empty()
               }
      end)

    assert [[_warning]] = Regex.scan(~r/Failed to enrich game metadata/, log)
    assert log =~ "scope=catalog"
    refute log =~ "game_not_found"
  end

  test "keeps catalog membership without metadata credentials" do
    Application.delete_env(:d20, BoardGameGeek)

    capture_log(fn ->
      assert {:ok, games} = Games.list(order_by: [asc: :id])
      assert length(games) == map_size(@bgg_names)
      assert Enum.all?(games, &is_nil(&1.metadata.name))
    end)
  end

  test "lists empty fallback metadata when the batch request fails" do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 401, "Unauthorized") end)

    log =
      capture_log(fn ->
        assert {:ok, games} = Games.list()
        assert length(games) == map_size(@bgg_names)
        assert Enum.find(games, &(&1.id == 183_006)).metadata.name == nil
        assert Enum.find(games, &(&1.id == 183_006)).slug == "qwinto"
      end)

    assert log =~ "Failed to enrich game metadata; using local fallback"
  end

  test "returns empty fallback metadata when BGG is unavailable" do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)

    log =
      capture_log(fn ->
        assert {:ok, {%Game{}, %Metadata{} = metadata}} = Games.fetch_by_id(game_id(183_006))
        assert metadata.name == nil
      end)

    assert log =~ "Failed to enrich game metadata; using local fallback"
  end

  test "local detail retains authoritative BGG identity during metadata failure" do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)

    capture_log(fn ->
      assert {:ok, %{bgg_id: 183_006, metadata: metadata}} = Games.fetch_by_slug("qwinto")
      assert metadata == Metadata.empty()
    end)
  end

  test "uses TypeID primary-key casting for local ids" do
    stub_bgg_game(@qwinto_xml)
    qwinto_id = game_id(183_006)
    missing_id = TypeID.new("game")

    assert {:ok, {%Game{id: ^qwinto_id}, %Metadata{}}} =
             Games.fetch_by_id(TypeID.to_string(qwinto_id))

    assert {:error, :game_not_found} = Games.fetch_by_id(missing_id)

    assert_raise Ecto.Query.CastError, fn -> Games.fetch_by_id("not-a-typeid") end
    assert_raise Ecto.Query.CastError, fn -> Games.get(TypeID.new("user")) end
  end

  test "slug lookup never treats a TypeID as a persisted slug" do
    assert {:error, :game_not_found} = Games.get_by_slug(TypeID.to_string(game_id(183_006)))
    assert {:error, :game_not_found} = Games.get_by_slug("not-a-typeid")
  end

  test "visibility follows configured stages independently of enabled state and engine" do
    released = %Game{stage: :released, enabled: true, engine: D20.Qwinto.Game}
    disabled = %{released | enabled: false}
    engine_less = %{released | engine: nil}
    in_development = %{released | stage: :in_development}
    Application.put_env(:d20, :visible_game_stages, [:released])

    for game <- [released, disabled, engine_less], do: assert(Games.visible?(game))
    refute Games.visible?(in_development)
    assert Games.session_launch_available?(released)
    refute Games.session_launch_available?(disabled)
    refute Games.session_launch_available?(engine_less)

    Application.put_env(:d20, :visible_game_stages, [:in_development])
    assert Games.visible?(in_development)
    for game <- [released, disabled, engine_less], do: refute(Games.visible?(game))

    Application.put_env(:d20, :visible_game_stages, [])
    refute Games.visible?(in_development)
  end

  test "allows released and in-development launch when both stages are configured" do
    Application.put_env(:d20, :visible_game_stages, [:released, :in_development])
    assert {:ok, released} = Games.get(game_id(183_006))
    assert {:ok, koala} = Games.get(game_id(425_873))
    assert {:ok, next_station} = Games.get(game_id(353_545))
    assert {:ok, engine_less} = Games.get(game_id(350_736))

    assert Games.session_launch_available?(released)
    assert Games.session_launch_available?(koala)
    assert Games.session_launch_available?(next_station)
    refute Games.session_launch_available?(engine_less)
  end

  test "an empty stage policy hides games and denies new launches without filtering generic listing" do
    Application.put_env(:d20, :visible_game_stages, [])
    assert {:ok, released} = Games.get(game_id(183_006))
    assert {:ok, next_station} = Games.get(game_id(353_545))

    refute Games.session_launch_available?(released)
    refute Games.session_launch_available?(next_station)
    assert {:ok, []} = Games.list_playable(limit: 8, order_by: [desc: :stage, asc: :id])

    stub_registered_bgg_games()
    assert {:ok, games} = Games.list(where: [stage: :released])
    assert MapSet.new(games, & &1.id) == MapSet.new([183_006, 425_873])
  end

  test "denies in-development launch when only released stages are configured" do
    Application.put_env(:d20, :visible_game_stages, [:released])
    assert {:ok, released} = Games.get(game_id(183_006))
    assert {:ok, next_station} = Games.get(game_id(353_545))
    assert {:ok, engine_less} = Games.get(game_id(350_736))

    assert Games.session_launch_available?(released)
    refute Games.session_launch_available?(next_station)
    refute Games.session_launch_available?(engine_less)
  end

  defp assert_metadata_batches(games) do
    ids =
      Enum.flat_map(1..div(length(games) + 19, 20), fn _batch ->
        assert_receive {:metadata_ids, ids}
        assert Enum.count_until(ids, 21) <= 20
        ids
      end)

    assert MapSet.new(ids) == MapSet.new(games, &Integer.to_string(&1.id))
    assert Enum.all?(games, &(&1.metadata.name == "Game #{&1.id}"))
  end

  defp stub_hot_games(ids, detail_ids \\ nil) do
    Req.Test.stub(__MODULE__, fn conn ->
      items =
        case conn.request_path do
          "/xmlapi2/hot" ->
            assert conn.params == %{"type" => "boardgame"}
            Enum.map_join(ids, &~s(<item id="#{&1}" rank="1"><name value="Game #{&1}" /></item>))

          "/xmlapi2/thing" ->
            conn.params["id"]
            |> String.split(",")
            |> Enum.filter(&(is_nil(detail_ids) or String.to_integer(&1) in detail_ids))
            |> Enum.map_join(&game_item_xml(&1, "Game #{&1}"))
        end

      Req.Test.text(conn, "<items>#{items}</items>")
    end)
  end

  defp stub_bgg_game(xml, id \\ "183006") do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.params == %{"id" => id, "type" => "boardgame", "stats" => "1"}
      Req.Test.text(conn, xml)
    end)
  end

  defp stub_registered_bgg_games(overrides \\ %{}, omitted_ids \\ []) do
    Req.Test.stub(__MODULE__, fn conn ->
      assert %{"id" => ids, "type" => "boardgame", "stats" => "1"} = conn.params

      requested_ids = String.split(ids, ",")

      # Metadata is batched per catalog query, so each request carries one
      # non-overlapping subset of the registered catalog.
      assert requested_ids != []
      assert MapSet.subset?(MapSet.new(requested_ids), MapSet.new(Map.keys(@bgg_names)))

      items =
        requested_ids
        |> Enum.reject(&(&1 in omitted_ids))
        |> Enum.map_join(fn id ->
          Map.get(overrides, id, game_item_xml(id, Map.fetch!(@bgg_names, id)))
        end)

      Req.Test.text(conn, "<items>#{items}</items>")
    end)
  end

  defp game_item_xml(id, name) do
    """
    <item type="boardgame" id="#{id}">
      <name type="primary" value="#{name}" />
    </item>
    """
  end
end
