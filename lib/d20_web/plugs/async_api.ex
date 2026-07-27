defmodule D20Web.Plugs.AsyncApi do
  @moduledoc """
  Serves an AsyncAPI specification or its standalone documentation viewer.
  """

  @behaviour Plug

  alias D20.Games.Registry

  @impl true
  def init(mode) when mode in [:raw, :reference], do: mode

  @impl true
  def call(%Plug.Conn{path_params: %{"slug" => slug}} = conn, mode)
      when mode in [:raw, :reference] do
    with {:ok, specification} <- specification(slug),
         spec_path = path(specification),
         true <- File.regular?(spec_path) do
      respond(conn, mode, specification, spec_path)
    else
      _error -> not_found(conn)
    end
  end

  defp respond(conn, :raw, _slug, spec_path) do
    case File.read(spec_path) do
      {:ok, spec} ->
        conn |> Plug.Conn.put_resp_content_type("text/yaml") |> Plug.Conn.send_resp(200, spec)

      {:error, _reason} ->
        not_found(conn)
    end
  end

  defp respond(conn, :reference, slug, _spec_path) do
    url = "/developers/specs/#{slug}/raw"
    encoded_url = Jason.encode!(url, escape: :html_safe)

    html = """
    <!doctype html>
    <html lang="en">
      <head>
        <title>AsyncAPI Reference</title>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="stylesheet" href="https://unpkg.com/@asyncapi/react-component@3.1.3/styles/default.min.css" />
        <style>
          html, body { margin: 0; min-height: 100%; }
          #asyncapi { max-width: 100vw; overflow-x: auto; }
        </style>
      </head>
      <body>
        <main id="asyncapi"></main>
        <script src="https://unpkg.com/@asyncapi/react-component@3.1.3/browser/standalone/index.js"></script>
        <script>
          AsyncApiStandalone.render({
            schema: { url: #{encoded_url} },
            config: { show: { sidebar: true } }
          }, document.getElementById("asyncapi"));
        </script>
      </body>
    </html>
    """

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, html)
  end

  defp path(slug) do
    Application.app_dir(:d20, "priv/specs/#{slug}.yaml")
  end

  defp specification("workspace"), do: {:error, :specification_not_found}

  defp specification(slug) do
    case Registry.fetch(slug) do
      {:ok, %Registry.Entry{slug: registered_slug}} -> {:ok, registered_slug}
      {:error, :game_not_found} -> {:error, :specification_not_found}
    end
  end

  defp not_found(conn) do
    Plug.Conn.send_resp(conn, :not_found, "Not found")
  end
end
