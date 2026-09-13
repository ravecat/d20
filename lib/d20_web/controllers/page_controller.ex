defmodule D20Web.PageController do
  use D20Web, :controller

  require Logger

  alias D20.Games
  alias D20.Games.Favorites
  alias D20.Games.Interests
  alias D20.Sessions
  alias D20Web.SessionChannel

  @typep params :: Plug.Conn.params()

  @playable_limit 8

  @spec home(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def home(conn, _params) do
    conn
    |> assign_prop(:favorites, fn ->
      Enum.map(Favorites.list(conn.assigns.current_user), & &1.bgg_id)
    end)
    |> assign_prop(:playable_games, fn ->
      {:ok, games} =
        Games.list_playable(limit: @playable_limit, order_by: [desc: :stage, asc: :id])

      Enum.map(games, &catalog_entry/1)
    end)
    |> assign_prop(:games, fn ->
      case Games.list_by_provider() do
        {:ok, games} ->
          Enum.map(games, &catalog_entry/1)

        {:error, _reason} ->
          Logger.warning(
            "Failed to discover BoardGameGeek games; showing an empty Games collection"
          )

          []
      end
    end)
    |> render_inertia("home")
  end

  defp catalog_entry(%{id: id, slug: slug, stage: stage, metadata: game}) do
    %{id: id, slug: slug, stage: stage, game: Map.from_struct(game), favorite: favorite(id, slug)}
  end

  @spec about(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def about(conn, _params) do
    render_inertia(conn, "about")
  end

  @spec contact(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def contact(conn, _params) do
    render_inertia(conn, "contact")
  end

  @spec rights_holders(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def rights_holders(conn, _params) do
    render_inertia(conn, "rights_holders")
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
    conn =
      assign_prop(conn, :favorites, fn ->
        Enum.map(Favorites.list(conn.assigns.current_user), & &1.bgg_id)
      end)

    case Games.fetch_by_slug(slug) do
      {:ok, detail} ->
        conn
        |> assign_prop(:interest, %{
          action: ~p"/games/#{slug}/interest",
          requested: Interests.requested?(conn.assigns.current_user, detail.bgg_id),
          count: Interests.count(detail.bgg_id)
        })
        |> render_game_detail(detail, slug, params["session"])

      {:error, _reason} ->
        send_not_found(conn)
    end
  end

  defp render_game_detail(conn, detail, requested_slug, session_id) do
    case Games.resolve_session(detail, session_id) do
      {:ok, session} ->
        conn = assign_prop(conn, :favorite, favorite(detail.bgg_id, requested_slug))

        render_resolved_game(conn, detail, session)

      {:error, reason} when reason in [:session_not_found, :session_game_mismatch] ->
        redirect_to_game_with_error(conn, detail.slug, "Session not found.")

      {:error, _reason} ->
        send_not_found(conn)
    end
  end

  defp render_resolved_game(conn, %{entry: nil, slug: slug, metadata: metadata}, nil) do
    conn
    |> assign_prop(:id, nil)
    |> assign_prop(:slug, slug)
    |> assign_prop(:stage, nil)
    |> assign_prop(:playable, false)
    |> assign_prop(:game, Map.from_struct(metadata))
    |> assign_prop(:schema, nil)
    |> assign_prop(:session, nil)
    |> render_inertia("game")
  end

  defp render_resolved_game(conn, %{entry: game, metadata: metadata}, session),
    do: render_game(conn, game, metadata, session)

  @spec create_game_session(Plug.Conn.t(), params()) :: Plug.Conn.t()
  def create_game_session(conn, %{"slug" => slug} = params) do
    actor = conn.assigns.scope.actor
    attrs = Map.delete(params, "slug")

    with {:ok, game} <- Games.get_by_slug(slug),
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
    playable = Games.session_launch_available?(game)

    conn
    |> assign_prop(:id, TypeID.to_string(game.id))
    |> assign_prop(:slug, game.slug)
    |> assign_prop(:stage, game.stage)
    |> assign_prop(:playable, playable)
    |> assign_prop(:game, Map.from_struct(metadata))
    |> assign_prop(:schema, fn ->
      if playable and not is_nil(game.engine) do
        game.engine |> D20.Game.changeset() |> to_schema()
      end
    end)
    |> assign_prop(
      :session,
      if(session, do: Map.put(session, :topic, SessionChannel.topic(session.id)))
    )
    |> render_inertia("game")
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

  defp favorite(bgg_id, slug) do
    %{bgg_id: bgg_id, action: ~p"/favorites/#{bgg_id}", slug: slug}
  end

  @spec send_not_found(Plug.Conn.t()) :: Plug.Conn.t()
  defp send_not_found(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(:not_found, "Not Found")
  end
end
