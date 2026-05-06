defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~ ~s(id="app")
    assert inertia_component(conn) == "home"
    assert token = conn.assigns.user_token
    assert html_response(conn, 200) =~ ~s(window.userToken = "#{token}")
  end

  test "GET /dashboard renders configured games", %{conn: conn} do
    conn = get(conn, ~p"/dashboard")

    assert inertia_component(conn) == "dashboard"
    assert %{games: [game]} = inertia_props(conn)
    assert game[:id] == "qwinto"
    assert game[:title] == "Qwinto"
    assert game[:embedUrl] == "http://localhost:5173"
    assert html_response(conn, 200) =~ ~s(src="http://localhost:5174/@vite/client")
    assert html_response(conn, 200) =~ ~s(src="http://localhost:5174/js/app.js")
  end

  test "GET /cursors exposes a channel user token", %{conn: conn} do
    conn = get(conn, ~p"/cursors")

    assert inertia_component(conn) == "cursors"
    assert token = conn.assigns.user_token
    assert html_response(conn, 200) =~ ~s(window.userToken = "#{token}")
  end
end
