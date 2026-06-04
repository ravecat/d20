defmodule D20Web.SessionChannelTest do
  use D20Web.ChannelCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Sessions.Session
  alias D20Web.ModuleSocket
  alias D20Web.Presence
  alias D20Web.SessionChannel
  alias D20Web.UserSocket

  test "session topic tracks anonymous actor presence" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    actor_id = actor.id
    session_id = create_runtime_session(actor_id)

    :ok = Presence.subscribe(SessionChannel.topic(session_id))

    assert {:ok, %Session{members: %{}}, socket} = join_session_channel(session_id, actor)

    assert socket.assigns.current_scope.session == %{id: session_id}

    assert socket.assigns.current_scope.game == %{slug: "qwinto"}

    assert_receive {:join, ^actor_id, %{online_at: tracked_online_at}}

    assert_push "projection", %Session{members: members}

    assert %{online_at: ^tracked_online_at, display_name: display_name, avatar: avatar} =
             members[actor_id]

    assert is_binary(display_name)
    assert is_binary(avatar)

    assert %{^actor_id => %{metas: [%{online_at: ^tracked_online_at}]}} = Presence.list(socket)

    assert is_integer(tracked_online_at)

    assert {:ok, {session, "qwinto"}} = D20.Sessions.get(session_id)

    assert %{online_at: ^tracked_online_at, display_name: display_name, avatar: avatar} =
             session.members[actor_id]

    assert is_binary(display_name)
    assert is_binary(avatar)
  end

  test "session topic tracks authenticated actor profile by id" do
    user = user_fixture()
    actor = %{id: to_string(user.id), type: :user}
    session_id = create_runtime_session(actor.id)

    assert {:ok, %Session{members: %{}}, _socket} = join_session_channel(session_id, actor)

    assert_push "projection", %Session{members: members}

    assert %{online_at: online_at, display_name: display_name, avatar: nil} = members[actor.id]

    assert is_integer(online_at)
    assert display_name == user.email
  end

  test "session topic rejects missing sessions" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}

    assert {:error, %{reason: "session_not_found"}} =
             join_session_channel(Ecto.UUID.generate(), actor)
  end

  test "module session topic accepts signed module tokens without tracking player presence" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)

    assert {:ok, socket} = connect_module_socket(session_id, actor)

    assert socket.assigns.current_scope.actor == %Actor{id: actor.id, type: actor.type}

    assert socket.assigns.current_scope.session == %{id: session_id}

    assert socket.assigns.current_scope.game == %{slug: "qwinto"}

    refute Map.has_key?(socket.assigns, :actor)
    refute Map.has_key?(socket.assigns, :module)

    assert {:ok, %Session{id: ^session_id}, socket} =
             subscribe_and_join(socket, SessionChannel.topic(session_id), %{})

    assert socket.assigns.current_scope.session == %{id: session_id}

    assert socket.assigns.current_scope.game == %{slug: "qwinto"}

    refute_push "projection", %Session{}, 50

    assert {:ok, {%Session{members: %{}}, "qwinto"}} = D20.Sessions.get(session_id)
  end

  test "module session topic rejects tokens for another session" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)
    other_session_id = create_runtime_session(Ecto.UUID.generate())

    assert {:ok, socket} = connect_module_socket(session_id, actor)

    assert {:error, %{reason: "forbidden"}} =
             subscribe_and_join(socket, SessionChannel.topic(other_session_id), %{})
  end

  test "module session topic rejects tokens for another module" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)

    assert {:ok, socket} = connect_module_socket(session_id, actor, module_id: "missing")

    assert {:error, %{reason: "forbidden"}} =
             subscribe_and_join(socket, SessionChannel.topic(session_id), %{})
  end

  test "session command dispatches with actor id" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    actor_id = actor.id
    session_id = create_runtime_session(actor.id)
    session_ref = session_id

    assert {:ok, _session} =
             D20.Sessions.dispatch(session_scope(session_ref, "p2"), "join", %{online_at: 123})

    assert {:ok,
            %Session{
              id: ^session_id,
              phase: :waiting_for_players,
              members: %{"p2" => %{online_at: 123}}
            }, socket} = join_session_channel(session_id, actor)

    assert_push "projection", %Session{members: members}
    assert %{online_at: actor_online_at} = members[actor_id]
    assert members["p2"] == %{online_at: 123}
    assert is_integer(actor_online_at)

    ref = push(socket, "start", %{})

    assert_reply ref, :ok

    assert_push "projection", %Session{id: ^session_id, phase: :in_progress}

    assert {:ok, {session, "qwinto"}} = D20.Sessions.get(session_ref)
    assert session.phase == :in_progress
  end

  test "session command forwards unknown commands to the game engine" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)
    assert {:ok, _payload, socket} = join_session_channel(session_id, actor)

    ref = push(socket, "not_a_command", %{})

    assert_reply ref, :error, %{reason: "invalid_phase"}
  end

  test "session command rejects invalid payloads" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)
    assert {:ok, _payload, socket} = join_session_channel(session_id, actor)

    ref = push(socket, "roll", [])

    assert_reply ref, :error, %{reason: "invalid_command"}
  end

  defp create_runtime_session(owner_id) do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, owner_id)

    on_exit(fn -> D20.Sessions.stop(session.id) end)

    session.id
  end

  defp join_session_channel(session_id, actor) do
    assert {:ok, socket} = connect_user_socket(actor)

    subscribe_and_join(socket, SessionChannel.topic(session_id), %{})
  end

  defp connect_user_socket(actor) do
    token = D20.Actors.Token.sign(D20Web.Endpoint, %Actor{id: actor.id, type: actor.type})

    connect UserSocket, %{}, connect_info: %{auth_token: token}
  end

  defp session_scope(session_id, actor_id) do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game("qwinto")
  end

  defp connect_module_socket(session_id, actor, opts \\ []) do
    module_id = Keyword.get(opts, :module_id, "qwinto")

    token =
      D20.Module.Token.sign(D20Web.Endpoint, %{
        endpoint: "ws://example.com/module",
        slug: module_id,
        topic: SessionChannel.topic(session_id),
        actor: %Actor{id: actor.id, type: actor.type}
      })

    connect ModuleSocket, %{}, connect_info: %{auth_token: token}
  end
end
