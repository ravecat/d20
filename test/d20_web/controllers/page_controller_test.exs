defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  import ExUnit.CaptureLog

  alias D20.Games.Registry
  alias D20.Games.Sources.BoardGameGeek
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
    original_req_options = Req.default_options()
    original_registry_config = Application.fetch_env!(:d20, Registry)
    original_google_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)

    original_launch_config = Application.get_env(:d20, :allow_launch_in_progress, :not_configured)

    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "google-test-client-id",
      client_secret: "google-test-client-secret"
    )

    Req.default_options(plug: {Req.Test, __MODULE__})
    Req.Test.stub(__MODULE__, fn conn -> Req.Test.text(conn, @qwinto_xml) end)

    on_exit(fn ->
      Req.default_options(original_req_options)
      Application.put_env(:d20, Registry, original_registry_config)

      case original_google_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)
        config -> Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, config)
      end

      case original_launch_config do
        :not_configured -> Application.delete_env(:d20, :allow_launch_in_progress)
        config -> Application.put_env(:d20, :allow_launch_in_progress, config)
      end

      case original_bgg_config do
        :not_configured -> Application.delete_env(:d20, BoardGameGeek)
        config -> Application.put_env(:d20, BoardGameGeek, config)
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

  test "GET / renders the complete fallback catalog when BGG is unavailable", %{conn: conn} do
    Req.Test.expect(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 401, "Unauthorized") end)

    log =
      capture_log(fn ->
        conn = get(conn, ~p"/")

        assert html_response(conn, 200) =~ ~s(id="app")
        assert inertia_component(conn) == "home"
        assert %{games: games} = inertia_props(conn)
        assert length(games) == map_size(@registered_game_names)
        assert %{name: nil, imageUrl: nil} = game_by_slug(games, "qwinto")
      end)

    assert log =~ "Failed to enrich game metadata; using local fallback"
  end

  test "GET / renders the complete fallback catalog without BGG credentials", %{conn: conn} do
    Application.delete_env(:d20, BoardGameGeek)

    capture_log(fn ->
      conn = get(conn, ~p"/")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert %{games: games} = inertia_props(conn)
      assert length(games) == map_size(@registered_game_names)

      assert %{status: :active, game: %{name: nil, imageUrl: nil}} =
               Enum.find(games, &(&1.slug == "koala-rescue-club"))
    end)
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

  test "Inertia pages share guest authentication state", %{conn: conn} do
    conn = get(conn, ~p"/developers")

    assert inertia_props(conn).auth == %{
             authenticated: false,
             local: false,
             prompt: nil,
             providers: %{google: %{available: true}}
           }

    assert "auth" in inertia_shared_props(conn)
    refute "authenticated" in inertia_shared_props(conn)
    refute "authPrompt" in inertia_shared_props(conn)
    refute "localMailboxAvailable" in inertia_shared_props(conn)
  end

  test "Inertia pages expose only derived Google availability", %{conn: conn} do
    conn = get(conn, ~p"/developers")

    assert inertia_props(conn).auth.providers == %{google: %{available: true}}
    refute Map.has_key?(inertia_props(conn).auth, :client_id)
    refute Map.has_key?(inertia_props(conn).auth, :client_secret)
  end

  test "Inertia pages report Google unavailable when a credential is missing", %{conn: conn} do
    put_google_oauth_config(client_id: nil, client_secret: "google-client-secret")

    conn = get(conn, ~p"/developers")

    assert inertia_props(conn).auth.providers == %{google: %{available: false}}
  end

  test "Inertia pages expose the local mailbox when dev routes and the Local adapter are enabled",
       %{conn: conn} do
    put_local_mailbox_config(true, Swoosh.Adapters.Local)

    conn = get(conn, ~p"/developers")

    assert inertia_props(conn).auth.local == true
  end

  test "Inertia pages hide the local mailbox when dev routes are disabled", %{conn: conn} do
    put_local_mailbox_config(false, Swoosh.Adapters.Local)

    conn = get(conn, ~p"/developers")

    assert inertia_props(conn).auth.local == false
  end

  test "Inertia pages hide the local mailbox when the Local adapter is disabled", %{conn: conn} do
    put_local_mailbox_config(true, Swoosh.Adapters.Test)

    conn = get(conn, ~p"/developers")

    assert inertia_props(conn).auth.local == false
  end

  test "Inertia pages share authenticated user state", %{conn: conn} do
    conn = conn |> log_in_user(D20.AccountsFixtures.user_fixture()) |> get(~p"/developers")

    assert inertia_props(conn).auth.authenticated == true
    assert "auth" in inertia_shared_props(conn)
  end

  test "Inertia pages expose an authentication prompt once", %{conn: conn} do
    prompt = %{
      email: "player@example.com",
      message: "You must log in to access this page.",
      reauthenticate: false,
      return_to: "/users/settings"
    }

    conn = conn |> init_test_session(auth_prompt: prompt) |> get(~p"/developers")

    assert inertia_props(conn).auth.prompt == %{
             email: "player@example.com",
             message: "You must log in to access this page.",
             reauthenticate: false,
             returnTo: "/users/settings"
           }

    refute get_session(conn, :auth_prompt)

    conn = conn |> recycle() |> get(~p"/developers")
    assert inertia_props(conn).auth.prompt == nil
  end

  test "Inertia pages do not bootstrap workspace sessions or module tokens", %{conn: conn} do
    conn = get(conn, ~p"/developers")
    props = inertia_props(conn)

    refute Map.has_key?(props, :sessions)
    refute Map.has_key?(props, :module)
    refute Map.has_key?(props, :connection)
    refute "sessions" in inertia_shared_props(conn)
  end

  test "GET /games/:slug renders metadata without creating a session", %{conn: conn} do
    stub_bgg_game(@resolved_qwinto_xml)

    conn = get(conn, ~p"/games/qwinto")

    assert inertia_component(conn) == "game"

    assert %{
             slug: "qwinto",
             session: nil,
             game: game,
             schema: %{"type" => "object", "properties" => %{}, "default" => %{}}
           } = inertia_props(conn)

    refute Map.has_key?(inertia_props(conn), :module)
    refute Map.has_key?(inertia_props(conn), :connection)

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
             schema: nil,
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

    assert %{
             status: :in_progress,
             canLaunchGame: true,
             schema: %{
               "type" => "object",
               "properties" => %{
                 "objectives" => %{"type" => "boolean"},
                 "powers" => %{"type" => "boolean"}
               },
               "required" => required,
               "default" => %{objectives: false, powers: false}
             }
           } = inertia_props(conn)

    assert Enum.sort(required) == ["objectives", "powers"]
  end

  test "GET /games/:slug disables Next Station launch when in-progress launch is disabled", %{
    conn: conn
  } do
    Application.put_env(:d20, :allow_launch_in_progress, false)
    stub_bgg_game(@next_station_xml, "353545")

    conn = get(conn, ~p"/games/next-station-london")

    assert %{status: :in_progress, canLaunchGame: false, schema: nil} = inertia_props(conn)
  end

  test "GET /games/:slug renders a game-owned creation form schema", %{conn: conn} do
    stub_bgg_game(@koala_xml, "425873")

    conn = get(conn, ~p"/games/koala-rescue-club")

    assert %{
             schema: %{
               "type" => "object",
               "properties" => %{
                 "sheet" => %{"type" => "string", "enum" => ["dharug", "yugambeh"]}
               },
               "required" => ["sheet"],
               "default" => %{sheet: :dharug}
             }
           } = inertia_props(conn)
  end

  test "GET /games/:slug renders fallback metadata and launch controls without BGG credentials",
       %{conn: conn} do
    Application.delete_env(:d20, BoardGameGeek)

    capture_log(fn ->
      conn = get(conn, ~p"/games/koala-rescue-club")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert inertia_component(conn) == "game"

      assert %{
               slug: "koala-rescue-club",
               status: :active,
               canLaunchGame: true,
               game: %{name: nil, imageUrl: nil},
               schema: %{
                 "type" => "object",
                 "properties" => %{
                   "sheet" => %{"type" => "string", "enum" => ["dharug", "yugambeh"]}
                 },
                 "required" => ["sheet"],
                 "default" => %{sheet: :dharug}
               },
               session: nil
             } = inertia_props(conn)
    end)
  end

  test "GET /games/:slug rejects a missing waiting session", %{conn: conn} do
    session_id = Ecto.UUID.generate()
    stub_bgg_game(@resolved_qwinto_xml)

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Session not found."}
  end

  test "GET /games/:slug rejects a waiting session from another game", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("other-game", D20.Qwinto.Game, "owner")
    on_exit(fn -> D20.Sessions.stop(session.id) end)
    stub_bgg_game(@resolved_qwinto_xml)

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

  test "POST /games/:slug/sessions creates a session and redirects to its lobby", %{conn: conn} do
    Application.put_env(:d20, :allow_launch_in_progress, false)

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/qwinto/sessions")

    redirect = redirected_to(conn, 303)
    assert redirect =~ ~r"^/games/qwinto\?session="
    %URI{query: query} = URI.parse(redirect)
    %{"session" => session_id} = URI.decode_query(query)
    on_exit(fn -> D20.Sessions.stop(session_id) end)

    stub_bgg_game(@resolved_qwinto_xml)
    conn = conn |> recycle() |> get(redirect)

    assert %{session: %{id: ^session_id, slug: "qwinto", topic: "session:" <> ^session_id}} =
             inertia_props(conn)

    refute Map.has_key?(inertia_props(conn), :module)
    refute Map.has_key?(inertia_props(conn), :connection)
    refute inspect(inertia_props(conn)) =~ "token"
  end

  test "POST /games/:slug/sessions creates a Koala session with submitted attrs", %{conn: conn} do
    Application.put_env(:d20, :allow_launch_in_progress, false)

    conn =
      conn
      |> put_req_header("x-inertia", "true")
      |> post(~p"/games/koala-rescue-club/sessions", %{sheet: "yugambeh"})

    redirect = redirected_to(conn, 303)
    assert redirect =~ ~r"^/games/koala-rescue-club\?session="
    %URI{query: query} = URI.parse(redirect)
    %{"session" => session_id} = URI.decode_query(query)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    assert {:ok, {%Session{game: %KoalaGame{sheet: :yugambeh}}, "koala-rescue-club"}} =
             D20.Sessions.get(session_id)
  end

  test "GET /games/:slug renders a live waiting session without module credentials", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, "owner")
    on_exit(fn -> D20.Sessions.stop(session.id) end)
    stub_bgg_game(@resolved_qwinto_xml)

    conn = get(conn, ~p"/games/qwinto?session=#{session.id}")

    assert %{session: %{id: session_id, slug: "qwinto", topic: topic}} = inertia_props(conn)

    assert session_id == session.id
    assert topic == "session:#{session.id}"
    refute Map.has_key?(inertia_props(conn), :module)
    refute Map.has_key?(inertia_props(conn), :connection)
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

  defp put_registry_games(games) do
    Application.put_env(:d20, Registry, games: games)
  end

  defp put_local_mailbox_config(dev_routes, adapter) do
    original_dev_routes = Application.get_env(:d20, :dev_routes, :not_configured)
    original_mailer_config = Application.fetch_env!(:d20, D20.Mailer)

    Application.put_env(:d20, :dev_routes, dev_routes)
    Application.put_env(:d20, D20.Mailer, Keyword.put(original_mailer_config, :adapter, adapter))

    on_exit(fn ->
      Application.put_env(:d20, D20.Mailer, original_mailer_config)

      case original_dev_routes do
        :not_configured -> Application.delete_env(:d20, :dev_routes)
        configured -> Application.put_env(:d20, :dev_routes, configured)
      end
    end)
  end

  defp put_google_oauth_config(config) do
    previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)
    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, config)

    on_exit(fn ->
      case previous_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)
        value -> Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, value)
      end
    end)
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
end
