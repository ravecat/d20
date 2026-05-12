defmodule D20Web.SessionChannelTest do
  use D20Web.ChannelCase, async: false

  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.SessionChannel
  alias D20Web.UserSocket

  test "page session topic tracks anonymous actor presence" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    actor_id = actor.id
    session_id = create_runtime_session(actor_id)

    :ok = Presence.subscribe(SessionChannel.topic(session_id))

    assert {:ok, %Session{members: %{^actor_id => :online}}, socket} =
             join_page_session_channel(session_id, actor)

    assert_receive {:join, ^actor_id}

    assert_push "projection", %Session{members: members}
    assert members[actor_id] == :online

    assert %{
             ^actor_id => %{metas: [%{online_at: tracked_online_at}]}
           } = Presence.list(socket)

    assert is_integer(tracked_online_at)

    assert {:ok, session} = D20.Sessions.get(session_id)
    assert session.members[actor_id] == :online
  end

  test "page session topic tracks authenticated actor presence by id" do
    actor = %{id: "42", type: :user}
    session_id = create_runtime_session(actor.id)

    assert {:ok, %Session{members: %{"42" => :online}}, _socket} =
             join_page_session_channel(session_id, actor)

    assert_push "projection", %Session{members: %{"42" => :online}}
  end

  test "page session topic rejects missing sessions" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}

    assert {:error, %{reason: "session_not_found"}} =
             join_page_session_channel(Ecto.UUID.generate(), actor)
  end

  test "page session command dispatches with actor id" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    actor_id = actor.id
    session_id = create_runtime_session(actor.id)
    assert {:ok, _session} = D20.Sessions.dispatch(session_id, :join, %{player_id: "p2"})

    assert {:ok,
            %Session{
              id: ^session_id,
              phase: :waiting_for_players,
              members: members
            }, socket} =
             join_page_session_channel(session_id, actor)

    assert members[actor_id] == :online

    ref = push(socket, "start", %{})

    assert_reply ref, :ok

    assert_push "projection", %Session{id: ^session_id, phase: :in_progress}

    assert {:ok, session} = D20.Sessions.get(session_id)
    assert session.phase == :in_progress
  end

  test "page session command rejects unknown commands" do
    actor = %{id: Ecto.UUID.generate(), type: :anonymous}
    session_id = create_runtime_session(actor.id)
    assert {:ok, _payload, socket} = join_page_session_channel(session_id, actor)

    ref = push(socket, "not_a_command", %{})

    assert_reply ref, :error, %{reason: "unknown_command"}
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
    session.id
  end

  defp join_page_session_channel(session_id, actor) do
    UserSocket
    |> socket(actor.id, %{actor: actor})
    |> subscribe_and_join(SessionChannel, SessionChannel.topic(session_id), %{})
  end
end
