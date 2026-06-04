defmodule D20Web.PageControllerTest do
  use D20Web.ConnCase

  alias D20.Accounts.Scope
  alias D20.Actors.Actor

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~ ~s(id="app")
    assert inertia_component(conn) == "home"
    assert token = conn.assigns.actor_token
    assert html_response(conn, 200) =~ ~s(window.actorToken = "#{token}")
  end

  test "GET /games renders game metadata", %{conn: conn} do
    conn = get(conn, ~p"/games")

    assert inertia_component(conn) == "games"
    assert %{games: [game]} = inertia_props(conn)
    assert game[:slug] == "qwinto"
    assert game[:name] == "Qwinto"
    assert game[:externalId] == 183_006
    refute Map.has_key?(game, :embedUrl)
    refute Map.has_key?(game, :allowedOrigins)
    refute Map.has_key?(game, :bootstrap)
  end

  test "GET /games/:slug renders metadata without creating a session", %{conn: conn} do
    conn = get(conn, ~p"/games/qwinto")

    assert inertia_component(conn) == "game"
    assert %{module: nil, connection: nil, game: game, session: nil} = inertia_props(conn)
    assert game[:slug] == "qwinto"
    assert game[:externalId] == 183_006
  end

  test "GET /games/:slug with a missing session redirects with errors", %{conn: conn} do
    session_id = Ecto.UUID.generate()

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Session not found."}
  end

  test "GET /games/:slug with a session from another game redirects with errors", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("other-game", D20.Qwinto.Game, "p1")

    on_exit(fn -> D20.Sessions.stop(session.id) end)

    conn = get(conn, ~p"/games/qwinto?session=#{session.id}")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Session not found."}
  end

  test "GET /games/:slug with a session redirects with errors when the module manifest is unavailable",
       %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, "p1")
    put_empty_module_manifest_on_exit()

    on_exit(fn -> D20.Sessions.stop(session.id) end)

    conn = get(conn, ~p"/games/qwinto?session=#{session.id}")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Game module is not available."}
  end

  test "GET /games/:slug returns 404 for unknown games", %{conn: conn} do
    conn = get(conn, ~p"/games/missing")

    assert html_response(conn, 404) == "Not Found"
  end

  test "GET /games/:slug with a session returns 404 for unknown games", %{conn: conn} do
    conn = get(conn, ~p"/games/missing?session=#{Ecto.UUID.generate()}")

    assert html_response(conn, 404) == "Not Found"
  end

  test "POST /games/:slug/sessions creates a session and redirects to shareable URL", %{
    conn: conn
  } do
    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/qwinto/sessions")

    assert redirected_to(conn, 303) =~ ~r"^/games/qwinto\?session="
  end

  test "POST /games/:slug/sessions returns 404 for unknown games", %{conn: conn} do
    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/missing/sessions")

    assert html_response(conn, 404) == "Not Found"
  end

  test "POST /games/:slug/sessions redirects with errors when the module manifest is unavailable",
       %{conn: conn} do
    put_empty_module_manifest_on_exit()

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/qwinto/sessions")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Game module is not available."}
  end

  test "POST /games/:slug/sessions redirects with errors when the engine is unavailable", %{
    conn: conn
  } do
    put_manifest_engines_on_exit([])

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/qwinto/sessions")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Game engine is not available."}
  end

  test "POST /games/:slug/sessions redirects with errors when the configured engine is invalid",
       %{conn: conn} do
    put_manifest_engines_on_exit(qwinto: String)

    conn = conn |> put_req_header("x-inertia", "true") |> post(~p"/games/qwinto/sessions")

    assert redirected_to(conn, 303) == ~p"/games/qwinto"
    assert inertia_errors(conn) == %{session: "Could not start session."}
  end

  test "GET /games/:slug with a waiting session attaches module connection", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, "p1")
    session_id = session.id
    session_ref = session_id

    on_exit(fn -> D20.Sessions.stop(session_ref) end)

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert %{module: module, connection: connection, session: session} = inertia_props(conn)
    assert session.id == session_id
    assert session.phase == :waiting_for_players
    assert session.members == %{}
    assert module[:embedUrl] == "http://qwinto.example.com/"
    assert module[:allowedOrigins] == ["http://qwinto.example.com"]
    assert "allow-scripts" in module[:sandbox]
    refute Map.has_key?(module, :bootstrap)
    refute Map.has_key?(connection, :moduleId)
    refute Map.has_key?(connection, :socketUrl)
    refute Map.has_key?(connection, :slug)
    refute Map.has_key?(connection, :actor)
    assert connection[:endpoint] == "ws://example.com/module"
    topic = "session:#{session_id}"
    assert connection[:topic] == topic

    assert {:ok,
            %{
              endpoint: "ws://example.com/module",
              slug: "qwinto",
              topic: ^topic,
              actor: %Actor{id: actor_id, type: :anonymous}
            }} = D20.Module.Token.verify(D20Web.Endpoint, connection[:token])

    assert is_binary(actor_id)
  end

  test "GET /games/:slug with an in-progress session attaches module connection", %{conn: conn} do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, "p1")
    session_id = session.id
    session_ref = session_id

    on_exit(fn -> D20.Sessions.stop(session_ref) end)

    assert {:ok, _session} =
             D20.Sessions.dispatch(session_scope(session_ref, "p2"), "join", %{online_at: 123})

    assert {:ok, _session} = D20.Sessions.dispatch(session_scope(session_ref, "p1"), "start", %{})

    conn = get(conn, ~p"/games/qwinto?session=#{session_id}")

    assert %{module: module, connection: connection, session: session} = inertia_props(conn)
    assert session.id == session_id
    assert session.phase == :in_progress
    assert session.members == %{"p2" => %{online_at: 123}}
    refute Map.has_key?(module, :bootstrap)
    refute Map.has_key?(connection, :moduleId)
    refute Map.has_key?(connection, :socketUrl)
    assert connection[:endpoint] == "ws://example.com/module"
    assert connection[:topic] == "session:#{session_id}"
  end

  defp put_empty_module_manifest_on_exit do
    manifest_config = Application.fetch_env!(:d20, D20.Module.Manifest)
    manifest_path = "tmp/empty-modules-#{System.unique_integer([:positive])}.json"
    full_manifest_path = Application.app_dir(:d20, manifest_path)

    File.mkdir_p!(Path.dirname(full_manifest_path))
    File.write!(full_manifest_path, "{}")

    Application.put_env(
      :d20,
      D20.Module.Manifest,
      Keyword.put(manifest_config, :path, manifest_path)
    )

    on_exit(fn ->
      File.rm(full_manifest_path)
      Application.put_env(:d20, D20.Module.Manifest, manifest_config)
    end)
  end

  defp put_manifest_engines_on_exit(engines) do
    manifest_config = Application.fetch_env!(:d20, D20.Module.Manifest)

    Application.put_env(
      :d20,
      D20.Module.Manifest,
      Keyword.put(manifest_config, :engines, engines)
    )

    on_exit(fn -> Application.put_env(:d20, D20.Module.Manifest, manifest_config) end)
  end

  defp session_scope(session_id, actor_id) do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game("qwinto")
  end
end
