defmodule D20Web.SessionChannelTest do
  use D20Web.ChannelCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.KoalaRescueClub.Game, as: KoalaGame
  alias D20.KoalaRescueClub.Rules
  alias D20.KoalaRescueClub.Ruleset
  alias D20.NextStationLondon.Game, as: LondonGame
  alias D20.NextStationLondon.Ruleset, as: LondonRuleset
  alias D20.Sessions.Registry, as: SessionRegistry
  alias D20.Sessions.Session
  alias D20Web.ModuleSocket
  alias D20Web.Presence
  alias D20Web.SessionChannel
  alias D20Web.UserSocket
  alias D20Web.Workspace

  describe "session topic" do
    test "should track anonymous actor presence" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id
      session_id = create_runtime_session(actor_id)

      :ok = Presence.subscribe(session_id)

      assert {:ok, %{members: %{}, permissions: permissions}, socket} =
               join_session_channel(session_id, actor)

      assert permissions.can_start_game == false

      assert socket.assigns.scope.session == %{id: session_id}

      assert socket.assigns.scope.game == %{slug: "qwinto"}

      assert [{runtime_pid, ^session_id}] = SessionRegistry.list(actor_id)
      assert Process.alive?(runtime_pid)

      assert_receive {:online, ^actor_id, %{online_at: tracked_online_at}}

      assert_push "projection", %{
        members: members,
        permissions: permissions,
        game: %D20.Qwinto.Game{order: [^actor_id]}
      }

      assert permissions.can_start_game == false

      assert %{
               status: :online,
               online_at: ^tracked_online_at,
               display_name: display_name,
               avatar: avatar
             } = members[actor_id]

      assert is_binary(display_name)
      assert is_binary(avatar)

      assert %{^actor_id => %{metas: [%{online_at: ^tracked_online_at}]}} = Presence.list(socket)

      assert is_integer(tracked_online_at)

      assert {:ok, {session, "qwinto"}} = D20.Sessions.get(session_id)

      assert %{
               status: :online,
               online_at: ^tracked_online_at,
               display_name: ^display_name,
               avatar: ^avatar
             } = session.members[actor_id]

      assert is_binary(display_name)
      assert is_binary(avatar)
    end

    test "should track an authenticated actor profile by ID" do
      user = user_fixture()
      actor = %{id: to_string(user.id), type: :user}
      session_id = create_runtime_session(actor.id)

      assert {:ok, %{members: %{}}, _socket} = join_session_channel(session_id, actor)

      assert_push "projection", %{members: members, permissions: _permissions}

      assert %{status: :online, online_at: online_at, display_name: display_name, avatar: nil} =
               members[actor.id]

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

      :ok = Presence.subscribe(session_id)

      assert {:ok, socket} = connect_module_socket(session_id, actor)

      assert socket.assigns.scope.actor == %Actor{id: actor.id, type: actor.type}

      assert socket.assigns.scope.session == %{id: session_id}

      assert socket.assigns.scope.game == %{slug: "qwinto"}

      refute Map.has_key?(socket.assigns, :actor)
      refute Map.has_key?(socket.assigns, :module)

      assert {:ok, %{id: ^session_id, permissions: permissions}, socket} =
               subscribe_and_join(socket, SessionChannel.topic(session_id), %{})

      assert permissions.can_start_game == false

      assert socket.assigns.scope.session == %{id: session_id}

      assert socket.assigns.scope.game == %{slug: "qwinto"}

      assert_receive {:online, ^actor_id, %{online_at: tracked_online_at}}

      assert_push "projection", %{
        members: members,
        permissions: permissions,
        game: %D20.Qwinto.Game{order: [^actor_id]}
      }

      assert permissions.can_start_game == false
      assert %{status: :online, online_at: ^tracked_online_at} = members[actor_id]

      assert {:ok, {%Session{members: members}, "qwinto"}} = D20.Sessions.get(session_id)
      assert %{status: :online, online_at: ^tracked_online_at} = members[actor_id]
    end

    test "leaves every matching actor channel while preserving membership and game state" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      other_actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id
      other_actor_id = other_actor.id
      session_id = create_runtime_session(actor.id)
      other_session_id = create_runtime_session(actor.id)

      assert {:ok, %Session{}} =
               D20.Sessions.dispatch(session_scope(session_id, actor.id), "join", %{})

      assert {:ok, %Session{}} =
               D20.Sessions.dispatch(session_scope(session_id, other_actor.id), "join", %{})

      assert {:ok, %Session{phase: :in_progress}} =
               D20.Sessions.dispatch(session_scope(session_id, actor.id), "start", %{})

      assert {:ok, _projection, first_socket} = join_session_channel(session_id, actor)
      assert {:ok, _projection, second_socket} = join_session_channel(session_id, actor)
      assert {:ok, _projection, other_socket} = join_session_channel(session_id, other_actor)

      assert {:ok, _projection, other_session_socket} =
               join_session_channel(other_session_id, actor)

      assert_push "projection", %{
        members: %{^actor_id => %{status: :online}, ^other_actor_id => %{status: :online}}
      }

      assert {:ok, {%Session{game: game_before}, "qwinto"}} = D20.Sessions.get(session_id)

      first_pid = first_socket.channel_pid
      second_pid = second_socket.channel_pid
      other_pid = other_socket.channel_pid
      other_session_pid = other_session_socket.channel_pid
      first_reference = Process.monitor(first_pid)
      second_reference = Process.monitor(second_pid)

      assert [{session_runtime_pid, _server}] =
               Registry.lookup(D20.Registry, {:session, session_id})

      assert [{other_session_runtime_pid, _server}] =
               Registry.lookup(D20.Registry, {:session, other_session_id})

      assert SessionRegistry.list(actor.id) |> Enum.sort() ==
               Enum.sort([
                 {session_runtime_pid, session_id},
                 {other_session_runtime_pid, other_session_id}
               ])

      assert SessionRegistry.list(other_actor.id) == [{session_runtime_pid, session_id}]

      assert :ok =
               Workspace.close_session_for_actor(session_scope(session_id, actor.id), session_id)

      assert_receive {:DOWN, ^first_reference, :process, ^first_pid, :normal}
      assert_receive {:DOWN, ^second_reference, :process, ^second_pid, :normal}
      assert Process.alive?(other_pid)
      assert Process.alive?(other_session_pid)

      assert_push "projection", %{
        members: %{^actor_id => %{status: :offline}, ^other_actor_id => %{status: :online}}
      }

      assert {:ok, {%Session{members: members, game: ^game_before}, "qwinto"}} =
               D20.Sessions.get(session_id)

      assert %{status: :offline} = members[actor.id]
      assert %{status: :online} = members[other_actor.id]
      assert [{runtime_pid, _server}] = Registry.lookup(D20.Registry, {:session, session_id})
      assert Process.alive?(runtime_pid)
      assert SessionRegistry.list(actor.id) == [{other_session_runtime_pid, other_session_id}]
      assert SessionRegistry.list(other_actor.id) == [{session_runtime_pid, session_id}]
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
                members: %{},
                permissions: join_permissions
              }, socket} = join_session_channel(session_id, actor)

      assert join_permissions.can_start_game == false

      assert_push "projection", %{
        members: members,
        permissions: permissions,
        game: %D20.Qwinto.Game{order: ["p2", ^actor_id]}
      }

      assert permissions.can_start_game == true
      assert %{status: :online, online_at: actor_online_at} = members[actor_id]
      refute Map.has_key?(members, "p2")
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

    test "should reply to Koala drafts without broadcasting and submit the complete candidate" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id
      {session_id, rolled_session} = create_koala_submit_session(actor.id)

      assert {:ok, %{options: options} = joined_projection, socket} =
               join_session_channel(session_id, actor)

      assert options != %{}
      refute Map.has_key?(joined_projection, :selection)
      assert_push "projection", _presence_projection

      value = rolled_session.game.roll.value
      rulesheet = Ruleset.sheet!(rolled_session.game.sheet)
      player_sheet = rolled_session.game.players[actor.id].sheet

      [first_cell | _remaining_cells] =
        cells =
        rulesheet |> Rules.legal_shape_placements(player_sheet, :tree, value) |> List.first()

      ref =
        push(socket, "draft", %{
          "mark" => "tree",
          "die_value" => value,
          "selected_cells" => [first_cell]
        })

      assert_reply ref, :ok, %{
        mark: :tree,
        die_value: ^value,
        selected_cells: [^first_cell],
        available_cells: available_cells,
        submit_ready: true,
        resolution: :single
      }

      assert available_cells != []
      refute_push "projection", _payload, 100

      assert {:ok, {%Session{game: unchanged_game}, "koala-rescue-club"}} =
               D20.Sessions.get(session_id)

      assert unchanged_game == rolled_session.game
      refute Map.has_key?(rolled_session.game.players[actor.id], :selection)

      for event <- ~w(select deselect reset plant_trees rehome_koalas circle_tree circle_koala) do
        legacy_ref = push(socket, event, %{})
        assert_reply legacy_ref, :error, %{reason: "unknown_command"}
        refute_push "projection", _payload, 100
      end

      invalid_ref =
        push(socket, "draft", %{
          "mark" => "tree",
          "die_value" => value,
          "selected_cells" => [%{"area" => "b", "row" => 0, "column" => 0}]
        })

      assert_reply invalid_ref, :error, %{reason: "invalid_target"}
      refute_push "projection", _payload, 100

      draft_ref =
        push(socket, "draft", %{"mark" => "tree", "die_value" => value, "selected_cells" => cells})

      assert_reply draft_ref, :ok, %{
        selected_cells: ^cells,
        submit_ready: true,
        resolution: :shape
      }

      refute_push "projection", _payload, 100

      submit_ref =
        push(socket, "submit", %{
          "mark" => "tree",
          "die_value" => value,
          "selected_cells" => cells,
          "bonus_actions" => []
        })

      assert_reply submit_ref, :ok

      assert_push "projection", projection

      assert %{
               options: %{},
               game: %{phase: :roll, turn: 2, players: %{^actor_id => %{status: :ready}}}
             } = projection

      refute Map.has_key?(projection, :selection)

      assert {:ok, reconnected_projection, _reconnected_socket} =
               join_session_channel(session_id, actor)

      refute Map.has_key?(reconnected_projection, :selection)
    end

    test "should run Next Station London through automatic preparation and explicit projections" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id

      assert {:ok, session} =
               D20.Sessions.create("next-station-london", LondonGame, actor_id, %{
                 "objectives" => true,
                 "powers" => true
               })

      on_exit(fn -> D20.Sessions.stop(session.id) end)

      assert {:ok,
              %{
                self: ^actor_id,
                objectives: [],
                powers: %{},
                members: %{},
                permissions: %{can_start_game: false},
                game: %{phase: :setup, players: %{}}
              }, socket} = join_session_channel(session.id, actor)

      assert_push "projection", projection

      assert %{
               self: ^actor_id,
               members: %{^actor_id => %{status: :online}},
               permissions: %{can_start_game: true},
               game: %{phase: :ready, players: %{^actor_id => %{status: :ready}}}
             } = projection

      refute Map.has_key?(projection, :attrs)

      start_ref = push(socket, "start", %{})

      assert_reply start_ref, :ok

      assert_push "projection", %{phase: :in_progress, game: %{phase: :preparing_round, round: 1}}

      assert_push "projection", %{
        objectives: objectives,
        powers: powers,
        permissions: %{can_draw_sections: true, can_pass: true},
        options: %{sections: sections},
        game: %{
          phase: :build,
          round: 1,
          reveals: [_first_reveal],
          players: %{^actor_id => %{current_color: current_color, status: :pending}}
        }
      }

      assert length(objectives) == 2
      assert map_size(powers) == 4
      assert current_color in LondonRuleset.colors()
      assert sections != []

      invalid_ref =
        push(socket, "draw_sections", %{"sections" => [%{"from" => "r0c0", "to" => "r0c1"}]})

      assert_reply invalid_ref, :error, %{reason: "invalid_origin"}
      refute_push "projection", _projection, 100

      pass_ref = push(socket, "pass", %{})
      assert_reply pass_ref, :ok

      assert_push "projection", %{
        game: %{phase: :build, reveals: [_, _], players: %{^actor_id => %{status: :pending}}}
      }

      spectator = %{id: Ecto.UUID.generate(), type: :anonymous}

      assert {:ok,
              %{
                self: spectator_id,
                permissions: %{can_draw_sections: false, can_pass: false},
                options: %{sections: [], power: nil},
                game: %{players: %{^actor_id => _owner_player}}
              }, _spectator_socket} = join_session_channel(session.id, spectator)

      assert spectator_id == spectator.id

      assert {:ok, %{self: ^actor_id, options: %{sections: reconnect_sections}}, _socket} =
               join_session_channel(session.id, actor)

      assert reconnect_sections != []
    end
  end

  defp create_runtime_session(owner_id) do
    assert {:ok, session} = D20.Sessions.create("qwinto", D20.Qwinto.Game, owner_id)

    on_exit(fn -> D20.Sessions.stop(session.id) end)

    session.id
  end

  defp create_koala_submit_session(owner_id) do
    assert {:ok, session} =
             D20.Sessions.create("koala-rescue-club", KoalaGame, owner_id, %{"sheet" => "dharug"})

    on_exit(fn -> D20.Sessions.stop(session.id) end)
    :ok = Phoenix.PubSub.subscribe(D20.PubSub, SessionChannel.topic(session.id))

    assert {:ok, %Session{}} =
             D20.Sessions.dispatch(
               session_scope(session.id, owner_id, "koala-rescue-club"),
               "join",
               %{}
             )

    assert_receive {:session, %Session{game: %KoalaGame{phase: :ready}}}

    assert {:ok, %Session{}} =
             D20.Sessions.dispatch(
               session_scope(session.id, owner_id, "koala-rescue-club"),
               "start",
               %{}
             )

    assert_receive {:session, %Session{game: %KoalaGame{phase: :roll}}}

    assert_receive {:session, %Session{game: %KoalaGame{phase: :submit}} = rolled_session},
                   5_000

    {session.id, rolled_session}
  end

  defp join_session_channel(session_id, actor) do
    assert {:ok, socket} = connect_user_socket(actor)

    subscribe_and_join(socket, SessionChannel.topic(session_id), %{})
  end

  defp connect_user_socket(actor) do
    token = D20.Actors.Token.sign(D20Web.Endpoint, %Actor{id: actor.id, type: actor.type})

    connect UserSocket, %{},
      connect_info: %{auth_token: token, uri: URI.parse("ws://example.com/socket/websocket")}
  end

  defp session_scope(session_id, actor_id, slug \\ "qwinto") do
    %Actor{id: actor_id, type: :anonymous}
    |> Scope.for_actor()
    |> Scope.put_session(session_id)
    |> Scope.put_game(slug)
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
