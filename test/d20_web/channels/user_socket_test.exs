defmodule D20Web.UserSocketTest do
  use D20Web.ChannelCase, async: true

  alias D20.Actors.Actor
  alias D20Web.UserSocket

  @uri URI.parse("http://example.com/socket/websocket")

  test "accepts a signed actor token" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: %{auth_token: token, uri: @uri})

    assert socket.assigns.current_scope.actor == actor
    assert socket.assigns.request_uri == @uri
    refute Map.has_key?(socket.assigns, :actor)
  end

  test "stores the public request URI behind a trusted TLS-terminating proxy" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    connect_info = %{
      auth_token: token,
      uri: URI.parse("http://d20.ravecat.io:80/socket/websocket?vsn=2.0.0"),
      x_headers: [{"x-forwarded-proto", "https"}, {"x-forwarded-port", "443"}]
    }

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: connect_info)

    assert URI.to_string(socket.assigns.request_uri) ==
             "https://d20.ravecat.io/socket/websocket?vsn=2.0.0"
  end

  test "rejects missing request context and invalid actor tokens" do
    assert :error = connect(UserSocket, %{})
    assert :error = connect(UserSocket, %{}, connect_info: %{auth_token: "invalid"})

    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    assert :error = connect(UserSocket, %{}, connect_info: %{auth_token: token})

    assert :error = connect(UserSocket, %{}, connect_info: %{auth_token: "invalid", uri: @uri})
  end
end
