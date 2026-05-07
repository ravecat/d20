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

  def game(conn, %{"game" => game}) do
    case D20.Module.Manifest.fetch(game) do
      {:ok, module} ->
        conn
        |> assign_prop(:module, module)
        |> render_inertia("game")

      :error ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(:not_found, "Not Found")
    end
  end

  def cursors(conn, _params) do
    render_inertia(conn, "cursors")
  end
end
