defmodule D20Web.PageController do
  use D20Web, :controller

  alias D20.Games.Registry

  @typep params :: Plug.Conn.params()

  @spec home(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def home(conn, _params) do
    render_inertia(conn, "home")
  end

  @spec games(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def games(conn, _params) do
    conn
    |> assign_prop(
      :games,
      Enum.map(D20.Games.list(), fn %{slug: slug, game: game} ->
        %{slug: slug, game: Map.from_struct(game)}
      end)
    )
    |> render_inertia("games")
  end

  @spec game(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def game(conn, %{"slug" => slug, "session" => session_id}) do
    with {:ok, game} <- D20.Games.fetch_by_slug(slug),
         {:ok, %Registry.Entry{} = entry} <- Registry.fetch(slug),
         {:ok, {session, ^slug}} <- D20.Sessions.get(session_id) do
      conn
      |> assign_prop(:slug, slug)
      |> assign_prop(:game, Map.from_struct(game))
      |> assign_prop(:session, session)
      |> assign_prop(:module, D20Web.Module.entry(conn, entry))
      |> assign_prop(:connection, D20Web.Module.connection(conn, slug, session.id))
      |> render_inertia("game")
    else
      {:ok, {_session, _session_slug}} ->
        redirect_to_game_with_error(conn, slug, "Session not found.")

      {:error, :session_not_found} ->
        redirect_to_game_with_error(conn, slug, "Session not found.")

      {:error, :game_not_found} ->
        send_not_found(conn)

      {:error, _reason} ->
        send_not_found(conn)
    end
  end

  def game(conn, %{"slug" => slug}) do
    with {:ok, game} <- D20.Games.fetch_by_slug(slug) do
      conn
      |> assign_prop(:slug, slug)
      |> assign_prop(:game, Map.from_struct(game))
      |> assign_prop(:session, nil)
      |> assign_prop(:module, nil)
      |> assign_prop(:connection, nil)
      |> render_inertia("game")
    else
      {:error, :game_not_found} -> send_not_found(conn)
      {:error, _reason} -> send_not_found(conn)
    end
  end

  @spec create_game_session(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def create_game_session(conn, %{"slug" => slug}) do
    actor = conn.assigns.current_scope.actor

    with {:ok, %Registry.Entry{engine: configured_engine}} <- Registry.fetch(slug),
         {:ok, engine} <- D20.Game.ensure_engine(configured_engine),
         {:ok, session} <- D20.Sessions.create(slug, engine, actor.id) do
      conn
      |> put_status(303)
      |> redirect(to: ~p"/games/#{slug}?session=#{session.id}")
    else
      {:error, :game_not_found} -> send_not_found(conn)
      {:error, _reason} -> redirect_to_game_with_error(conn, slug, "Could not start session.")
    end
  end

  @spec redirect_to_game_with_error(Plug.Conn.t(), String.t(), String.t()) :: Plug.Conn.t()
  defp redirect_to_game_with_error(conn, slug, message) do
    conn
    |> assign_errors(%{session: message})
    |> put_status(303)
    |> redirect(to: ~p"/games/#{slug}")
  end

  @spec send_not_found(Plug.Conn.t()) :: Plug.Conn.t()
  defp send_not_found(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(:not_found, "Not Found")
  end
end
