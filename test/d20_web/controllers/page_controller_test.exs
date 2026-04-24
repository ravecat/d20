defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ ~s(id="app")
    assert inertia_component(conn) == "home"
  end
end
