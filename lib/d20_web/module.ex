defmodule D20Web.Module do
  @moduledoc """
  Builds iframe embed data for modules.
  """

  import Plug.Conn, only: [get_req_header: 2, put_resp_header: 3]

  alias D20.Accounts.Scope
  alias D20.Actors.Actor

  @type request_context :: %{optional(:actor) => Actor.t(), required(:uri) => URI.t()}
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

  @spec entry(Plug.Conn.t() | Phoenix.Socket.t(), D20.Games.Registry.Entry.t()) :: entry()
  def entry(source, %D20.Games.Registry.Entry{slug: slug, sandbox: sandbox}) do
    embed_url = source |> request_context() |> embed_url(slug)

    %{embed_url: embed_url, allowed_origins: [origin(embed_url)], sandbox: sandbox}
  end

  @spec connection(Plug.Conn.t() | Phoenix.Socket.t(), String.t(), String.t()) :: connection()
  def connection(source, slug, session_id) when is_binary(slug) and is_binary(session_id) do
    %{actor: actor} = context = request_context(source)
    endpoint = module_endpoint(context)
    topic = D20Web.SessionChannel.topic(session_id)

    claims = %{endpoint: endpoint, topic: topic, slug: slug, actor: actor}

    %{endpoint: endpoint, topic: topic, token: D20.Module.Token.sign(D20Web.Endpoint, claims)}
  end

  @spec put_module_cors_headers(Plug.Conn.t()) :: Plug.Conn.t()
  def put_module_cors_headers(conn) do
    case get_req_header(conn, "origin") do
      [] ->
        conn

      [origin | _] ->
        conn
        |> put_resp_header("access-control-allow-origin", origin)
        |> put_resp_header("access-control-allow-methods", "POST, OPTIONS")
        |> put_resp_header("access-control-allow-headers", "content-type")
        |> put_resp_header("access-control-allow-credentials", "true")
        |> put_resp_header("access-control-max-age", "600")
        |> put_resp_header("vary", "origin")
    end
  end

  @spec put_module_cors_headers(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def put_module_cors_headers(conn, _opts), do: put_module_cors_headers(conn)

  @spec request_context(Plug.Conn.t() | Phoenix.Socket.t()) :: request_context()
  defp request_context(%Plug.Conn{} = conn) do
    context = %{uri: conn |> Plug.Conn.request_url() |> URI.parse()}

    case conn.assigns do
      %{current_scope: %Scope{actor: %Actor{} = actor}} -> Map.put(context, :actor, actor)
      _assigns -> context
    end
  end

  defp request_context(%Phoenix.Socket{
         assigns: %{current_scope: %Scope{actor: %Actor{} = actor}, request_uri: %URI{} = uri}
       }) do
    %{actor: actor, uri: uri}
  end

  @spec embed_url(request_context(), String.t()) :: String.t()
  defp embed_url(context, slug) do
    context
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

  @spec module_uri(request_context(), String.t()) :: URI.t()
  defp module_uri(%{uri: %URI{scheme: scheme, host: host}}, slug) do
    %URI{scheme: http_scheme(scheme), host: "#{slug}.#{host}"}
  end

  @spec module_endpoint(request_context()) :: String.t()
  defp module_endpoint(%{uri: %URI{} = uri}) do
    uri
    |> Map.put(:scheme, socket_scheme(uri.scheme))
    |> Map.put(:path, "/module")
    |> Map.put(:query, nil)
    |> URI.to_string()
  end

  defp http_scheme(scheme) when scheme in ["https", "wss"], do: "https"
  defp http_scheme(_scheme), do: "http"

  defp socket_scheme(scheme) when scheme in ["https", "wss"], do: "wss"
  defp socket_scheme(_scheme), do: "ws"
end
