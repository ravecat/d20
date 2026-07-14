defmodule D20Web.ModuleControllerTest do
  use D20Web.ConnCase, async: false

  alias D20.Actors.Actor
  alias D20.Games.Registry
  alias D20.KoalaRescueClub.Game, as: KoalaGame
  alias D20.Sessions.Session

  @koala_origin "http://koala-rescue-club.example.com"

  setup do
    original_launch_config = Application.get_env(:d20, :allow_launch_in_progress, :not_configured)
    original_registry_config = Application.fetch_env!(:d20, Registry)

    on_exit(fn ->
      Application.put_env(:d20, Registry, original_registry_config)

      case original_launch_config do
        :not_configured -> Application.delete_env(:d20, :allow_launch_in_progress)
        config -> Application.put_env(:d20, :allow_launch_in_progress, config)
      end
    end)
  end

  test "POST /modules/:slug creates a module session and returns bootstrap", %{conn: conn} do
    conn =
      conn |> put_req_header("origin", @koala_origin) |> post(~p"/modules/koala-rescue-club", %{})

    assert %{
             "session" => session_id,
             "bootstrap" => %{
               "endpoint" => "ws://example.com/module",
               "topic" => topic,
               "token" => token
             }
           } = json_response(conn, 200)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    assert topic == "session:#{session_id}"
    assert get_resp_header(conn, "access-control-allow-origin") == [@koala_origin]
    assert get_resp_header(conn, "access-control-allow-methods") == ["POST, OPTIONS"]
    assert get_resp_header(conn, "access-control-allow-headers") == ["content-type"]
    assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]

    assert {:ok,
            %{
              endpoint: "ws://example.com/module",
              slug: "koala-rescue-club",
              topic: ^topic,
              actor: %Actor{id: actor_id, type: :anonymous}
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)

    assert {:ok,
            {%Session{game: %KoalaGame{sheet: :dharug, players: players}, members: members},
             "koala-rescue-club"}} = D20.Sessions.get(session_id)

    refute Map.has_key?(players, actor_id)
    refute Map.has_key?(members, actor_id)
  end

  test "POST /modules/:slug accepts creation attrs", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", @koala_origin)
      |> post(~p"/modules/koala-rescue-club", %{attrs: %{sheet: "yugambeh"}})

    assert %{"session" => session_id} = json_response(conn, 200)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    assert {:ok,
            {%Session{game: %KoalaGame{sheet: :yugambeh, players: players}}, "koala-rescue-club"}} =
             D20.Sessions.get(session_id)

    assert players == %{}
  end

  test "POST /modules/:slug returns bootstrap for an existing session", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("koala-rescue-club", KoalaGame, "owner")
    session_id = session.id
    topic = "session:#{session_id}"

    Application.put_env(:d20, :allow_launch_in_progress, false)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    conn =
      conn
      |> put_req_header("origin", @koala_origin)
      |> post(~p"/modules/koala-rescue-club", %{session: session_id})

    assert %{
             "session" => ^session_id,
             "bootstrap" => %{
               "endpoint" => "ws://example.com/module",
               "topic" => ^topic,
               "token" => token
             }
           } = json_response(conn, 200)

    assert {:ok,
            %{
              endpoint: "ws://example.com/module",
              slug: "koala-rescue-club",
              topic: ^topic,
              actor: %Actor{id: actor_id, type: :anonymous}
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)

    assert {:ok, {%Session{game: %KoalaGame{players: players}, members: members}, _slug}} =
             D20.Sessions.get(session_id)

    refute Map.has_key?(players, actor_id)
    refute Map.has_key?(members, actor_id)
  end

  test "POST /modules/:slug forbids creating an in-progress session when configured", %{
    conn: conn
  } do
    Application.put_env(:d20, :allow_launch_in_progress, false)

    Application.put_env(:d20, Registry,
      games: [
        "koala-rescue-club": [
          engine: KoalaGame,
          bgg_id: 425_873,
          sandbox: ["allow-scripts", "allow-same-origin"],
          status: :in_progress
        ]
      ]
    )

    conn =
      conn |> put_req_header("origin", @koala_origin) |> post(~p"/modules/koala-rescue-club", %{})

    assert response(conn, 403) == "Forbidden"
  end

  test "POST /modules/:slug returns 404 for a session from another game", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, "owner")

    on_exit(fn -> D20.Sessions.stop(session.id) end)

    conn =
      conn
      |> put_req_header("origin", @koala_origin)
      |> post(~p"/modules/koala-rescue-club", %{session: session.id})

    assert response(conn, 404) == "Not Found"
  end

  test "POST /modules/:slug allows any browser origin", %{conn: conn} do
    origin = "https://not-koala.example"

    conn = conn |> put_req_header("origin", origin) |> post(~p"/modules/koala-rescue-club", %{})

    assert %{"session" => session_id} = json_response(conn, 200)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    assert get_resp_header(conn, "access-control-allow-origin") == [origin]
  end

  test "OPTIONS /modules/:slug returns CORS preflight headers", %{conn: conn} do
    conn =
      conn |> put_req_header("origin", @koala_origin) |> options(~p"/modules/koala-rescue-club")

    assert response(conn, 204) == ""
    assert get_resp_header(conn, "access-control-allow-origin") == [@koala_origin]
    assert get_resp_header(conn, "access-control-allow-methods") == ["POST, OPTIONS"]
    assert get_resp_header(conn, "access-control-allow-headers") == ["content-type"]
  end
end
