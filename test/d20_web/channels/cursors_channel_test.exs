defmodule D20Web.CursorsChannelTest do
  use D20Web.ChannelCase, async: false

  alias D20.Actors.Actor
  alias D20Web.CursorsChannel
  alias D20Web.Presence
  alias D20Web.UserSocket

  defp join_cursors_channel(actor_id) do
    UserSocket
    |> socket(actor_id, %{actor: %{id: actor_id, type: :anonymous}})
    |> subscribe_and_join(CursorsChannel, "cursors", %{})
  end

  test "socket accepts a signed actor token" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}
    token = D20.Actors.Token.sign(D20Web.Endpoint, actor)

    assert {:ok, socket} = connect(UserSocket, %{}, connect_info: %{auth_token: token})

    assert socket.assigns.actor == %{id: actor.id, type: actor.type}
  end

  test "socket rejects missing or invalid actor tokens" do
    assert :error = connect(UserSocket, %{})
    assert :error = connect(UserSocket, %{}, connect_info: %{auth_token: "invalid"})
  end

  test "after_join subscribes to presence changes and tracks actor presence" do
    actor_id = Ecto.UUID.generate()

    :ok = Presence.subscribe("cursors")
    assert {:ok, %{cursors: []}, socket} = join_cursors_channel(actor_id)
    assert_receive {:join, ^actor_id, %{online_at: tracked_online_at}}
    assert_push "projection", %{cursors: []}

    refute_push "presence_state", _
    refute_push "join", _

    assert %{^actor_id => %{metas: [%{online_at: ^tracked_online_at}]}} = Presence.list(socket)

    assert is_integer(tracked_online_at)
  end

  test "move pushes a full cursor projection" do
    sender_id = Ecto.UUID.generate()
    receiver_id = Ecto.UUID.generate()

    :ok = Presence.subscribe("cursors")
    assert {:ok, %{cursors: []}, sender} = join_cursors_channel(sender_id)
    assert {:ok, %{cursors: []}, _receiver} = join_cursors_channel(receiver_id)
    assert_receive {:join, ^sender_id, %{online_at: sender_online_at}}
    assert_receive {:join, ^receiver_id, %{online_at: receiver_online_at}}
    assert is_integer(sender_online_at)
    assert is_integer(receiver_online_at)

    refute sender_id == receiver_id

    push(sender, "move", %{"x" => 12.4, "y" => 34})

    assert_push "projection", %{cursors: [%{id: ^sender_id, x: 12, y: 34}]}

    refute_push "move", _
  end

  test "presence leave pushes a full cursor projection" do
    actor_id = Ecto.UUID.generate()

    assert {:ok, %{cursors: []}, _socket} = join_cursors_channel(actor_id)
    assert_push "projection", %{cursors: []}

    assert {:ok, %{}} =
             Presence.handle_metas(
               "cursors",
               %{joins: %{}, leaves: %{"other-actor" => %{metas: [%{}]}}},
               %{},
               %{}
             )

    assert_push "projection", %{cursors: []}
  end
end
