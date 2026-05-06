defmodule D20Web.PageController do
  use D20Web, :controller

  def home(conn, _params) do
    render_inertia(conn, "home")
  end

  def dashboard(conn, _params) do
    conn
    |> assign_prop(:games, games())
    |> render_inertia("dashboard")
  end

  def cursors(conn, _params) do
    render_inertia(conn, "cursors")
  end

  defp games do
    :d20
    |> Application.fetch_env!(:games)
    |> Enum.map(fn {id, attrs} ->
      %{
        id: Atom.to_string(id),
        title: Keyword.fetch!(attrs, :title),
        embed_url: Keyword.fetch!(attrs, :embed_url)
      }
    end)
  end
end
