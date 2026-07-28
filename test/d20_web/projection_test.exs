defmodule D20Web.ProjectionTest do
  use ExUnit.Case, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Command
  alias D20.KoalaRescueClub.Game, as: KoalaGame
  alias D20.Qwinto.Game
  alias D20.Sessions.Session
  alias D20Web.Projection

  describe "render/2" do
    test "renders a session envelope with caller-specific Qwinto permissions" do
      session = %Session{
        id: "session-1",
        phase: :waiting_for_players,
        owner_id: "owner",
        members: %{},
        game: %Game{
          phase: :ready,
          order: ["owner", "p2"],
          players: %{"owner" => player(), "p2" => player()}
        }
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      assert %{
               id: "session-1",
               self: "owner",
               phase: :waiting_for_players,
               owner_id: "owner",
               members: %{},
               game: %Game{},
               permissions: %{can_start_game: true, can_see_roll: false},
               available_slots: []
             } = Projection.render(scope, session)
    end

    test "renders caller-specific Qwinto available slots for first-roll choice previews" do
      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: %Game{
          phase: :write_or_pass,
          order: ["owner", "p2"],
          cursor: 0,
          dices: %{orange: 4, purple: 1},
          sum: 5,
          attempt: 1,
          players: %{"owner" => player(), "p2" => player()}
        }
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      assert %{available_slots: available_slots} = Projection.render(scope, session)
      assert %{row: :orange, slot: 0} in available_slots
      assert %{row: :purple, slot: 8} in available_slots
      refute Enum.any?(available_slots, &(&1.row == :yellow))
    end

    test "renders caller-specific Qwinto available slots after reroll opens result phase" do
      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: %Game{
          phase: :result,
          order: ["owner", "p2"],
          cursor: 0,
          dices: %{orange: 4, purple: 1},
          sum: 5,
          attempt: 2,
          players: %{"owner" => player(), "p2" => player()}
        }
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      assert %{available_slots: available_slots} = Projection.render(scope, session)
      assert %{row: :orange, slot: 0} in available_slots
      assert %{row: :purple, slot: 8} in available_slots
      refute Enum.any?(available_slots, &(&1.row == :yellow))
    end

    test "renders self for non-player actors without deriving a sheet" do
      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: %Game{phase: :roll, order: ["owner"], players: %{"owner" => player()}}
      }

      scope = Scope.for_actor(%Actor{id: "spectator", type: :anonymous})

      assert %{self: "spectator", available_slots: []} = Projection.render(scope, session)
    end

    test "renders a session envelope with caller-specific Koala permissions" do
      {:ok, game} = D20.Game.init(KoalaGame, %{"sheet" => "dharug"})
      {:ok, game} = dispatch_koala(game, "join", "owner")
      {:ok, game} = dispatch_koala(game, "join", "p2")
      {:ok, game} = dispatch_koala(game, "start", "owner")
      {:ok, game} = dispatch_koala(game, "roll", nil)

      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: game
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      projection = Projection.render(scope, session)

      assert %{
               id: "session-1",
               self: "owner",
               phase: :in_progress,
               owner_id: "owner",
               members: %{},
               permissions: %{can_start_game: false, can_roll: false, can_submit_turn: true},
               options: turn_options,
               game: %{
                 sheet: :dharug,
                 mode: :multiplayer,
                 phase: :submit,
                 round: 1,
                 turn: 1,
                 roll: %{value: _value},
                 scores: %{},
                 players: %{
                   "owner" => %{
                     status: :pending,
                     badges: %{},
                     rounds: [],
                     turns: [],
                     sheet: %{
                       volunteers: [:available, :locked, :locked, :locked, :locked, :locked],
                       skybridges: [],
                       hospitals: %{hospital_2: %{size: 3, score: 2, filled: 0}},
                       bonuses: bonuses,
                       areas: %{
                         a: %{
                           accessible: true,
                           rows: [
                             [%{tree: false, koala: false} | _rest],
                             _row_1,
                             _row_2,
                             [nil | _row_3]
                           ]
                         },
                         b: %{accessible: false}
                       }
                     }
                   },
                   "p2" => %{status: :pending, sheet: %{areas: %{a: %{accessible: true}}}}
                 }
               }
             } = projection

      refute Map.has_key?(projection.game, :order)

      other_scope = Scope.for_actor(%Actor{id: "p2", type: :anonymous})
      assert %{game: %{mode: :multiplayer}} = Projection.render(other_scope, session)

      assert Map.keys(turn_options) |> Enum.sort() == ~w(1 2 3 4 5 6)

      rolled_option = turn_options[Integer.to_string(projection.game.roll.value)]
      assert rolled_option.volunteer_cost == 0
      assert rolled_option.marks.tree.available_cells != []
      refute Map.has_key?(rolled_option.marks, :koala)
      refute Map.has_key?(rolled_option, :actions)
      refute Map.has_key?(rolled_option, :die_value)
      refute Map.has_key?(rolled_option, :required_cells)

      opposite_value = rem(projection.game.roll.value + 2, 6) + 1
      assert %{volunteer_cost: 3, marks: %{}} = turn_options[Integer.to_string(opposite_value)]

      a_area = projection.game.players["owner"].sheet.areas.a

      assert %{
               ref: %{area: :a, axis: :row, index: 0},
               state: :locked,
               bonus: %{kind: :skybridge, from: :a, to: :b}
             } in bonuses

      assert %{
               ref: %{area: :a, axis: :column, index: 2},
               state: :locked,
               bonus: %{kind: :hospital}
             } in bonuses

      refute Map.has_key?(a_area, :row_bonuses)
      refute Map.has_key?(a_area, :column_bonuses)
      refute Map.has_key?(projection, :available_turn_actions)
      refute Map.has_key?(projection, :sheet_projection)
      refute Map.has_key?(projection, :turn)
      refute Map.has_key?(projection, :turn_options)
      refute Map.has_key?(projection, :turn_selection)
      refute Map.has_key?(projection, :selection)
    end

    test "renders an unset Koala mode while the roster is open" do
      {:ok, game} = D20.Game.init(KoalaGame, %{"sheet" => "dharug"})
      {:ok, game} = dispatch_koala(game, "join", "owner")

      session = %Session{
        id: "session-1",
        phase: :waiting_for_players,
        owner_id: "owner",
        members: %{},
        game: game
      }

      owner_scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})
      spectator_scope = Scope.for_actor(%Actor{id: "spectator", type: :anonymous})

      assert %{game: %{mode: nil} = owner_game} = Projection.render(owner_scope, session)
      assert %{game: %{mode: nil} = spectator_game} = Projection.render(spectator_scope, session)

      refute Map.has_key?(owner_game, :order)
      refute Map.has_key?(spectator_game, :order)
    end

    test "omits Koala player order from finished and newly rendered projections" do
      {:ok, game} = D20.Game.init(KoalaGame, %{"sheet" => "dharug"})
      {:ok, game} = dispatch_koala(game, "join", "owner")
      {:ok, game} = dispatch_koala(game, "join", "p2")
      {:ok, game} = dispatch_koala(game, "start", "owner")

      session = %Session{
        id: "session-1",
        phase: :finished,
        owner_id: "owner",
        members: %{},
        game: %{game | phase: :finished}
      }

      owner_scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})
      spectator_scope = Scope.for_actor(%Actor{id: "spectator", type: :anonymous})

      assert %{
               options: %{},
               permissions: %{can_submit_turn: false},
               game: %{players: %{"owner" => _owner, "p2" => _player_2}} = owner_game
             } = Projection.render(owner_scope, session)

      assert %{
               options: %{},
               permissions: %{can_submit_turn: false},
               game: %{players: %{"owner" => _owner, "p2" => _player_2}} = spectator_game
             } = Projection.render(spectator_scope, session)

      refute Map.has_key?(owner_game, :order)
      refute Map.has_key?(spectator_game, :order)
    end

    test "renders confirmed Koala turn history as adjusted values" do
      {:ok, game} = D20.Game.init(KoalaGame, %{"sheet" => "dharug"})
      {:ok, game} = dispatch_koala(game, "join", "owner")
      {:ok, game} = dispatch_koala(game, "join", "p2")
      {:ok, game} = dispatch_koala(game, "start", "owner")

      game =
        game
        |> put_in([Access.key!(:players), "owner", Access.key!(:turns)], [6, 1])
        |> update_in([Access.key!(:players), "p2"], &Map.delete(&1, :turns))

      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: game
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      assert %{game: %{players: %{"owner" => %{turns: [6, 1]}, "p2" => %{turns: []}}}} =
               Projection.render(scope, session)
    end

    test "renders empty top-level Koala turn fields without an active roll" do
      {:ok, game} = D20.Game.init(KoalaGame, %{"sheet" => "dharug"})
      {:ok, game} = dispatch_koala(game, "join", "owner")
      {:ok, game} = dispatch_koala(game, "start", "owner")

      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: game
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      assert %{options: %{}, game: %{mode: :solo}} =
               projection = Projection.render(scope, session)

      refute Map.has_key?(projection, :turn)
      refute Map.has_key?(projection, :turn_options)
      refute Map.has_key?(projection, :turn_selection)
      refute Map.has_key?(projection, :selection)
    end

    test "keeps stateless Koala drafts out of normal projections" do
      {:ok, game} = D20.Game.init(KoalaGame, %{"sheet" => "dharug"})
      {:ok, game} = dispatch_koala(game, "join", "owner")
      {:ok, game} = dispatch_koala(game, "join", "p2")
      {:ok, game} = dispatch_koala(game, "start", "owner")
      {:ok, game} = dispatch_koala(game, "roll", nil)

      value = game.roll.value

      assert {:ok,
              %{
                mark: :tree,
                die_value: ^value,
                selected_cells: [%{area: :a, row: 0, column: 0}],
                submit_ready: true,
                resolution: :single
              }} =
               KoalaGame.preview(game, %Command{
                 event: "draft",
                 actor_id: "owner",
                 attrs: %{
                   "mark" => "tree",
                   "die_value" => value,
                   "selected_cells" => [%{"area" => "a", "row" => 0, "column" => 0}]
                 }
               })

      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: game
      }

      owner_scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})
      other_scope = Scope.for_actor(%Actor{id: "p2", type: :anonymous})
      spectator_scope = Scope.for_actor(%Actor{id: "spectator", type: :anonymous})

      owner_projection = Projection.render(owner_scope, session)
      other_projection = Projection.render(other_scope, session)
      spectator_projection = Projection.render(spectator_scope, session)

      refute Map.has_key?(owner_projection, :turn)
      refute Map.has_key?(other_projection, :turn)
      refute Map.has_key?(owner_projection, :selection)
      refute Map.has_key?(other_projection, :selection)
      refute Map.has_key?(spectator_projection, :selection)
      assert spectator_projection.options == %{}
      refute spectator_projection.permissions.can_submit_turn
      refute Map.has_key?(owner_projection.game.players["owner"], :selection)
      refute Map.has_key?(other_projection.game.players["owner"], :selection)

      assert %{tree: false, koala: false} =
               other_projection.game.players["owner"].sheet.areas.a.rows
               |> Enum.at(0)
               |> Enum.at(0)
    end

    test "returns the session unchanged without a game-specific projection" do
      session = %Session{
        id: "session-1",
        phase: :waiting_for_players,
        owner_id: "owner",
        members: %{},
        game: %{phase: :ready}
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      assert Projection.render(scope, session) == session
    end
  end

  defp player do
    %{rows: %{orange: %{}, yellow: %{}, purple: %{}}, penalties: 0, status: :pending}
  end

  defp dispatch_koala(game, event, actor_id, attrs \\ %{}) do
    KoalaGame.dispatch(game, %Command{event: event, actor_id: actor_id, attrs: attrs})
  end
end
