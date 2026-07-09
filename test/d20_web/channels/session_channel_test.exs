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

  describe "session topic" do
    test "should track anonymous actor presence" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id
      session_id = create_runtime_session(actor_id)

      :ok = Presence.subscribe(SessionChannel.topic(session_id))

      assert {:ok, %{members: %{}, permissions: permissions}, socket} =
               join_session_channel(session_id, actor)

      assert permissions.can_start_game == false

      assert socket.assigns.current_scope.session == %{id: session_id}

      assert socket.assigns.current_scope.game == %{slug: "qwinto"}

      assert_receive {:join, ^actor_id, %{online_at: tracked_online_at}}

      assert_push "projection", %{members: members, permissions: permissions}

      assert permissions.can_start_game == false

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

    test "should track an authenticated actor profile by ID" do
      user = user_fixture()
      actor = %{id: to_string(user.id), type: :user}
      session_id = create_runtime_session(actor.id)

      assert {:ok, %{members: %{}, permissions: _permissions}, _socket} =
               join_session_channel(session_id, actor)

      assert_push "projection", %{members: members, permissions: _permissions}

      assert %{online_at: online_at, display_name: display_name, avatar: nil} = members[actor.id]

      assert is_integer(online_at)
      assert display_name == user.email
    end

    test "should reject missing sessions" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}

      assert {:error, %{reason: "session_not_found"}} =
               join_session_channel(Ecto.UUID.generate(), actor)
    end

    test "should track signed module token actors through presence" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id
      session_id = create_runtime_session(actor.id)

      :ok = Presence.subscribe(SessionChannel.topic(session_id))

      assert {:ok, socket} = connect_module_socket(session_id, actor)

      assert socket.assigns.current_scope.actor == %Actor{id: actor.id, type: actor.type}

      assert socket.assigns.current_scope.session == %{id: session_id}

      assert socket.assigns.current_scope.game == %{slug: "qwinto"}

      refute Map.has_key?(socket.assigns, :actor)
      refute Map.has_key?(socket.assigns, :module)

      assert {:ok, %{id: ^session_id, permissions: permissions}, socket} =
               subscribe_and_join(socket, SessionChannel.topic(session_id), %{})

      assert permissions.can_start_game == false

      assert socket.assigns.current_scope.session == %{id: session_id}

      assert socket.assigns.current_scope.game == %{slug: "qwinto"}

      assert_receive {:join, ^actor_id, %{online_at: tracked_online_at}}

      assert_push "projection", %{members: members, permissions: permissions}

      assert permissions.can_start_game == false
      assert %{online_at: ^tracked_online_at} = members[actor_id]

      assert {:ok, {%Session{members: members}, "qwinto"}} = D20.Sessions.get(session_id)
      assert %{online_at: ^tracked_online_at} = members[actor_id]
    end

    test "should reject tokens for another session" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      session_id = create_runtime_session(actor.id)
      other_session_id = create_runtime_session(Ecto.UUID.generate())

      assert {:ok, socket} = connect_module_socket(session_id, actor)

      assert {:error, %{reason: "forbidden"}} =
               subscribe_and_join(socket, SessionChannel.topic(other_session_id), %{})
    end

    test "should reject tokens for another module" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      session_id = create_runtime_session(actor.id)

      assert {:ok, socket} = connect_module_socket(session_id, actor, module_id: "missing")

      assert {:error, %{reason: "forbidden"}} =
               subscribe_and_join(socket, SessionChannel.topic(session_id), %{})
    end

    test "should dispatch commands with actor ID" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id
      session_id = create_runtime_session(actor.id)
      session_ref = session_id

      assert {:ok, _session} =
               D20.Sessions.dispatch(session_scope(session_ref, "p2"), "join", %{online_at: 123})

      assert {:ok,
              %{
                id: ^session_id,
                phase: :waiting_for_players,
                members: %{"p2" => %{online_at: 123}},
                permissions: join_permissions
              }, socket} = join_session_channel(session_id, actor)

      assert join_permissions.can_start_game == false

      assert_push "projection", %{members: members, permissions: permissions}
      assert permissions.can_start_game == true
      assert %{online_at: actor_online_at} = members[actor_id]
      assert members["p2"] == %{online_at: 123}
      assert is_integer(actor_online_at)

      ref = push(socket, "start", %{})

      assert_reply ref, :ok

      assert_push "projection", %{
        id: ^session_id,
        phase: :in_progress,
        permissions: %{can_roll: false, can_see_roll: false}
      }

      assert {:ok, {session, "qwinto"}} = D20.Sessions.get(session_ref)
      assert session.phase == :in_progress
    end

    test "should roll selected dice and push the projected result" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id
      session_id = create_runtime_session(actor.id)

      assert {:ok, _payload, socket} = join_session_channel(session_id, actor)

      assert_push "projection", %{game: %D20.Qwinto.Game{phase: :setup, order: [^actor_id]}}

      assert {:ok, _session} =
               D20.Sessions.dispatch(session_scope(session_id, "p2"), "join", %{online_at: 123})

      assert_push "projection", %{
        game: %D20.Qwinto.Game{phase: :ready, order: [^actor_id, "p2"]},
        permissions: %{can_start_game: true}
      }

      start_ref = push(socket, "start", %{})
      assert_reply start_ref, :ok

      assert_push "projection", %{
        id: ^session_id,
        phase: :in_progress,
        game: %D20.Qwinto.Game{phase: :roll, order: [^actor_id, "p2"], cursor: 0},
        permissions: %{can_roll: true, can_see_roll: false}
      }

      roll_ref = push(socket, "roll", %{"colors" => ["orange", "purple"]})
      assert_reply roll_ref, :ok

      assert_push "projection", %{
        id: ^session_id,
        phase: :in_progress,
        game: %D20.Qwinto.Game{phase: :write_or_pass, dices: dices, sum: _sum, attempt: 1},
        permissions: %{can_reroll: true, can_see_roll: true},
        available_slots: available_slots
      }

      assert MapSet.new(Map.keys(dices)) == MapSet.new([:orange, :purple])
      assert Enum.all?(Map.values(dices), &(&1 in 1..6))
      assert available_slots != []
      assert Enum.all?(available_slots, &(&1.row in [:orange, :purple]))
    end

    test "should forward unknown commands to the game engine" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      session_id = create_runtime_session(actor.id)
      assert {:ok, _payload, socket} = join_session_channel(session_id, actor)

      ref = push(socket, "not_a_command", %{})

      assert_reply ref, :error, %{reason: "invalid_phase"}
    end

    test "should route invalid payloads through session lifecycle" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      session_id = create_runtime_session(actor.id)
      assert {:ok, _payload, socket} = join_session_channel(session_id, actor)

      ref = push(socket, "roll", [])

      assert_reply ref, :error, %{reason: "invalid_phase"}
    end
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
