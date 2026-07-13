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
      {:ok, game} = dispatch_koala(game, "roll", "owner")

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
               turn_options: turn_options,
               game: %{
                 sheet: :dharug,
                 phase: :submit,
                 round: 1,
                 turn: 1,
                 order: ["owner", "p2"],
                 roll: %{value: _value},
                 roll_due_at: nil,
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

      a_area = projection.game.players["owner"].sheet.areas.a

      assert Enum.any?(turn_options, fn option ->
               option.volunteers_used == 0 and option.die_value == projection.game.roll.value and
                 option.shape != []
             end)

      assert Enum.all?(turn_options, &(&1.volunteers_used in 0..1))

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
