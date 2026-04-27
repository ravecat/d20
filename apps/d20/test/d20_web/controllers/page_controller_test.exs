defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~ ~s(id="app")
    assert inertia_component(conn) == "home"
    assert token = conn.assigns.user_token
    assert html_response(conn, 200) =~ ~s(window.userToken = "#{token}")
  end

  test "GET /cursors exposes a channel user token", %{conn: conn} do
    conn = get(conn, ~p"/cursors")

    assert inertia_component(conn) == "cursors"
    assert token = conn.assigns.user_token
    assert html_response(conn, 200) =~ ~s(window.userToken = "#{token}")
  end
end
