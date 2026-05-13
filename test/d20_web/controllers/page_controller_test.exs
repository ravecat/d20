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

  test "GET /games/:slug renders metadata without creating a session", %{conn: conn} do
    conn = get(conn, ~p"/games/qwinto")

    assert inertia_component(conn) == "game"
    assert %{module: module, game: game, session: nil} = inertia_props(conn)
    assert module[:id] == "qwinto"
    assert module[:title] == "Qwinto"
    assert module[:embedUrl] == "http://localhost:5173"
    assert module[:allowedOrigins] == ["http://localhost:5173"]
    assert "allow-scripts" in module[:sandbox]
    assert game[:slug] == "qwinto"
    assert game[:externalId] == 183_006
    refute Map.has_key?(module, :bootstrap)
  end

  test "GET /games/:slug returns 404 for unknown games", %{conn: conn} do
    conn = get(conn, ~p"/games/missing")

    assert html_response(conn, 404) == "Not Found"
  end

  test "POST /games/:slug/sessions creates a session and redirects to shareable URL", %{
    conn: conn
  } do
    conn =
      conn
      |> put_req_header("x-inertia", "true")
      |> post(~p"/games/qwinto/sessions")

    assert redirected_to(conn, 303) =~ ~r"^/games/qwinto\?session="
  end

  test "POST /games/:slug/sessions redirects with errors when the engine is unavailable", %{
    conn: conn
  } do
    manifest_config = Application.fetch_env!(:d20, D20.Module.Manifest)

    Application.put_env(
      :d20,
      D20.Module.Manifest,
      Keyword.put(manifest_config, :engines, [])
    )

    on_exit(fn ->
      Application.put_env(:d20, D20.Module.Manifest, manifest_config)
    end)

    conn =
      conn
      |> put_req_header("x-inertia", "true")
      |> post(~p"/games/qwinto/sessions")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{start_session: "Game engine is not available."}
  end

  test "GET /games/:slug with a waiting session does not attach iframe bootstrap", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", "p1")
    session_id = session.id

    on_exit(fn ->
      D20.Sessions.stop(session_id)
    end)

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert %{module: module, session: session} = inertia_props(conn)
    assert session.id == session_id
    assert session.phase == :waiting_for_players
    assert session.members == %{}
    refute Map.has_key?(module, :bootstrap)
  end

  test "GET /games/:slug with an in-progress session attaches iframe bootstrap", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", "p1")
    session_id = session.id

    on_exit(fn ->
      D20.Sessions.stop(session_id)
    end)

    assert {:ok, _session} =
             D20.Sessions.dispatch(session_id, :join, %{player_id: "p2", online_at: 123})

    assert {:ok, _session} = D20.Sessions.dispatch(session_id, :start, %{player_id: "p1"})

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert %{module: module, session: session} = inertia_props(conn)
    assert session.id == session_id
    assert session.phase == :in_progress
    assert session.members == %{"p2" => %{online_at: 123}}
    assert module[:bootstrap][:moduleId] == "qwinto"
    assert module[:bootstrap][:topic] == "session:#{session_id}"
  end
end
