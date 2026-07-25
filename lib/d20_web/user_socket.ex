defmodule D20Web.UserSocket do
  use Phoenix.Socket

  alias D20.Accounts.Scope

  @forwarded_port_header "x-forwarded-port"
  @forwarded_proto_header "x-forwarded-proto"

  channel "session:*", D20Web.SessionChannel
  channel "workspace", D20Web.WorkspaceChannel

  @impl true
  def connect(_params, socket, %{auth_token: token, uri: %URI{} = uri} = connect_info)
      when is_binary(token) do
    case D20.Actors.Token.verify(socket, token) do
      {:ok, actor} ->
        request_uri = public_uri(uri, Map.get(connect_info, :x_headers, []))

        socket =
          socket
          |> assign(:current_scope, Scope.for_actor(actor))
          |> assign(:request_uri, request_uri)

        {:ok, socket}

      _ ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket) do
    actor = socket.assigns.current_scope.actor

    "user_socket:#{actor.type}:#{actor.id}"
  end

  defp public_uri(uri, headers) when is_list(headers) do
    case forwarded_scheme(headers) do
      nil ->
        uri

      scheme ->
        %{
          uri
          | authority: nil,
            scheme: scheme,
            port: forwarded_port(headers) || default_port(scheme)
        }
    end
  end

  defp public_uri(uri, _headers), do: uri

  defp forwarded_scheme(headers) do
    case forwarded_header(headers, @forwarded_proto_header) do
      scheme when scheme in ["https", "wss"] -> "https"
      "http" -> "http"
      _scheme -> nil
    end
  end

  defp forwarded_port(headers) do
    with value when byte_size(value) <= 5 <- forwarded_header(headers, @forwarded_port_header),
         {port, ""} when port in 1..65_535 <- Integer.parse(value) do
      port
    else
      _invalid -> nil
    end
  end

  defp forwarded_header(headers, name) do
    case for {^name, value} when is_binary(value) <- headers, do: value do
      [value] -> value
      _values -> nil
    end
  end

  defp default_port("https"), do: 443
  defp default_port("http"), do: 80
end
