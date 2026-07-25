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

      :ok = Presence.subscribe(session_id)

      assert {:ok, %{members: %{}, permissions: permissions}, socket} =
               join_session_channel(session_id, actor)

      assert permissions.can_start_game == false

      assert socket.assigns.scope.session == %{id: session_id}

      assert socket.assigns.scope.game == %{slug: "qwinto"}

      assert_receive {:online, ^actor_id, %{online_at: tracked_online_at}}

      assert_push "projection", %{members: members, permissions: permissions}

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

      assert_push "projection", %{members: members, permissions: permissions}

      assert permissions.can_start_game == false
      assert %{status: :online, online_at: ^tracked_online_at} = members[actor_id]

      assert {:ok, {%Session{members: members}, "qwinto"}} = D20.Sessions.get(session_id)
      assert %{status: :online, online_at: ^tracked_online_at} = members[actor_id]
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

      assert_push "projection", %{members: members, permissions: permissions}
      assert permissions.can_start_game == false
      assert %{status: :online, online_at: actor_online_at} = members[actor_id]
      refute Map.has_key?(members, "p2")
      assert is_integer(actor_online_at)

      join_ref = push(socket, "join", %{})
      assert_reply join_ref, :ok
      assert_push "projection", %{game: %D20.Qwinto.Game{order: ["p2", ^actor_id]}}

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

      assert_push "projection", %{game: %D20.Qwinto.Game{phase: :setup, order: []}}

      join_ref = push(socket, "join", %{})
      assert_reply join_ref, :ok

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

    test "should dispatch Koala selection commands and push regular projections" do
      actor = %{id: Ecto.UUID.generate(), type: :anonymous}
      actor_id = actor.id
      {session_id, rolled_session} = create_koala_submit_session(actor.id)

      assert {:ok, %{options: options, selection: nil}, socket} =
               join_session_channel(session_id, actor)

      assert options != %{}
      assert_push "projection", _presence_projection

      value = rolled_session.game.roll.value
      rulesheet = Ruleset.sheet!(rolled_session.game.sheet)
      player_sheet = rolled_session.game.players[actor.id].sheet

      [first_cell | remaining_cells] =
        rulesheet
        |> Rules.legal_shape_placements(player_sheet, "plant_trees", value)
        |> List.first()

      ref =
        push(socket, "select", %{
          "action" => "plant_trees",
          "die_value" => value,
          "volunteers_used" => 0,
          "target_cell" => first_cell
        })

      assert_reply ref, :ok

      assert_push "projection", projection

      assert %{
               selection: %{
                 action: "plant_trees",
                 die_value: ^value,
                 selected_cells: [^first_cell],
                 available_cells: available_cells,
                 complete: false
               }
             } = projection

      assert available_cells != []

      assert {:ok, {%Session{game: game}, "koala-rescue-club"}} = D20.Sessions.get(session_id)

      assert game.players[actor.id].selection == %{
               action: "plant_trees",
               value: value,
               volunteers: 0,
               cells: [first_cell]
             }

      assert {:ok,
              %{
                selection: %{
                  action: "plant_trees",
                  die_value: ^value,
                  selected_cells: [^first_cell]
                }
              }, _reconnected_socket} = join_session_channel(session_id, actor)

      legacy_submit_ref = push(socket, "submit_turn_selection", %{"bonus_actions" => []})
      assert_reply legacy_submit_ref, :error, %{reason: "invalid_phase"}
      refute_push "projection", _payload, 100

      invalid_ref =
        push(socket, "select", %{"target_cell" => %{"area" => "b", "row" => 0, "column" => 0}})

      assert_reply invalid_ref, :error, %{reason: "invalid_target"}
      refute_push "projection", _payload, 100

      reset_ref = push(socket, "reset", %{})
      assert_reply reset_ref, :ok
      assert_push "projection", %{selection: nil}
      assert_push "projection", %{selection: nil}

      select_ref =
        push(socket, "select", %{
          "action" => "plant_trees",
          "die_value" => value,
          "volunteers_used" => 0,
          "target_cell" => first_cell
        })

      assert_reply select_ref, :ok
      assert_push "projection", %{selection: %{selected_cells: [^first_cell]}}
      assert_push "projection", %{selection: %{selected_cells: [^first_cell]}}

      Enum.each(remaining_cells, fn cell ->
        select_ref = push(socket, "select", %{"target_cell" => cell})
        assert_reply select_ref, :ok
        assert_push "projection", %{selection: %{selected_cells: selected_cells}}
        assert_push "projection", %{selection: %{selected_cells: ^selected_cells}}
        assert cell in selected_cells
      end)

      submit_ref = push(socket, "submit", %{"bonus_actions" => []})
      assert_reply submit_ref, :ok

      assert_push "projection", %{
        options: %{},
        selection: nil,
        game: %{phase: :roll, turn: 2, players: %{^actor_id => %{status: :ready}}}
      }

      assert_push "projection", %{
        options: %{},
        selection: nil,
        game: %{phase: :roll, turn: 2, players: %{^actor_id => %{status: :ready}}}
      }
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
               permissions: %{can_start_game: false},
               game: %{phase: :setup, players: %{}}
             } = projection

      refute Map.has_key?(projection, :attrs)

      join_ref = push(socket, "join", %{})
      assert_reply join_ref, :ok

      assert_push "projection", %{
        permissions: %{can_start_game: true},
        game: %{phase: :ready, players: %{^actor_id => %{status: :ready}}}
      }

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
