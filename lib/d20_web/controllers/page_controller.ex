defmodule D20Web.PageController do
  use D20Web, :controller

  def home(conn, _params) do
    render_inertia(conn, "home")
  end

  def games(conn, _params) do
    conn
    |> assign_prop(:modules, D20.Module.Manifest.list())
    |> render_inertia("games")
  end

  def game(conn, %{"slug" => slug} = params) do
    with {:ok, game_context} <- D20.Games.fetch_context_by_slug(slug) do
      {module_manifest, session} = resolve_session_view(conn, game_context, params["session"])

      conn
      |> assign_prop(:module, module_manifest)
      |> assign_prop(:game, Map.from_struct(game_context.game))
      |> assign_prop(:session, session)
      |> render_inertia("game")
    else
      {:error, :game_not_found} -> send_not_found(conn)
      {:error, :module_not_found} -> send_not_found(conn)
      {:error, :engine_not_found} -> send_not_found(conn)
    end
  end

  def create_game_session(conn, %{"slug" => slug}) do
    actor = conn.assigns.current_scope.actor

    with {:ok, session} <- D20.Sessions.create(slug, actor.id) do
      conn
      |> put_status(303)
      |> redirect(to: ~p"/games/#{slug}?session=#{session.id}")
    else
      {:error, :game_not_found} ->
        send_not_found(conn)

      {:error, :module_not_found} ->
        redirect_with_start_error(conn, slug, "Game module is not available.")

      {:error, :engine_not_found} ->
        redirect_with_start_error(conn, slug, "Game engine is not available.")

      {:error, _reason} ->
        redirect_with_start_error(conn, slug, "Could not start session.")
    end
  end

  defp resolve_session_view(conn, game_context, session_id) when is_binary(session_id) do
    case D20.Sessions.get(session_id) do
      {:ok, %{engine: engine} = session} ->
        if engine == game_context.engine do
          {
            put_bootstrap(conn, game_context.manifest, session.id),
            session
          }
        else
          {game_context.manifest, nil}
        end

      {:error, :session_not_found} ->
        {game_context.manifest, nil}
    end
  end

  defp resolve_session_view(_conn, game_context, _session_id),
    do: {game_context.manifest, nil}

  defp put_bootstrap(conn, manifest, session_id) do
    Map.put(
      manifest,
      :bootstrap,
      D20Web.Module.bootstrap(conn, manifest, session_id: session_id)
    )
  end

  defp redirect_with_start_error(conn, slug, message) do
    conn
    |> assign_errors(%{start_session: message})
    |> put_status(303)
    |> redirect(to: ~p"/games/#{slug}")
  end

  defp send_not_found(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(:not_found, "Not Found")
  end
end
