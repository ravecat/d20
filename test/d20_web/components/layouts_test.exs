defmodule D20Web.LayoutsTest do
  use D20Web.ConnCase, async: true

  for layout <- ~w(root inertia_root) do
    test "#{layout} exposes stylesheet rules through anonymous CORS", %{conn: conn} do
      conn = put_private(conn, :phoenix_endpoint, D20Web.Endpoint)

      html =
        Phoenix.Template.render_to_string(D20Web.Layouts, unquote(layout), "html", %{
          conn: conn,
          inner_content: "Page content",
          flash: %{},
          inertia_head: []
        })

      document = LazyHTML.from_document(html)
      stylesheet = LazyHTML.query(document, ~s(link[rel="stylesheet"]))

      assert LazyHTML.attribute(stylesheet, "crossorigin") == ["anonymous"]

      assert LazyHTML.attribute(stylesheet, "href") == [
               Phoenix.VerifiedRoutes.static_url(conn, "/css/app.css")
             ]

      assert document |> LazyHTML.query(~s(script[type="module"])) |> LazyHTML.attribute("src") ==
               [
                 Phoenix.VerifiedRoutes.static_url(conn, "/@vite/client"),
                 Phoenix.VerifiedRoutes.static_url(conn, "/js/app.js")
               ]
    end
  end
end
