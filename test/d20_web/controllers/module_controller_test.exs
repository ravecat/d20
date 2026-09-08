defmodule D20Web.ModuleControllerTest do
  use D20Web.ConnCase, async: false

  alias D20.Actors.Actor
  alias D20.Games
  alias D20.KoalaRescueClub.Game, as: KoalaGame
  alias D20.Sessions.Session

  setup do
    original_environment = Application.get_env(:d20, :env, :not_configured)

    on_exit(fn -> Application.put_env(:d20, :env, original_environment) end)
  end

  test "POST /modules/:game_id creates a module session and returns bootstrap", %{conn: conn} do
    game_id = game_id(425_873)
    origin = koala_origin()
    conn = conn |> put_req_header("origin", origin) |> post(~p"/modules/#{game_id}", %{})

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
    assert get_resp_header(conn, "access-control-allow-origin") == [origin]
    assert get_resp_header(conn, "access-control-allow-methods") == ["POST, OPTIONS"]
    assert get_resp_header(conn, "access-control-allow-headers") == ["content-type"]
    assert get_resp_header(conn, "access-control-allow-credentials") == ["true"]

    assert {:ok,
            %{
              endpoint: "ws://example.com/module",
              game_id: ^game_id,
              topic: ^topic,
              actor: %Actor{id: actor_id, type: :anonymous}
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)

    assert {:ok,
            {%Session{game: %KoalaGame{sheet: :dharug, players: players}, members: members},
             ^game_id}} = D20.Sessions.get(session_id)

    refute Map.has_key?(players, actor_id)
    refute Map.has_key?(members, actor_id)
  end

  test "POST /modules/:game_id accepts creation attrs", %{conn: conn} do
    game_id = game_id(425_873)

    conn =
      conn
      |> put_req_header("origin", koala_origin())
      |> post(~p"/modules/#{game_id}", %{attrs: %{sheet: "yugambeh"}})

    assert %{"session" => session_id} = json_response(conn, 200)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    assert {:ok, {%Session{game: %KoalaGame{sheet: :yugambeh, players: players}}, ^game_id}} =
             D20.Sessions.get(session_id)

    assert players == %{}
  end

  test "POST /modules/:game_id returns bootstrap for an existing session", %{conn: conn} do
    game_id = game_id(425_873)
    assert {:ok, session} = D20.Sessions.create(game_id, KoalaGame, "owner")
    session_id = session.id
    topic = "session:#{session_id}"

    Application.put_env(:d20, :env, :prod)

    {:ok, game} = Games.get(game_id)
    assert {:ok, _game} = Games.update(game, %{stage: :in_development, enabled: false})

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    conn =
      conn
      |> put_req_header("origin", koala_origin())
      |> post(~p"/modules/#{game_id}", %{session: session_id})

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
              game_id: ^game_id,
              topic: ^topic,
              actor: %Actor{id: actor_id, type: :anonymous}
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)

    assert {:ok, {%Session{game: %KoalaGame{players: players}, members: members}, _game_id}} =
             D20.Sessions.get(session_id)

    refute Map.has_key?(players, actor_id)
    refute Map.has_key?(members, actor_id)
  end

  test "POST /modules/:game_id returns bootstrap for an existing session after the game is disabled",
       %{conn: conn} do
    game_id = game_id(425_873)
    assert {:ok, session} = D20.Sessions.create(game_id, KoalaGame, "owner")
    session_id = session.id

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    {:ok, game} = Games.get(game_id)
    {:ok, _updated} = Games.update(game, %{enabled: false})

    conn =
      conn
      |> put_req_header("origin", koala_origin())
      |> post(~p"/modules/#{game_id}", %{session: session_id})

    assert %{"session" => ^session_id, "bootstrap" => %{"token" => token}} =
             json_response(conn, 200)

    assert {:ok, %{game_id: ^game_id}} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end

  test "POST /modules/:game_id forbids creating an in-development session in production", %{
    conn: conn
  } do
    Application.put_env(:d20, :env, :prod)

    game_id = game_id(425_873)
    {:ok, game} = Games.get(game_id)
    {:ok, _updated} = Games.update(game, %{stage: :in_development})

    conn = conn |> put_req_header("origin", koala_origin()) |> post(~p"/modules/#{game_id}", %{})

    assert response(conn, 403) == "Forbidden"
  end

  test "POST /modules/:game_id allows an in-development session in dev", %{conn: conn} do
    Application.put_env(:d20, :env, :dev)
    game_id = game_id(353_545)
    conn = post conn, ~p"/modules/#{game_id}", %{}
    assert %{"session" => session_id} = json_response(conn, 200)
    on_exit(fn -> D20.Sessions.stop(session_id) end)
    assert {:ok, {%Session{}, ^game_id}} = D20.Sessions.get(session_id)
  end

  test "POST /modules/:game_id returns 404 for a session from another game", %{conn: conn} do
    koala_id = game_id(425_873)
    assert {:ok, session} = D20.Sessions.create(game_id(183_006), D20.Qwinto.Game, "owner")

    on_exit(fn -> D20.Sessions.stop(session.id) end)

    conn =
      conn
      |> put_req_header("origin", koala_origin())
      |> post(~p"/modules/#{koala_id}", %{session: session.id})

    assert response(conn, 404) == "Not Found"
  end

  test "POST /modules/:game_id allows any browser origin", %{conn: conn} do
    origin = "https://not-koala.example"

    conn = conn |> put_req_header("origin", origin) |> post(~p"/modules/#{game_id(425_873)}", %{})

    assert %{"session" => session_id} = json_response(conn, 200)

    on_exit(fn -> D20.Sessions.stop(session_id) end)

    assert get_resp_header(conn, "access-control-allow-origin") == [origin]
  end

  test "OPTIONS /modules/:game_id returns CORS preflight headers", %{conn: conn} do
    origin = koala_origin()
    conn = conn |> put_req_header("origin", origin) |> options(~p"/modules/#{game_id(425_873)}")

    assert response(conn, 204) == ""
    assert get_resp_header(conn, "access-control-allow-origin") == [origin]
    assert get_resp_header(conn, "access-control-allow-methods") == ["POST, OPTIONS"]
    assert get_resp_header(conn, "access-control-allow-headers") == ["content-type"]
  end

  test "module routes distinguish missing and invalid TypeIDs", %{conn: conn} do
    missing_id = TypeID.new("game")

    assert conn |> post(~p"/modules/#{missing_id}", %{}) |> response(404) == "Not Found"
    assert_error_sent :bad_request, fn -> post conn, "/modules/not-a-typeid", %{} end
    assert_error_sent :bad_request, fn -> post conn, ~p"/modules/#{TypeID.new("user")}", %{} end
  end

  defp koala_origin do
    "http://koala-rescue-club.example.com"
  end
end
