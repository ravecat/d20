defmodule D20Web.PageController do
  use D20Web, :controller

  require Logger

  alias D20.Games
  alias D20.Games.Registry

  @typep params :: Plug.Conn.params()

  @spec home(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def home(conn, _params) do
    conn
    |> assign_games_prop()
    |> render_inertia("home")
  end

  @spec games(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def games(conn, _params) do
    redirect(conn, to: ~p"/")
  end

  @spec game(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def game(conn, %{"slug" => slug, "session" => session_id}) do
    with {:ok, game} <- D20.Games.fetch_by_slug(slug),
         {:ok, %Registry.Entry{} = entry} <- Registry.fetch(slug),
         {:ok, {session, ^slug}} <- D20.Sessions.get(session_id) do
      conn
      |> assign_prop(:slug, slug)
      |> assign_prop(:status, entry.status)
      |> assign_prop(:can_launch_game, Games.session_launch_available?(entry))
      |> assign_prop(:game, Map.from_struct(game))
      |> assign_prop(:attrs, %{})
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
    with {:ok, game} <- D20.Games.fetch_by_slug(slug),
         {:ok, %Registry.Entry{} = entry} <- Registry.fetch(slug) do
      can_launch_game = Games.session_launch_available?(entry)

      attrs =
        if can_launch_game,
          do: entry.engine |> D20.Game.changeset() |> D20.Form.to_form(),
          else: %{}

      conn
      |> assign_prop(:slug, slug)
      |> assign_prop(:status, entry.status)
      |> assign_prop(:can_launch_game, can_launch_game)
      |> assign_prop(:game, Map.from_struct(game))
      |> assign_prop(:attrs, attrs)
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
  def create_game_session(conn, %{"slug" => slug} = params) do
    actor = conn.assigns.current_scope.actor
    attrs = Map.delete(params, "slug")

    with {:ok, %Registry.Entry{} = entry} <- Registry.fetch(slug),
         :ok <- authorize_session_launch(entry),
         %Registry.Entry{engine: configured_engine} <- entry,
         {:ok, engine} <- D20.Game.ensure_engine(configured_engine),
         {:ok, session} <- D20.Sessions.create(slug, engine, actor.id, attrs) do
      conn
      |> put_status(303)
      |> redirect(to: ~p"/games/#{slug}?session=#{session.id}")
    else
      {:error, :game_not_found} ->
        send_not_found(conn)

      {:error, :session_launch_forbidden} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:forbidden, "Game sessions are unavailable.")

      {:error, %Ecto.Changeset{} = changeset} ->
        redirect_to_game_with_errors(conn, slug, changeset)

      {:error, _reason} ->
        redirect_to_game_with_error(conn, slug, "Could not start session.")
    end
  end

  @spec redirect_to_game_with_error(Plug.Conn.t(), String.t(), String.t()) :: Plug.Conn.t()
  defp redirect_to_game_with_error(conn, slug, message) do
    conn
    |> assign_errors(%{session: message})
    |> put_status(303)
    |> redirect(to: ~p"/games/#{slug}")
  end

  defp redirect_to_game_with_errors(conn, slug, changeset) do
    conn
    |> assign_errors(changeset)
    |> put_status(303)
    |> redirect(to: ~p"/games/#{slug}")
  end

  defp assign_games_prop(conn) do
    case D20.Games.list() do
      {:ok, games} ->
        assign_prop(
          conn,
          :games,
          Enum.map(games, fn %{slug: slug, status: status, game: game} ->
            %{slug: slug, status: status, game: Map.from_struct(game)}
          end)
        )

      {:error, reason} ->
        Logger.error("Failed to load game metadata: #{inspect(reason)}")
        assign_prop(conn, :games, [])
    end
  end

  defp authorize_session_launch(entry) do
    if Games.session_launch_available?(entry),
      do: :ok,
      else: {:error, :session_launch_forbidden}
  end

  @spec send_not_found(Plug.Conn.t()) :: Plug.Conn.t()
  defp send_not_found(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(:not_found, "Not Found")
  end
end
