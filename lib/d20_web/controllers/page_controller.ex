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
    with {:ok, playable_context} <- D20.Games.fetch_playable_context_by_slug(slug) do
      {module_entry, session} = resolve_session_view(conn, playable_context, params["session"])

      conn
      |> assign_prop(:module, module_entry)
      |> assign_prop(:game, Map.from_struct(playable_context.game))
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

    with {:ok, %{id: session_id}} <- D20.Games.create_session(slug, actor.id) do
      conn
      |> put_status(303)
      |> redirect(to: ~p"/games/#{slug}?session=#{session_id}")
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

  def cursors(conn, _params) do
    render_inertia(conn, "cursors")
  end

  defp resolve_session_view(conn, playable_context, session_id) when is_binary(session_id) do
    case D20.Sessions.get(session_id) do
      {:ok, %{engine: engine} = session} ->
        if engine == playable_context.engine do
          {
            maybe_put_bootstrap(conn, playable_context.module_entry, session_id, session),
            session_summary(session_id, session)
          }
        else
          {playable_context.module_entry, nil}
        end

      {:error, :session_not_found} ->
        {playable_context.module_entry, nil}
    end
  end

  defp resolve_session_view(_conn, playable_context, _session_id),
    do: {playable_context.module_entry, nil}

  defp maybe_put_bootstrap(conn, module_entry, session_id, %{phase: :in_progress}) do
    Map.put(
      module_entry,
      :bootstrap,
      D20Web.Module.bootstrap(conn, module_entry, session_id: session_id)
    )
  end

  defp maybe_put_bootstrap(_conn, module_entry, _session_id, _session), do: module_entry

  defp session_summary(session_id, session) do
    %{id: session_id, phase: Atom.to_string(session.phase)}
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
