defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~ ~s(id="app")
    assert inertia_component(conn) == "home"
    assert token = conn.assigns.actor_token
    assert html_response(conn, 200) =~ ~s(window.actorToken = "#{token}")
  end

  test "GET /games renders configured modules", %{conn: conn} do
    conn = get(conn, ~p"/games")

    assert inertia_component(conn) == "games"
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

  test "GET /games/:game renders the selected game module", %{conn: conn} do
    conn = get(conn, ~p"/games/qwinto")

    assert inertia_component(conn) == "game"
    assert %{module: module} = inertia_props(conn)
    assert module[:id] == "qwinto"
    assert module[:title] == "Qwinto"
    assert module[:embedUrl] == "http://localhost:5173"
    assert module[:allowedOrigins] == ["http://localhost:5173"]
    assert "allow-scripts" in module[:sandbox]
  end

  test "GET /games/:game returns 404 for unknown games", %{conn: conn} do
    conn = get(conn, ~p"/games/missing")

    assert html_response(conn, 404) == "Not Found"
  end

  test "GET /cursors exposes a channel actor token", %{conn: conn} do
    conn = get(conn, ~p"/cursors")

    assert inertia_component(conn) == "cursors"
    assert token = conn.assigns.actor_token
    assert html_response(conn, 200) =~ ~s(window.actorToken = "#{token}")
  end
end
