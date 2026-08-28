defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  import ExUnit.CaptureLog

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
    original_apple_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Apple)
    original_discord_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth)
    original_facebook_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)
    original_google_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)
    original_steam_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Steam)

    original_launch_config =
      Application.get_env(:d20, :allow_launch_in_development, :not_configured)

    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")

    Application.put_env(:ueberauth, Ueberauth.Strategy.Apple, [])

    Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth,
      client_id: "discord-test-client-id",
      client_secret: "discord-test-client-secret"
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth,
      client_id: nil,
      client_secret: nil
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "google-test-client-id",
      client_secret: "google-test-client-secret"
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, api_key: nil)

    Req.default_options(plug: {Req.Test, __MODULE__})
    Req.Test.stub(__MODULE__, fn conn -> Req.Test.text(conn, @qwinto_xml) end)

    on_exit(fn ->
      Req.default_options(original_req_options)

      case original_apple_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Apple)
        config -> Application.put_env(:ueberauth, Ueberauth.Strategy.Apple, config)
      end

      case original_discord_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth)
        config -> Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth, config)
      end

      case original_facebook_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)
        config -> Application.put_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth, config)
      end

      case original_google_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)
        config -> Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, config)
      end

      case original_steam_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Steam)
        config -> Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, config)
      end

      case original_launch_config do
        :not_configured -> Application.delete_env(:d20, :allow_launch_in_development)
        config -> Application.put_env(:d20, :allow_launch_in_development, config)
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

    assert Enum.map(games, & &1.id) == Enum.map(ordered_bgg_ids, &game_id_string/1)

    refute Enum.any?(games, &Map.has_key?(&1, :slug))

    assert %{stage: :planned} = Enum.find(games, &(&1.id == game_id_string(360_471)))
    assert %{stage: :released} = Enum.find(games, &(&1.id == game_id_string(425_873)))
    assert %{stage: :in_development} = Enum.find(games, &(&1.id == game_id_string(353_545)))
    assert %{stage: :released} = Enum.find(games, &(&1.id == game_id_string(183_006)))

    game = game_by_bgg_id(games, 183_006)

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
    game = game_by_bgg_id(games, 183_006)

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
        assert %{name: nil, imageUrl: nil} = game_by_bgg_id(games, 183_006)
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

      assert %{stage: :released, game: %{name: nil, imageUrl: nil}} =
               Enum.find(games, &(&1.id == game_id_string(425_873)))
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
             providers: %{
               apple: %{available: false},
               discord: %{available: true},
               facebook: %{available: false},
               google: %{available: true},
               steam: %{available: false}
             }
           }

    assert "auth" in inertia_shared_props(conn)
    refute "authenticated" in inertia_shared_props(conn)
    refute "authPrompt" in inertia_shared_props(conn)
    refute "localMailboxAvailable" in inertia_shared_props(conn)
  end

  test "Inertia pages expose only derived provider availability", %{conn: conn} do
    conn = get(conn, ~p"/developers")

    assert inertia_props(conn).auth.providers == %{
             apple: %{available: false},
             discord: %{available: true},
             facebook: %{available: false},
             google: %{available: true},
             steam: %{available: false}
           }

    refute Map.has_key?(inertia_props(conn).auth, :client_id)
    refute Map.has_key?(inertia_props(conn).auth, :client_secret)
  end

  test "Inertia pages derive provider availability independently", %{conn: conn} do
    put_apple_auth_config()
    put_discord_oauth_config(client_id: "discord-client-id", client_secret: nil)

    put_facebook_oauth_config(
      client_id: "facebook-client-id",
      client_secret: "facebook-client-secret"
    )

    put_google_oauth_config(client_id: nil, client_secret: "google-client-secret")
    put_steam_strategy_configured(true)

    conn = get(conn, ~p"/developers")

    assert inertia_props(conn).auth.providers == %{
             apple: %{available: true},
             discord: %{available: false},
             facebook: %{available: true},
             google: %{available: false},
             steam: %{available: true}
           }
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
      kind: :warning,
      message: "You must log in to access this page.",
      reauthenticate: false,
      return_to: "/users/settings"
    }

    conn = conn |> init_test_session(auth_prompt: prompt) |> get(~p"/developers")

    assert inertia_props(conn).auth.prompt == %{
             email: "player@example.com",
             kind: :warning,
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

  test "GET /games/:game_id renders metadata without creating a session", %{conn: conn} do
    stub_bgg_game(@resolved_qwinto_xml)
    game_id = game_id(183_006)
    game_id_string = TypeID.to_string(game_id)

    conn = get(conn, ~p"/games/#{game_id}")

    assert inertia_component(conn) == "game"

    assert %{
             id: ^game_id_string,
             session: nil,
             game: game,
             schema: %{"type" => "object", "properties" => %{}, "default" => %{}}
           } = inertia_props(conn)

    refute Map.has_key?(inertia_props(conn), :module)
    refute Map.has_key?(inertia_props(conn), :connection)
    refute Map.has_key?(inertia_props(conn), :slug)

    assert %{stage: :released, canLaunchGame: true} = inertia_props(conn)

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

  test "GET /games/:game_id renders planned game metadata without an engine", %{conn: conn} do
    stub_bgg_game(@voyages_xml, "350736")
    game_id = game_id(350_736)
    game_id_string = TypeID.to_string(game_id)

    conn = get(conn, ~p"/games/#{game_id}")

    assert inertia_component(conn) == "game"

    assert %{
             id: ^game_id_string,
             stage: :planned,
             canLaunchGame: false,
             schema: nil,
             game: %{name: "Voyages", description: "Draw maps and chart a course."}
           } = inertia_props(conn)
  end

  test "GET /games/:game_id keeps Koala launch available when in-development launch is disabled",
       %{conn: conn} do
    Application.put_env(:d20, :allow_launch_in_development, false)
    stub_bgg_game(@koala_xml, "425873")

    conn = get(conn, ~p"/games/#{game_id(425_873)}")

    assert %{stage: :released, canLaunchGame: true} = inertia_props(conn)
  end

  test "GET /games/:game_id allows Next Station launch when in-development launch is enabled", %{
    conn: conn
  } do
    Application.put_env(:d20, :allow_launch_in_development, true)
    stub_bgg_game(@next_station_xml, "353545")

    conn = get(conn, ~p"/games/#{game_id(353_545)}")

    assert %{
             stage: :in_development,
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

  test "GET /games/:game_id disables Next Station launch when in-development launch is disabled",
       %{conn: conn} do
    Application.put_env(:d20, :allow_launch_in_development, false)
    stub_bgg_game(@next_station_xml, "353545")

    conn = get(conn, ~p"/games/#{game_id(353_545)}")

    assert %{stage: :in_development, canLaunchGame: false, schema: nil} = inertia_props(conn)
  end

  test "GET /games/:game_id renders a game-owned creation form schema", %{conn: conn} do
    stub_bgg_game(@koala_xml, "425873")

    conn = get(conn, ~p"/games/#{game_id(425_873)}")

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

  test "GET /games/:game_id renders fallback metadata and launch controls without BGG credentials",
       %{conn: conn} do
    Application.delete_env(:d20, BoardGameGeek)

    capture_log(fn ->
      game_id = game_id(425_873)
      game_id_string = TypeID.to_string(game_id)
      conn = get(conn, ~p"/games/#{game_id}")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert inertia_component(conn) == "game"

      assert %{
               id: ^game_id_string,
               stage: :released,
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

  test "GET /games/:game_id rejects a missing waiting session", %{conn: conn} do
    session_id = Ecto.UUID.generate()
    game_id = game_id(183_006)
    stub_bgg_game(@resolved_qwinto_xml)

    conn = get(conn, ~p"/games/#{game_id}?session=#{session_id}")

    assert redirected_to(conn, 303) == ~p"/games/#{game_id}"
    assert inertia_errors(conn) == %{session: "Session not found."}
  end

  test "GET /games/:game_id rejects a waiting session from another game", %{conn: conn} do
    qwinto_id = game_id(183_006)
    assert {:ok, session} = D20.Sessions.create(game_id(425_873), D20.Qwinto.Game, "owner")
    on_exit(fn -> D20.Sessions.stop(session.id) end)
    stub_bgg_game(@resolved_qwinto_xml)

    conn = get(conn, ~p"/games/#{qwinto_id}?session=#{session.id}")

    assert redirected_to(conn, 303) == ~p"/games/#{qwinto_id}"
    assert inertia_errors(conn) == %{session: "Session not found."}
  end

  test "GET /games/:game_id returns 404 for unknown games", %{conn: conn} do
    conn = get(conn, ~p"/games/#{TypeID.new("game")}")

    assert html_response(conn, 404) == "Not Found"
  end

  test "GET /games/:game_id returns 400 for malformed and wrong-prefix ids", %{conn: conn} do
    assert_error_sent :bad_request, fn -> get(conn, "/games/not-a-typeid") end
    assert_error_sent :bad_request, fn -> get(conn, ~p"/games/#{TypeID.new("user")}") end
  end

  test "GET /games/:game_id/:slug is not routed", %{conn: conn} do
    conn = get(conn, "/games/#{game_id(183_006)}/qwinto")

    assert conn.status == 404
  end

  test "GET /games/:game_id with a session returns 404 for unknown games", %{conn: conn} do
    conn = get(conn, ~p"/games/#{TypeID.new("game")}?session=#{Ecto.UUID.generate()}")

    assert html_response(conn, 404) == "Not Found"
  end

  test "POST /games/:game_id/sessions creates a session and redirects to its lobby", %{conn: conn} do
    Application.put_env(:d20, :allow_launch_in_development, false)
    game_id = game_id(183_006)
    game_id_string = TypeID.to_string(game_id)

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/#{game_id}/sessions")

    redirect = redirected_to(conn, 303)
    assert String.starts_with?(redirect, "/games/#{game_id}?session=")
    %URI{query: query} = URI.parse(redirect)
    %{"session" => session_id} = URI.decode_query(query)
    on_exit(fn -> D20.Sessions.stop(session_id) end)

    stub_bgg_game(@resolved_qwinto_xml)
    conn = conn |> recycle() |> get(redirect)

    assert %{
             session: %{
               id: ^session_id,
               gameId: ^game_id_string,
               topic: "session:" <> ^session_id
             }
           } = inertia_props(conn)

    refute Map.has_key?(inertia_props(conn), :module)
    refute Map.has_key?(inertia_props(conn), :connection)
    refute inspect(inertia_props(conn)) =~ "token"
  end

  test "POST /games/:game_id/sessions creates a Koala session with submitted attrs", %{conn: conn} do
    Application.put_env(:d20, :allow_launch_in_development, false)
    game_id = game_id(425_873)

    conn =
      conn
      |> put_req_header("x-inertia", "true")
      |> post(~p"/games/#{game_id}/sessions", %{sheet: "yugambeh"})

    redirect = redirected_to(conn, 303)
    assert String.starts_with?(redirect, "/games/#{game_id}?session=")
    %URI{query: query} = URI.parse(redirect)
    %{"session" => session_id} = URI.decode_query(query)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    assert {:ok, {%Session{game: %KoalaGame{sheet: :yugambeh}}, ^game_id}} =
             D20.Sessions.get(session_id)
  end

  test "GET /games/:game_id renders a live waiting session without module credentials", %{
    conn: conn
  } do
    game_id = game_id(183_006)
    game_id_string = TypeID.to_string(game_id)
    assert {:ok, session} = D20.Sessions.create(game_id, D20.Qwinto.Game, "owner")
    on_exit(fn -> D20.Sessions.stop(session.id) end)
    stub_bgg_game(@resolved_qwinto_xml)

    conn = get(conn, ~p"/games/#{game_id}?session=#{session.id}")

    assert %{session: %{id: session_id, gameId: ^game_id_string, topic: topic}} =
             inertia_props(conn)

    assert session_id == session.id
    assert topic == "session:#{session.id}"
    refute Map.has_key?(inertia_props(conn), :module)
    refute Map.has_key?(inertia_props(conn), :connection)
  end

  test "POST /games/:game_id/sessions forbids planned games", %{conn: conn} do
    before_count = Elixir.Registry.count(D20.Registry)

    conn =
      conn |> put_req_header("x-inertia", "true") |> post(~p"/games/#{game_id(350_736)}/sessions")

    assert text_response(conn, 403) == "Game sessions are unavailable."
    assert Elixir.Registry.count(D20.Registry) == before_count
  end

  test "POST /games/:game_id/sessions forbids in-development launch when configured", %{
    conn: conn
  } do
    Application.put_env(:d20, :allow_launch_in_development, false)

    game_id = game_id(183_006)
    {:ok, game} = D20.Games.get(game_id)
    {:ok, _updated} = D20.Games.update(game, %{stage: :in_development})

    before_count = Elixir.Registry.count(D20.Registry)

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/#{game_id}/sessions")

    assert text_response(conn, 403) == "Game sessions are unavailable."
    assert Elixir.Registry.count(D20.Registry) == before_count
  end

  test "POST /games/:game_id/sessions redirects with errors when creation attrs are invalid", %{
    conn: conn
  } do
    before_count = Elixir.Registry.count(D20.Registry)
    game_id = game_id(425_873)

    conn =
      conn
      |> put_req_header("x-inertia", "true")
      |> post(~p"/games/#{game_id}/sessions", %{sheet: "missing"})

    assert redirected_to(conn, 303) == ~p"/games/#{game_id}"
    assert inertia_errors(conn) == %{sheet: "is invalid"}
    assert Elixir.Registry.count(D20.Registry) == before_count
  end

  test "POST /games/:game_id/sessions returns 404 for unknown games", %{conn: conn} do
    conn =
      conn
      |> put_req_header("x-inertia", "true")
      |> post(~p"/games/#{TypeID.new("game")}/sessions")

    assert html_response(conn, 404) == "Not Found"
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

  defp put_facebook_oauth_config(config) do
    previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)
    Application.put_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth, config)

    on_exit(fn ->
      case previous_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)
        value -> Application.put_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth, value)
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

  defp put_steam_strategy_configured(configured?) do
    previous_config = Application.fetch_env!(:ueberauth, Ueberauth)
    previous_steam = Application.get_env(:ueberauth, Ueberauth.Strategy.Steam)

    providers =
      previous_config
      |> Keyword.fetch!(:providers)
      |> then(fn providers ->
        if configured? do
          Keyword.put(
            providers,
            :steam,
            {Ueberauth.Strategy.Steam,
             [request_path: "/auth/steam", callback_path: "/auth/steam/callback"]}
          )
        else
          Keyword.delete(providers, :steam)
        end
      end)

    Application.put_env(
      :ueberauth,
      Ueberauth,
      Keyword.put(previous_config, :providers, providers)
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Steam,
      api_key: if(configured?, do: "steam-api-key")
    )

    on_exit(fn ->
      Application.put_env(:ueberauth, Ueberauth, previous_config)

      if previous_steam,
        do: Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, previous_steam),
        else: Application.delete_env(:ueberauth, Ueberauth.Strategy.Steam)
    end)
  end

  defp put_discord_oauth_config(config) do
    previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth)
    Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth, config)

    on_exit(fn ->
      case previous_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth)
        value -> Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth, value)
      end
    end)
  end

  defp put_apple_auth_config do
    previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Apple)

    Application.put_env(:ueberauth, Ueberauth.Strategy.Apple,
      client_id: "com.example.d20.web",
      team_id: "TEAM123456",
      key_id: "KEY1234567",
      private_key_base64: "test-private-key",
      callback_url: "https://accounts.example.com/auth/apple/callback"
    )

    on_exit(fn ->
      case previous_config do
        nil -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Apple)
        value -> Application.put_env(:ueberauth, Ueberauth.Strategy.Apple, value)
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

  defp game_by_bgg_id(games, bgg_id) do
    games
    |> Enum.find(&(&1.id == game_id_string(bgg_id)))
    |> Map.fetch!(:game)
  end

  defp game_id_string(bgg_id), do: bgg_id |> game_id() |> TypeID.to_string()
end
