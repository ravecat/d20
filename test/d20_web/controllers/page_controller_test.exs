defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~ ~s(id="app")
    assert inertia_component(conn) == "home"
    assert token = conn.assigns.actor_token
    assert html_response(conn, 200) =~ ~s(window.actorToken = "#{token}")
  end

  test "GET /dashboard renders configured modules", %{conn: conn} do
    conn = get(conn, ~p"/dashboard")

    assert inertia_component(conn) == "dashboard"
    assert %{modules: [module]} = inertia_props(conn)
    assert module[:id] == "qwinto"
    assert module[:title] == "Qwinto"
    assert module[:embedUrl] == "http://localhost:5173"
    assert module[:allowedOrigins] == ["http://localhost:5173"]
    assert "allow-scripts" in module[:sandbox]
    refute Map.has_key?(module, :transport)
    refute Map.has_key?(module, :bootstrap)
    assert html_response(conn, 200) =~ ~s(src="http://localhost:5174/@vite/client")
    assert html_response(conn, 200) =~ ~s(src="http://localhost:5174/js/app.js")
  end

  test "GET /cursors exposes a channel actor token", %{conn: conn} do
    conn = get(conn, ~p"/cursors")

    assert inertia_component(conn) == "cursors"
    assert token = conn.assigns.actor_token
    assert html_response(conn, 200) =~ ~s(window.actorToken = "#{token}")
  end
end
