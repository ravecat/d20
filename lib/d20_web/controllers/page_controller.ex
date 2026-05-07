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

  def cursors(conn, _params) do
    render_inertia(conn, "cursors")
  end
end
