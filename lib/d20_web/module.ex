defmodule D20Web.Module do
  @moduledoc """
  Builds iframe embed data for modules.
  """

  alias D20.Module.Manifest

  @module_socket_path "/module"

  @type entry :: %{
          required(:embed_url) => String.t(),
          required(:allowed_origins) => [String.t()],
          required(:sandbox) => [String.t()]
        }
  @type connection :: %{
          required(:endpoint) => String.t(),
          required(:topic) => String.t(),
          required(:token) => String.t()
        }

  @spec entry(Plug.Conn.t(), Manifest.entry()) :: entry()
  def entry(conn, manifest) do
    embed_url = embed_url(conn, manifest.slug)

    %{embed_url: embed_url, allowed_origins: [origin(embed_url)], sandbox: manifest.sandbox}
  end

  @spec connection(Plug.Conn.t(), String.t(), String.t()) :: connection()
  def connection(conn, slug, session_id) when is_binary(slug) and is_binary(session_id) do
    actor = conn.assigns.current_scope.actor
    endpoint = module_endpoint(conn)
    topic = D20Web.SessionChannel.topic(session_id)

    claims = %{
      endpoint: endpoint,
      topic: topic,
      slug: slug,
      actor: %{id: actor.id, type: actor.type}
    }

    %{endpoint: endpoint, topic: topic, token: D20.Module.Token.sign(D20Web.Endpoint, claims)}
  end

  @spec embed_url(Plug.Conn.t(), String.t()) :: String.t()
  defp embed_url(conn, slug) do
    conn
    |> module_uri(slug)
    |> Map.put(:path, "/")
    |> URI.to_string()
  end

  @spec origin(String.t()) :: String.t()
  defp origin(url) do
    url
    |> URI.parse()
    |> Map.put(:path, nil)
    |> Map.put(:query, nil)
    |> Map.put(:fragment, nil)
    |> Map.put(:userinfo, nil)
    |> URI.to_string()
  end

  @spec module_uri(Plug.Conn.t(), String.t()) :: URI.t()
  defp module_uri(conn, slug) do
    %URI{scheme: Atom.to_string(conn.scheme), host: "#{slug}.#{conn.host}"}
  end

  @spec module_endpoint(Plug.Conn.t()) :: String.t()
  defp module_endpoint(conn) do
    conn
    |> Plug.Conn.request_url()
    |> URI.parse()
    |> Map.put(:scheme, socket_scheme(conn))
    |> Map.put(:path, @module_socket_path)
    |> Map.put(:query, nil)
    |> URI.to_string()
  end

  defp socket_scheme(%{scheme: :https}), do: "wss"
  defp socket_scheme(_conn), do: "ws"
end
