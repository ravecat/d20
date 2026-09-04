defmodule D20Web.PageController do
  use D20Web, :controller

  alias D20.Games
  alias D20.Games.Game
  alias D20.Sessions
  alias D20Web.SessionChannel

  @typep params :: Plug.Conn.params()

  @spec home(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def home(conn, _params) do
    conn
    |> assign_games_prop()
    |> render_inertia("home")
  end

  @spec developers(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def developers(conn, _params) do
    render_inertia(conn, "developers")
  end

  @spec games(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def games(conn, _params) do
    redirect(conn, to: ~p"/")
  end

  @spec game(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def game(conn, %{"slug" => slug} = params) do
    with {:ok, {%Game{} = game, metadata}} <- Games.fetch_by_slug(slug),
         {:ok, session} <- resolve_game_session(game, params["session"]) do
      render_game(conn, game, metadata, session)
    else
      {:error, :session_not_found} ->
        redirect_to_game_with_error(conn, slug, "Session not found.")

      {:error, :session_game_mismatch} ->
        redirect_to_game_with_error(conn, slug, "Session not found.")

      {:error, :game_not_found} ->
        send_not_found(conn)

      {:error, _reason} ->
        send_not_found(conn)
    end
  end

  @spec create_game_session(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def create_game_session(conn, %{"slug" => slug} = params) do
    actor = conn.assigns.scope.actor
    attrs = Map.delete(params, "slug")

    with {:ok, %Game{} = game} <- Games.get_by_slug(slug),
         :ok <- authorize_session_launch(game),
         {:ok, engine} <- Games.engine(game),
         {:ok, session} <- Sessions.create(game.id, engine, actor.id, attrs) do
      conn
      |> put_status(303)
      |> redirect(to: ~p"/games/#{game.slug}?session=#{session.id}")
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

  defp render_game(conn, game, metadata, session) do
    can_launch_game = Games.session_launch_available?(game)

    schema =
      if can_launch_game and not is_nil(game.engine) do
        game.engine |> D20.Game.changeset() |> to_schema()
      else
        nil
      end

    conn
    |> assign_prop(:id, TypeID.to_string(game.id))
    |> assign_prop(:slug, game.slug)
    |> assign_prop(:stage, game.stage)
    |> assign_prop(:can_launch_game, can_launch_game)
    |> assign_prop(:game, Map.from_struct(metadata))
    |> assign_prop(:schema, schema)
    |> assign_prop(:session, session)
    |> render_inertia("game")
  end

  defp assign_games_prop(conn) do
    {:ok, games} = Games.list()

    assign_prop(
      conn,
      :games,
      Enum.map(games, fn %{id: id, slug: slug, stage: stage, metadata: game} ->
        %{id: TypeID.to_string(id), slug: slug, stage: stage, game: Map.from_struct(game)}
      end)
    )
  end

  defp authorize_session_launch(game) do
    if Games.session_launch_available?(game),
      do: :ok,
      else: {:error, :session_launch_forbidden}
  end

  defp to_schema(changeset) do
    defaults = Map.take(changeset.data, Map.keys(changeset.types))

    changeset
    |> Schemecto.to_json_schema()
    |> Map.put("default", defaults)
  end

  defp resolve_game_session(_game, nil), do: {:ok, nil}

  defp resolve_game_session(%Game{id: game_id, slug: slug}, session_id) do
    case Sessions.get(session_id) do
      {:ok, {_session, ^game_id}} ->
        {:ok,
         %{
           id: session_id,
           game_id: TypeID.to_string(game_id),
           slug: slug,
           topic: SessionChannel.topic(session_id)
         }}

      {:ok, {_session, _other_game_id}} ->
        {:error, :session_game_mismatch}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec send_not_found(Plug.Conn.t()) :: Plug.Conn.t()
  defp send_not_found(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(:not_found, "Not Found")
  end
end
