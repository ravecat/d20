defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  import ExUnit.CaptureLog

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Games
  alias D20.Games.Registry
  alias D20.Games.Sources.BoardGameGeek
  alias D20.Games.Sources.Local
  alias D20.KoalaRescueClub.Game, as: KoalaGame
  alias D20.Sessions.Session

  @qwinto_xml """
  <?xml version="1.0" encoding="utf-8"?>
  <items>
    <item type="boardgame" id="183006">
      <thumbnail>https://example.invalid/qwinto-thumb.jpg</thumbnail>
      <name type="primary" value="Qwinto" />
    </item>
  </items>
  """

  @resolved_qwinto_xml """
  <?xml version="1.0" encoding="utf-8"?>
  <items>
    <item type="boardgame" id="183006">
      <thumbnail>https://example.invalid/qwinto-thumb.jpg</thumbnail>
      <image>https://example.invalid/qwinto-image.jpg</image>
      <name type="primary" value="Resolved Qwinto" />
      <description>Resolved details.</description>
      <minplayers value="2" />
      <maxplayers value="6" />
      <playingtime value="30" />
      <minplaytime value="20" />
      <maxplaytime value="40" />
      <minage value="8" />
      <statistics page="1">
        <ratings>
          <average value="7.42" />
          <averageweight value="1.47" />
        </ratings>
      </statistics>
    </item>
  </items>
  """

  @koala_xml """
  <?xml version="1.0" encoding="utf-8"?>
  <items>
    <item type="boardgame" id="425873">
      <name type="primary" value="Koala Rescue Club" />
    </item>
  </items>
  """

  @next_station_xml """
  <?xml version="1.0" encoding="utf-8"?>
  <items>
    <item type="boardgame" id="353545">
      <name type="primary" value="Next Station: London" />
    </item>
  </items>
  """

  @voyages_xml """
  <?xml version="1.0" encoding="utf-8"?>
  <items>
    <item type="boardgame" id="350736">
      <name type="primary" value="Voyages" />
      <description>Draw maps and chart a course.</description>
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

    original_bgg_config = Application.get_env(:d20, BoardGameGeek, :not_configured)
    original_games_config = Application.get_env(:d20, Games, :not_configured)
    original_req_options = Req.default_options()
    original_registry_config = Application.fetch_env!(:d20, Registry)

    original_launch_config = Application.get_env(:d20, :allow_launch_in_progress, :not_configured)

    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    Application.put_env(:d20, Games, metadata_source: BoardGameGeek)
    Req.default_options(plug: {Req.Test, __MODULE__})
    Req.Test.stub(__MODULE__, fn conn -> Req.Test.text(conn, @qwinto_xml) end)

    on_exit(fn ->
      Req.default_options(original_req_options)
      Application.put_env(:d20, Registry, original_registry_config)

      case original_launch_config do
        :not_configured -> Application.delete_env(:d20, :allow_launch_in_progress)
        config -> Application.put_env(:d20, :allow_launch_in_progress, config)
      end

      case original_bgg_config do
        :not_configured -> Application.delete_env(:d20, BoardGameGeek)
        config -> Application.put_env(:d20, BoardGameGeek, config)
      end

      case original_games_config do
        :not_configured -> Application.delete_env(:d20, Games)
        config -> Application.put_env(:d20, Games, config)
      end
    end)
  end

  test "GET / renders game metadata", %{conn: conn} do
    stub_registered_bgg_games()

    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~ ~s(id="app")
    assert inertia_component(conn) == "home"
    assert token = conn.assigns.actor_token
    assert html_response(conn, 200) =~ ~s(window.actorToken = "#{token}")
    assert %{games: games} = inertia_props(conn)

    assert Enum.map(games, & &1.slug) == [
             "koala-rescue-club",
             "qwinto",
             "next-station-london",
             "aquamarine",
             "confusing-lands",
             "death-valley",
             "deep-sea-adventure",
             "flip-7",
             "fliptown",
             "lost-cities",
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

    assert %{status: nil} = Enum.find(games, &(&1.slug == "aquamarine"))
    assert %{status: :active} = Enum.find(games, &(&1.slug == "koala-rescue-club"))
    assert %{status: :in_progress} = Enum.find(games, &(&1.slug == "next-station-london"))
    assert %{status: :active} = Enum.find(games, &(&1.slug == "qwinto"))

    game = game_by_slug(games, "qwinto")

    assert game[:name] == "Qwinto"
    assert game[:thumbnailUrl] == "https://example.invalid/qwinto-thumb.jpg"
    refute Map.has_key?(game, :slug)
    refute Map.has_key?(game, :bggId)
    refute Map.has_key?(game, :embedUrl)
    refute Map.has_key?(game, :allowedOrigins)
    refute Map.has_key?(game, :bootstrap)
  end

  test "GET / renders runtime metadata when it is available", %{conn: conn} do
    stub_registered_bgg_games(%{"183006" => @resolved_qwinto_xml})

    conn = get(conn, ~p"/")

    assert %{games: games} = inertia_props(conn)
    game = game_by_slug(games, "qwinto")

    assert game[:name] == "Resolved Qwinto"
    assert game[:thumbnailUrl] == "https://example.invalid/qwinto-thumb.jpg"
    assert game[:imageUrl] == "https://example.invalid/qwinto-image.jpg"
  end

  test "GET / renders the catalog from local metadata without a BGG request", %{conn: conn} do
    Application.put_env(:d20, Games, metadata_source: Local)

    conn = get(conn, ~p"/")

    assert %{games: games} = inertia_props(conn)

    assert %{status: :active, game: %{name: "Koala Rescue Club"}} =
             Enum.find(games, &(&1.slug == "koala-rescue-club"))
  end

  test "GET / renders an empty catalog when runtime metadata is unavailable", %{conn: conn} do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 401, "Unauthorized") end)

    log =
      capture_log(fn ->
        conn = get(conn, ~p"/")

        assert html_response(conn, 200) =~ ~s(id="app")
        assert inertia_component(conn) == "home"
        assert %{games: []} = inertia_props(conn)
      end)

    assert log =~ "Failed to load game metadata"
  end

  test "GET /games redirects to the home showcase", %{conn: conn} do
    conn = get(conn, ~p"/games")

    assert redirected_to(conn) == ~p"/"
  end

  test "GET /developers renders the developer entry page", %{conn: conn} do
    conn = get(conn, ~p"/developers")

    assert html_response(conn, 200) =~ ~s(id="app")
    assert inertia_component(conn) == "developers"
    refute Map.has_key?(conn.assigns, :page_title)
  end

  test "GET /games/:slug renders metadata without creating a session", %{conn: conn} do
    stub_bgg_game(@resolved_qwinto_xml)

    conn = get(conn, ~p"/games/qwinto")

    assert inertia_component(conn) == "game"

    assert %{slug: "qwinto", module: nil, connection: nil, game: game, session: nil} =
             inertia_props(conn)

    assert %{status: :active, canLaunchGame: true} = inertia_props(conn)

    refute Map.has_key?(game, :slug)
    refute Map.has_key?(game, :bggId)
    assert game[:name] == "Resolved Qwinto"
    assert game[:description] == "Resolved details."
    assert game[:minPlayers] == 2
    assert game[:maxPlayers] == 6
    assert game[:playingTime] == 30
    assert game[:minPlayTime] == 20
    assert game[:maxPlayTime] == 40
    assert game[:minAge] == 8
    assert game[:complexity] == 1.47
    assert game[:rating] == 7.42
  end

  test "GET /games/:slug renders inactive game metadata without an engine", %{conn: conn} do
    stub_bgg_game(@voyages_xml, "350736")

    conn = get(conn, ~p"/games/voyages")

    assert inertia_component(conn) == "game"

    assert %{
             slug: "voyages",
             status: nil,
             canLaunchGame: false,
             attrs: %{},
             game: %{name: "Voyages", description: "Draw maps and chart a course."}
           } = inertia_props(conn)
  end

  test "GET /games/:slug keeps Koala launch available when in-progress launch is disabled", %{
    conn: conn
  } do
    Application.put_env(:d20, :allow_launch_in_progress, false)
    stub_bgg_game(@koala_xml, "425873")

    conn = get(conn, ~p"/games/koala-rescue-club")

    assert %{status: :active, canLaunchGame: true} = inertia_props(conn)
  end

  test "GET /games/:slug allows Next Station launch when in-progress launch is enabled", %{
    conn: conn
  } do
    Application.put_env(:d20, :allow_launch_in_progress, true)
    stub_bgg_game(@next_station_xml, "353545")

    conn = get(conn, ~p"/games/next-station-london")

    assert %{status: :in_progress, canLaunchGame: true, attrs: %{}} = inertia_props(conn)
  end

  test "GET /games/:slug disables Next Station launch when in-progress launch is disabled", %{
    conn: conn
  } do
    Application.put_env(:d20, :allow_launch_in_progress, false)
    stub_bgg_game(@next_station_xml, "353545")

    conn = get(conn, ~p"/games/next-station-london")

    assert %{status: :in_progress, canLaunchGame: false, attrs: %{}} = inertia_props(conn)
  end

  test "GET /games/:slug renders game-owned creation attrs", %{conn: conn} do
    stub_bgg_game(@koala_xml, "425873")

    conn = get(conn, ~p"/games/koala-rescue-club")

    assert %{
             attrs: %{
               opponent: %{
                 id: "attrs_opponent",
                 name: "opponent",
                 type: "enum",
                 value: "none",
                 required: true,
                 values: ["none", "bot_easy", "bot_normal", "bot_hard"],
                 errors: []
               },
               sheet: %{
                 id: "attrs_sheet",
                 name: "sheet",
                 type: "enum",
                 value: "dharug",
                 required: true,
                 values: ["dharug", "yugambeh"],
                 errors: []
               }
             }
           } = inertia_props(conn)
  end

  test "GET /games/:slug with a missing session redirects with errors", %{conn: conn} do
    session_id = Ecto.UUID.generate()

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Session not found."}
  end

  test "GET /games/:slug with a session from another game redirects with errors", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("other-game", D20.Qwinto.Game, "p1")

    on_exit(fn -> D20.Sessions.stop(session.id) end)

    conn = get(conn, ~p"/games/qwinto?session=#{session.id}")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Session not found."}
  end

  test "GET /games/:slug returns 404 for unknown games", %{conn: conn} do
    conn = get(conn, ~p"/games/missing")

    assert html_response(conn, 404) == "Not Found"
  end

  test "GET /games/:slug with a session returns 404 for unknown games", %{conn: conn} do
    conn = get(conn, ~p"/games/missing?session=#{Ecto.UUID.generate()}")

    assert html_response(conn, 404) == "Not Found"
  end

  test "POST /games/:slug/sessions creates a session and redirects to shareable URL", %{
    conn: conn
  } do
    Application.put_env(:d20, :allow_launch_in_progress, false)

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/qwinto/sessions")

    assert redirected_to(conn, 303) =~ ~r"^/games/qwinto\?session="
  end

  test "POST /games/:slug/sessions creates a Koala session with submitted attrs", %{conn: conn} do
    Application.put_env(:d20, :allow_launch_in_progress, false)

    conn =
      conn
      |> put_req_header("x-inertia", "true")
      |> post(~p"/games/koala-rescue-club/sessions", %{sheet: "yugambeh", opponent: "bot_hard"})

    redirected = redirected_to(conn, 303)
    assert redirected =~ ~r"^/games/koala-rescue-club\?session="
    [_, session_id] = Regex.run(~r/session=([^&]+)/, redirected)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    assert {:ok,
            {%Session{game: %KoalaGame{sheet: :yugambeh, opponent: :bot_hard}},
             "koala-rescue-club"}} = D20.Sessions.get(session_id)
  end

  test "POST /games/:slug/sessions forbids inactive games", %{conn: conn} do
    before_count = Elixir.Registry.count(D20.Registry)

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/voyages/sessions")

    assert text_response(conn, 403) == "Game sessions are unavailable."
    assert Elixir.Registry.count(D20.Registry) == before_count
  end

  test "POST /games/:slug/sessions forbids in-progress launch when configured", %{conn: conn} do
    Application.put_env(:d20, :allow_launch_in_progress, false)

    put_registry_games(
      qwinto: [
        engine: D20.Qwinto.Game,
        bgg_id: 183_006,
        sandbox: ["allow-scripts"],
        status: :in_progress
      ]
    )

    before_count = Elixir.Registry.count(D20.Registry)

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/qwinto/sessions")

    assert text_response(conn, 403) == "Game sessions are unavailable."
    assert Elixir.Registry.count(D20.Registry) == before_count
  end

  test "POST /games/:slug/sessions redirects with errors when creation attrs are invalid", %{
    conn: conn
  } do
    before_count = Elixir.Registry.count(D20.Registry)

    conn =
      conn
      |> put_req_header("x-inertia", "true")
      |> post(~p"/games/koala-rescue-club/sessions", %{sheet: "missing"})

    assert redirected_to(conn, 303) == ~p"/games/koala-rescue-club"
    assert inertia_errors(conn) == %{sheet: "is invalid"}
    assert Elixir.Registry.count(D20.Registry) == before_count
  end

  test "POST /games/:slug/sessions returns 404 for unknown games", %{conn: conn} do
    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/missing/sessions")

    assert html_response(conn, 404) == "Not Found"
  end

  test "POST /games/:slug/sessions redirects with errors when the configured engine is invalid",
       %{conn: conn} do
    put_registry_games(
      qwinto: [engine: String, bgg_id: 183_006, sandbox: ["allow-scripts"], status: :active]
    )

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/qwinto/sessions")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Could not start session."}
  end

  test "GET /games/:slug with a waiting session attaches module connection", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, "p1")
    session_id = session.id
    session_ref = session_id

    on_exit(fn -> D20.Sessions.stop(session_ref) end)

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert %{module: module, connection: connection, session: session} = inertia_props(conn)
    assert session.id == session_id
    assert session.phase == :waiting_for_players
    assert session.members == %{}
    assert module[:embedUrl] == "http://qwinto.example.com/"
    assert module[:allowedOrigins] == ["http://qwinto.example.com"]
    assert "allow-scripts" in module[:sandbox]
    refute Map.has_key?(module, :bootstrap)
    refute Map.has_key?(connection, :moduleId)
    refute Map.has_key?(connection, :socketUrl)
    refute Map.has_key?(connection, :slug)
    refute Map.has_key?(connection, :actor)
    assert connection[:endpoint] == "ws://example.com/module"
    topic = "session:#{session_id}"
    assert connection[:topic] == topic

    assert {:ok,
            %{
              endpoint: "ws://example.com/module",
              slug: "qwinto",
              topic: ^topic,
              actor: %Actor{id: actor_id, type: :anonymous}
            }} = D20.Module.Token.verify(D20Web.Endpoint, connection[:token])

    assert is_binary(actor_id)
  end

  test "GET /games/:slug with forwarded https attaches secure module URLs", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, "p1")
    session_id = session.id
    session_ref = session_id

    on_exit(fn -> D20.Sessions.stop(session_ref) end)

    conn =
      conn
      |> put_req_header("x-forwarded-proto", "https")
      |> get(~p"/games/qwinto?session=#{session_id}")

    assert %{module: module, connection: connection} = inertia_props(conn)
    assert module[:embedUrl] == "https://qwinto.example.com/"
    assert module[:allowedOrigins] == ["https://qwinto.example.com"]
    assert connection[:endpoint] == "wss://example.com/module"

    topic = "session:#{session_id}"

    assert {:ok, %{endpoint: "wss://example.com/module", topic: ^topic}} =
             D20.Module.Token.verify(D20Web.Endpoint, connection[:token])
  end

  test "GET /games/:slug with an in-progress session attaches module connection", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, "p1")
    session_id = session.id
    session_ref = session_id

    on_exit(fn -> D20.Sessions.stop(session_ref) end)

    assert {:ok, _session} =
             D20.Sessions.dispatch(session_scope(session_ref, "p1"), "join", %{online_at: 100})

    assert {:ok, _session} =
             D20.Sessions.dispatch(session_scope(session_ref, "p2"), "join", %{online_at: 123})

    assert {:ok, _session} = D20.Sessions.dispatch(session_scope(session_ref, "p1"), "start", %{})

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert %{module: module, connection: connection, session: session} = inertia_props(conn)
    assert session.id == session_id
    assert session.phase == :in_progress
    assert session.members == %{"p1" => %{online_at: 100}, "p2" => %{online_at: 123}}
    refute Map.has_key?(module, :bootstrap)
    refute Map.has_key?(connection, :moduleId)
    refute Map.has_key?(connection, :socketUrl)
    assert connection[:endpoint] == "ws://example.com/module"
    assert connection[:topic] == "session:#{session_id}"
  end

  defp put_registry_games(games) do
    Application.put_env(:d20, Registry, games: games)
  end

  defp stub_bgg_game(xml, id \\ "183006") do
    Req.Test.expect(__MODULE__, fn conn ->
      assert conn.params == %{"id" => id, "type" => "boardgame", "stats" => "1"}

      Req.Test.text(conn, xml)
    end)
  end

  defp stub_registered_bgg_games(overrides \\ %{}) do
    Req.Test.expect(__MODULE__, fn conn ->
      assert %{"id" => ids, "type" => "boardgame", "stats" => "1"} = conn.params

      requested_ids = String.split(ids, ",")
      assert MapSet.new(requested_ids) == MapSet.new(Map.keys(@registered_game_names))

      items =
        Enum.map_join(requested_ids, fn id ->
          id
          |> then(&Map.get(overrides, &1, game_xml(&1, Map.fetch!(@registered_game_names, &1))))
          |> extract_item()
        end)

      Req.Test.text(conn, "<items>#{items}</items>")
    end)
  end

  defp game_xml("183006", "Qwinto"), do: @qwinto_xml

  defp game_xml(id, name) do
    """
    <?xml version="1.0" encoding="utf-8"?>
    <items>
      <item type="boardgame" id="#{id}">
        <name type="primary" value="#{name}" />
      </item>
    </items>
    """
  end

  defp extract_item(xml) do
    [item] = Regex.run(~r/<item\b.*<\/item>/s, xml)
    item
  end

  defp game_by_slug(games, slug) do
    games
    |> Enum.find(&(&1.slug == slug))
    |> Map.fetch!(:game)
  end

  defp session_scope(session_id, actor_id) do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game("qwinto")
  end
end
