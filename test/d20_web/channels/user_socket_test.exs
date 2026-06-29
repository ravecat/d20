defmodule D20Web.UserSocketTest do
  use D20Web.ChannelCase, async: true

  alias D20.Actors.Actor
  alias D20Web.UserSocket

  test "accepts a signed actor token" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: %{auth_token: token})

    assert socket.assigns.current_scope.actor == actor
    refute Map.has_key?(socket.assigns, :actor)
  end

  test "rejects missing or invalid actor tokens" do
    assert :error = connect(UserSocket, %{})
    assert :error = connect(UserSocket, %{}, connect_info: %{auth_token: "invalid"})
  end
end
