defmodule D20Web.SessionChannelTest do
  use D20Web.ChannelCase, async: false

  alias D20Web.ModuleSocket
  alias D20Web.SessionChannel

  test "module socket accepts scoped module token" do
    actor_id = Ecto.UUID.generate()
    assert {:ok, %{id: session_id}} = D20.Sessions.create(D20.Qwinto.Game, actor_id)

    token =
      D20.Module.Token.sign(D20Web.Endpoint, %{
        actor_id: actor_id,
        actor_type: :anonymous,
        module_id: "qwinto",
        session_id: session_id
      })

    assert {:ok, socket} = connect(ModuleSocket, %{}, connect_info: %{auth_token: token})
    assert socket.assigns.module_claims.session_id == session_id
  end

  test "module socket rejects missing or invalid module tokens" do
    assert :error = connect(ModuleSocket, %{})
    assert :error = connect(ModuleSocket, %{}, connect_info: %{auth_token: "invalid"})
  end

  test "session channel joins matching session and rejects mismatched session" do
    actor_id = Ecto.UUID.generate()
    assert {:ok, %{id: session_id}} = D20.Sessions.create(D20.Qwinto.Game, actor_id)

    socket =
      socket(ModuleSocket, actor_id, %{
        module_claims: %{
          actor_id: actor_id,
          actor_type: :anonymous,
          module_id: "qwinto",
          session_id: session_id
        }
      })

    assert {:ok, %{projection: %{game: %{phase: :setup}}}, _socket} =
             subscribe_and_join(socket, SessionChannel, "session:#{session_id}", %{})

    assert {:error, %{reason: "invalid_claim"}} =
             subscribe_and_join(socket, SessionChannel, "session:#{Ecto.UUID.generate()}", %{})
  end

  test "command pushes updated projection through the generic command event" do
    actor_id = Ecto.UUID.generate()
    assert {:ok, %{id: session_id}} = D20.Sessions.create(D20.Qwinto.Game, actor_id)

    socket =
      socket(ModuleSocket, actor_id, %{
        module_claims: %{
          actor_id: actor_id,
          actor_type: :anonymous,
          module_id: "qwinto",
          session_id: session_id
        }
      })

    assert {:ok, _reply, socket} =
             subscribe_and_join(socket, SessionChannel, "session:#{session_id}", %{})

    ref = push(socket, "command", %{"kind" => "join", "attrs" => %{}})

    assert_reply ref, :ok
    assert_push "projection", %{projection: %{game: %{players: %{^actor_id => _player}}}}
  end

  test "command rejects unknown commands" do
    actor_id = Ecto.UUID.generate()
    assert {:ok, %{id: session_id}} = D20.Sessions.create(D20.Qwinto.Game, actor_id)

    socket =
      socket(ModuleSocket, actor_id, %{
        module_claims: %{
          actor_id: actor_id,
          actor_type: :anonymous,
          module_id: "qwinto",
          session_id: session_id
        }
      })

    assert {:ok, _reply, socket} =
             subscribe_and_join(socket, SessionChannel, "session:#{session_id}", %{})

    ref = push(socket, "command", %{"kind" => "not_a_command", "attrs" => %{}})

    assert_reply ref, :error, %{reason: "unknown_command"}
  end
end
