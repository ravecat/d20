defmodule D20Web.PageController do
  use D20Web, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
