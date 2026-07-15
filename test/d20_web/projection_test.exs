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
                 phase: :submit,
                 round: 1,
                 turn: 1,
                 order: ["owner", "p2"],
                 roll: %{value: _value},
                 scores: %{},
                 players: %{
                   "owner" => %{
                     status: :pending,
                     badges: %{},
                     rounds: [],
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

      assert Map.keys(turn_options) |> Enum.sort() == ~w(1 2 3 4 5 6)

      rolled_option = turn_options[Integer.to_string(projection.game.roll.value)]
      assert rolled_option.volunteer_cost == 0
      assert rolled_option.actions["plant_trees"].available_cells != []
      assert rolled_option.actions["circle_tree"].available_cells != []
      refute Map.has_key?(rolled_option.actions, "rehome_koalas")
      refute Map.has_key?(rolled_option.actions, "circle_koala")
      refute Map.has_key?(rolled_option, :die_value)
      refute Map.has_key?(rolled_option, :required_cells)

      opposite_value = rem(projection.game.roll.value + 2, 6) + 1
      assert %{volunteer_cost: 3, actions: %{}} = turn_options[Integer.to_string(opposite_value)]

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

      assert %{options: %{}} = projection = Projection.render(scope, session)
      refute Map.has_key?(projection, :turn)
      refute Map.has_key?(projection, :turn_options)
      refute Map.has_key?(projection, :turn_selection)
      refute Map.has_key?(projection, :selection)
    end

    test "projects an incremental Koala selection without changing regular projections" do
      {:ok, game} = D20.Game.init(KoalaGame, %{"sheet" => "dharug"})
      {:ok, game} = dispatch_koala(game, "join", "owner")
      {:ok, game} = dispatch_koala(game, "join", "p2")
      {:ok, game} = dispatch_koala(game, "start", "owner")
      {:ok, game} = dispatch_koala(game, "roll", nil)

      value = game.roll.value

      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: game
      }

      owner_scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})
      other_scope = Scope.for_actor(%Actor{id: "p2", type: :anonymous})

      attrs = %{
        "action" => "plant_trees",
        "die_value" => value,
        "volunteers_used" => 0,
        "selected_cells" => [%{"area" => "a", "row" => 0, "column" => 0}]
      }

      assert {:ok,
              %{
                action: "plant_trees",
                die_value: ^value,
                volunteers_used: 0,
                required_cells: required_cells,
                selected_cells: [%{area: :a, row: 0, column: 0}],
                available_cells: available_cells,
                complete: false,
                bonus_options: []
              }} = Projection.render_event(owner_scope, session, "project_turn_selection", attrs)

      assert required_cells in 2..4
      assert available_cells != []
      assert session.game == game

      owner_projection = Projection.render(owner_scope, session)
      other_projection = Projection.render(other_scope, session)

      refute Map.has_key?(owner_projection, :turn)
      refute Map.has_key?(other_projection, :turn)
      refute Map.has_key?(owner_projection, :selection)
      refute Map.has_key?(other_projection, :selection)
      refute Map.has_key?(owner_projection.game.players["owner"], :turn_selection)
      refute Map.has_key?(other_projection.game.players["owner"], :turn_selection)

      invalid_attrs = %{attrs | "selected_cells" => [%{"area" => "b", "row" => 0, "column" => 0}]}

      assert {:error, :invalid_target} =
               Projection.render_event(
                 owner_scope,
                 session,
                 "project_turn_selection",
                 invalid_attrs
               )

      assert %{tree: false, koala: false} =
               other_projection.game.players["owner"].sheet.areas.a.rows
               |> Enum.at(0)
               |> Enum.at(0)
    end

    test "projects bonus options from a complete shape without committing the sheet" do
      {:ok, game} = D20.Game.init(KoalaGame, %{"sheet" => "dharug"})
      {:ok, game} = dispatch_koala(game, "join", "owner")
      {:ok, game} = dispatch_koala(game, "start", "owner")
      {:ok, game} = dispatch_koala(game, "roll", nil)

      row = Enum.map(0..3, &%{area: :a, row: 0, column: &1})

      game =
        game
        |> Map.put(:roll, %{value: 1})
        |> put_in([Access.key!(:players), "owner", Access.key!(:sheet), Access.key!(:trees)], row)
        |> put_in(
          [Access.key!(:players), "owner", Access.key!(:sheet), Access.key!(:koalas)],
          Enum.take(row, 2)
        )

      session = %Session{
        id: "session-1",
        phase: :in_progress,
        owner_id: "owner",
        members: %{},
        game: game
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      attrs = %{
        "action" => "rehome_koalas",
        "die_value" => 1,
        "volunteers_used" => 0,
        "selected_cells" => [
          %{"area" => "a", "row" => 0, "column" => 2},
          %{"area" => "a", "row" => 0, "column" => 3}
        ]
      }

      assert {:ok,
              %{
                complete: true,
                available_cells: [],
                bonus_options: [
                  %{ref: %{area: :a, axis: :row, index: 0}, bonus: %{kind: :skybridge, to: :b}}
                ]
              }} = Projection.render_event(scope, session, "project_turn_selection", attrs)

      assert game.players["owner"].sheet.koalas == Enum.take(row, 2)
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
