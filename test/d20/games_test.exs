defmodule D20.GamesTest do
  use ExUnit.Case, async: false

  alias D20.Games
  alias D20.Games.Game
  alias D20.Games.Registry
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

  @registered_game_names %{
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

    original_launch_config = Application.get_env(:d20, :allow_launch_in_progress, :not_configured)

    original_req_options = Req.default_options()

    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    Req.default_options(plug: {Req.Test, __MODULE__})

    on_exit(fn ->
      Req.default_options(original_req_options)

      case original_launch_config do
        :not_configured -> Application.delete_env(:d20, :allow_launch_in_progress)
        config -> Application.put_env(:d20, :allow_launch_in_progress, config)
      end

      case original_config do
        :not_configured -> Application.delete_env(:d20, BoardGameGeek)
        config -> Application.put_env(:d20, BoardGameGeek, config)
      end
    end)
  end

  test "fetches registered Qwinto metadata by slug" do
    stub_bgg_game(@qwinto_xml)

    assert {:ok, %Game{} = game} = Games.fetch_by_slug("qwinto")
    assert game.name == "Qwinto"
    assert game.categories == ["Dice", "Number"]
    assert game.mechanics == ["Dice Rolling", "Paper-and-Pencil"]
    assert game.description == "Resolved from BGG."
    assert game.thumbnail_url == "https://example.invalid/thumb.jpg"
    assert game.min_age == 8
    assert game.complexity == 1.47
    assert game.rating == 7.42
    refute Map.has_key?(game, :slug)
  end

  test "lists registered game metadata by availability and registry order" do
    stub_registered_bgg_games()

    assert {:ok, games} = Games.list()

    assert Enum.map(games, & &1.slug) == [
             "qwinto",
             "koala-rescue-club",
             "aquamarine",
             "confusing-lands",
             "death-valley",
             "deep-sea-adventure",
             "flip-7",
             "fliptown",
             "lost-cities",
             "next-station-london",
             "nimalia",
             "qwixx",
             "railroad-ink",
             "shifting-stones",
             "sky-team",
             "trailblazers",
             "trails-of-tucana",
             "voyages",
             "waypoints"
           ]

    assert %{status: nil, game: %Game{name: "Aquamarine"}} =
             Enum.find(games, &(&1.slug == "aquamarine"))

    assert %Game{name: "Fliptown"} = game_by_slug(games, "fliptown")

    assert %{status: :in_progress, game: %Game{name: "Koala Rescue Club"}} =
             Enum.find(games, &(&1.slug == "koala-rescue-club"))

    assert %Game{name: "Next Station: London"} = game_by_slug(games, "next-station-london")

    assert %{status: :active, game: %Game{name: "Qwinto"}} =
             Enum.find(games, &(&1.slug == "qwinto"))
  end

  test "returns batch metadata source errors without a game slug" do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 401, "Unauthorized") end)

    assert Games.list() == {:error, {:http_error, 401}}
  end

  test "returns metadata source errors for registered games" do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)

    assert Games.fetch_by_slug("qwinto") == {:error, {:http_error, 503}}
  end

  test "returns not found for unknown games" do
    assert Games.fetch_by_slug("missing") == {:error, :game_not_found}
  end

  test "allows active and in-progress session launch outside production" do
    assert {:ok, active} = Registry.fetch("qwinto")
    assert {:ok, in_progress} = Registry.fetch("koala-rescue-club")
    assert {:ok, inactive} = Registry.fetch("voyages")

    assert Games.session_launch_available?(active)
    assert Games.session_launch_available?(in_progress)
    refute Games.session_launch_available?(inactive)
  end

  test "keeps active launch available when in-progress launch is disabled" do
    Application.put_env(:d20, :allow_launch_in_progress, false)
    assert {:ok, active} = Registry.fetch("qwinto")
    assert {:ok, in_progress} = Registry.fetch("koala-rescue-club")
    assert {:ok, inactive} = Registry.fetch("voyages")

    assert Games.session_launch_available?(active)
    refute Games.session_launch_available?(in_progress)
    refute Games.session_launch_available?(inactive)
  end

  defp stub_bgg_game(xml) do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.params == %{"id" => "183006", "type" => "boardgame", "stats" => "1"}

      Req.Test.text(conn, xml)
    end)
  end

  defp stub_registered_bgg_games do
    Req.Test.expect(__MODULE__, fn conn ->
      assert %{"id" => ids, "type" => "boardgame", "stats" => "1"} = conn.params

      requested_ids = String.split(ids, ",")

      assert MapSet.new(requested_ids) == MapSet.new(Map.keys(@registered_game_names))

      items =
        Enum.map_join(requested_ids, fn id ->
          game_item_xml(id, Map.fetch!(@registered_game_names, id))
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

  defp game_by_slug(games, slug) do
    games
    |> Enum.find(&(&1.slug == slug))
    |> Map.fetch!(:game)
  end
end
