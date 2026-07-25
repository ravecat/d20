defmodule D20Web.UserSocketTest do
  use D20Web.ChannelCase, async: true

  alias D20.Actors.Actor
  alias D20Web.UserSocket

  @uri URI.parse("http://example.com/socket/websocket")

  test "accepts a signed actor token" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: %{auth_token: token, uri: @uri})

    assert socket.assigns.scope.actor == actor
    assert socket.assigns.request_uri == @uri
    refute Map.has_key?(socket.assigns, :actor)
  end

  test "stores an endpoint-normalized HTTPS request URI" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    uri = URI.parse("https://d20.ravecat.io/socket/websocket?vsn=2.0.0")
    connect_info = %{auth_token: token, uri: uri}

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: connect_info)
    assert socket.assigns.request_uri == uri
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
