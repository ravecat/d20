defmodule D20Web.SessionChannelTest do
  use D20Web.ChannelCase, async: false

  import D20.AccountsFixtures

  alias D20.Sessions.Session
  alias D20Web.ModuleSocket
  alias D20Web.Presence
  alias D20Web.SessionChannel
  alias D20Web.UserSocket

  test "page session topic tracks anonymous actor presence" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    actor_id = actor.id
    session_id = create_runtime_session(actor_id)

    :ok = Presence.subscribe(SessionChannel.topic(session_id))

    assert {:ok, %Session{members: %{}}, socket} = join_page_session_channel(session_id, actor)

    assert_receive {:join, ^actor_id, %{online_at: tracked_online_at}}

    assert_push "projection", %Session{members: members}

    assert %{
             online_at: ^tracked_online_at,
             actor_type: :anonymous,
             display_name: display_name,
             avatar: avatar
           } = members[actor_id]

    assert is_binary(display_name)
    assert is_binary(avatar)

    assert %{^actor_id => %{metas: [%{online_at: ^tracked_online_at}]}} = Presence.list(socket)

    assert is_integer(tracked_online_at)

    assert {:ok, session} = D20.Sessions.get(session_id)

    assert %{
             online_at: ^tracked_online_at,
             actor_type: :anonymous,
             display_name: display_name,
             avatar: avatar
           } = session.members[actor_id]

    assert is_binary(display_name)
    assert is_binary(avatar)
  end

  test "page session topic tracks authenticated actor profile by id" do
    user = user_fixture()
    actor = %{id: to_string(user.id), type: :user}
    session_id = create_runtime_session(actor.id)

    assert {:ok, %Session{members: %{}}, _socket} = join_page_session_channel(session_id, actor)

    assert_push "projection", %Session{members: members}

    assert %{online_at: online_at, actor_type: :user, display_name: display_name, avatar: nil} =
             members[actor.id]

    assert is_integer(online_at)
    assert display_name == user.email
  end

  test "page session topic rejects missing sessions" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}

    assert {:error, %{reason: "session_not_found"}} =
             join_page_session_channel(Ecto.UUID.generate(), actor)
  end

  test "module session topic accepts signed module tokens" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)

    assert {:ok, socket} = connect_module_socket(session_id, actor)

    assert socket.assigns.actor == actor
    assert socket.assigns.module.session_id == session_id
    assert socket.assigns.module.module_id == "qwinto"

    assert {:ok, %Session{id: ^session_id}, _socket} =
             subscribe_and_join(socket, SessionChannel.topic(session_id), %{})

    assert_push "projection", %Session{members: members}
    assert %{actor_type: :anonymous} = members[actor.id]
  end

  test "module session topic rejects tokens for another session" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)
    other_session_id = create_runtime_session(Ecto.UUID.generate())

    assert {:ok, socket} = connect_module_socket(session_id, actor)

    assert {:error, %{reason: "forbidden"}} =
             subscribe_and_join(socket, SessionChannel.topic(other_session_id), %{})
  end

  test "page session command dispatches with actor id" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    actor_id = actor.id
    session_id = create_runtime_session(actor.id)

    assert {:ok, _session} =
             D20.Sessions.dispatch(session_id, "join", %{player_id: "p2", online_at: 123})

    assert {:ok,
            %Session{
              id: ^session_id,
              phase: :waiting_for_players,
              members: %{"p2" => %{online_at: 123}}
            }, socket} = join_page_session_channel(session_id, actor)

    assert_push "projection", %Session{members: members}
    assert %{online_at: actor_online_at} = members[actor_id]
    assert members["p2"] == %{online_at: 123}
    assert is_integer(actor_online_at)

    ref = push(socket, "start", %{})

    assert_reply ref, :ok

    assert_push "projection", %Session{id: ^session_id, phase: :in_progress}

    assert {:ok, session} = D20.Sessions.get(session_id)
    assert session.phase == :in_progress
  end

  test "page session command forwards unknown commands to the game engine" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)
    assert {:ok, _payload, socket} = join_page_session_channel(session_id, actor)

    ref = push(socket, "not_a_command", %{})

    assert_reply ref, :error, %{reason: "invalid_phase"}
  end

  test "page session command rejects invalid payloads" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)
    assert {:ok, _payload, socket} = join_page_session_channel(session_id, actor)

    ref = push(socket, "roll", [])

    assert_reply ref, :error, %{reason: "invalid_command"}
  end

  defp create_runtime_session(owner_id) do
    assert {:ok, session} = D20.Sessions.create("qwinto", owner_id)

    on_exit(fn -> D20.Sessions.stop(session.id) end)

    session.id
  end

  defp join_page_session_channel(session_id, actor) do
    UserSocket
    |> socket(actor.id, %{actor: actor})
    |> subscribe_and_join(SessionChannel, SessionChannel.topic(session_id), %{})
  end

  defp connect_module_socket(session_id, actor) do
    token =
      D20.Module.Token.sign(D20Web.Endpoint, %{
        actor_id: actor.id,
        actor_type: actor.type,
        module_id: "qwinto",
        session_id: session_id
      })

    connect ModuleSocket, %{}, connect_info: %{auth_token: token}
  end
end
