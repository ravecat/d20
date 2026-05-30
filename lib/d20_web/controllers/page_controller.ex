defmodule D20Web.PageController do
  use D20Web, :controller

  alias D20.Module.Manifest

  def home(conn, _params) do
    render_inertia(conn, "home")
  end

  def games(conn, _params) do
    conn
    |> assign_prop(:games, Enum.map(D20.Games.list(), &Map.from_struct/1))
    |> render_inertia("games")
  end

  def game(conn, %{"slug" => slug, "session" => session_id}) do
    with {:ok, game} <- D20.Games.fetch_by_slug(slug),
         {:ok, manifest} <- Manifest.fetch(slug),
         {:ok, session} <- D20.Sessions.get({slug, session_id}) do
      conn
      |> assign_prop(:game, Map.from_struct(game))
      |> assign_prop(:session, session)
      |> assign_prop(:module, D20Web.Module.entry(conn, manifest))
      |> assign_prop(:connection, D20Web.Module.connection(conn, slug, session.id))
      |> render_inertia("game")
    else
      {:error, :session_not_found} -> game(conn, %{"slug" => slug})
      {:error, reason} -> handle_game_error(conn, reason)
    end
  end

  def game(conn, %{"slug" => slug}) do
    with {:ok, game} <- D20.Games.fetch_by_slug(slug) do
      conn
      |> assign_prop(:game, Map.from_struct(game))
      |> assign_prop(:session, nil)
      |> assign_prop(:module, nil)
      |> assign_prop(:connection, nil)
      |> render_inertia("game")
    else
      {:error, reason} -> handle_game_error(conn, reason)
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

  defp handle_game_error(conn, reason)
       when reason in [:not_found, :game_not_found, :module_not_found, :engine_not_found] do
    send_not_found(conn)
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
