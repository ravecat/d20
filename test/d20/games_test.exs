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

    original_launch_config =
      Application.get_env(:d20, :allow_launch_in_development, :not_configured)

    original_req_options = Req.default_options()

    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    Req.default_options(plug: {Req.Test, __MODULE__})

    on_exit(fn ->
      Req.default_options(original_req_options)

      case original_launch_config do
        :not_configured -> Application.delete_env(:d20, :allow_launch_in_development)
        config -> Application.put_env(:d20, :allow_launch_in_development, config)
      end

      case original_config do
        :not_configured -> Application.delete_env(:d20, BoardGameGeek)
        config -> Application.put_env(:d20, BoardGameGeek, config)
      end
    end)
  end

  test "fetches persisted game metadata by local id" do
    stub_bgg_game(@qwinto_xml)
    qwinto_id = game_id(183_006)

    assert {:ok, {%Game{id: ^qwinto_id, bgg_id: 183_006}, %Metadata{} = metadata}} =
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

  test "lists persisted games ordered by implementation stage and local id" do
    stub_registered_bgg_games()

    assert {:ok, games} = Games.list()

    assert length(games) == 19

    ordered_bgg_ids = [
      425_873,
      183_006,
      353_545,
      360_471,
      342_200,
      322_703,
      169_654,
      420_087,
      352_418,
      50,
      361_850,
      245_654,
      131_260,
      302_280,
      373_106,
      352_454,
      283_864,
      350_736,
      388_329
    ]

    assert Enum.map(games, & &1.id) == Enum.map(ordered_bgg_ids, &game_id/1)

    qwinto_id = game_id(183_006)
    koala_id = game_id(425_873)
    next_station_id = game_id(353_545)
    voyages_id = game_id(350_736)

    assert %{stage: :released} = Enum.find(games, &(&1.id == qwinto_id))
    assert %{stage: :released} = Enum.find(games, &(&1.id == koala_id))
    assert %{stage: :in_development} = Enum.find(games, &(&1.id == next_station_id))
    assert %{stage: :planned} = Enum.find(games, &(&1.id == voyages_id))
    assert %Metadata{name: "Qwinto"} = Enum.find(games, &(&1.id == qwinto_id)).metadata
  end

  test "omits public slugs from catalog entries" do
    stub_registered_bgg_games()
    assert {:ok, games} = Games.list()
    refute Map.has_key?(Enum.find(games, &(&1.id == game_id(183_006))), :slug)
  end

  test "lists empty fallback metadata when the batch request fails" do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 401, "Unauthorized") end)

    log =
      capture_log(fn ->
        assert {:ok, games} = Games.list()
        assert length(games) == map_size(@bgg_names)
        assert Enum.find(games, &(&1.id == game_id(183_006))).metadata.name == nil
        refute Map.has_key?(Enum.find(games, &(&1.id == game_id(183_006))), :slug)
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

  test "allows released and Next Station launch when in-development launch is enabled" do
    Application.put_env(:d20, :allow_launch_in_development, true)
    assert {:ok, released} = Games.get(game_id(183_006))
    assert {:ok, koala} = Games.get(game_id(425_873))
    assert {:ok, next_station} = Games.get(game_id(353_545))
    assert {:ok, planned} = Games.get(game_id(350_736))

    assert Games.session_launch_available?(released)
    assert Games.session_launch_available?(koala)
    assert Games.session_launch_available?(next_station)
    refute Games.session_launch_available?(planned)
  end

  test "disables Next Station launch when in-development launch is disabled" do
    Application.put_env(:d20, :allow_launch_in_development, false)
    assert {:ok, released} = Games.get(game_id(183_006))
    assert {:ok, next_station} = Games.get(game_id(353_545))
    assert {:ok, planned} = Games.get(game_id(350_736))

    assert Games.session_launch_available?(released)
    refute Games.session_launch_available?(next_station)
    refute Games.session_launch_available?(planned)
  end

  defp stub_bgg_game(xml) do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.params == %{"id" => "183006", "type" => "boardgame", "stats" => "1"}
      Req.Test.text(conn, xml)
    end)
  end

  defp stub_registered_bgg_games(overrides \\ %{}, omitted_ids \\ []) do
    Req.Test.expect(__MODULE__, fn conn ->
      assert %{"id" => ids, "type" => "boardgame", "stats" => "1"} = conn.params

      requested_ids = String.split(ids, ",")

      assert MapSet.new(requested_ids) == MapSet.new(Map.keys(@bgg_names))

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
