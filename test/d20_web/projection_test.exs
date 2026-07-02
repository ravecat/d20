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

      assert %{
               id: "session-1",
               self: "owner",
               phase: :in_progress,
               owner_id: "owner",
               members: %{},
               game: %KoalaGame{phase: :submit},
               permissions: %{can_start_game: false, can_roll: false, can_submit_turn: true},
               available_turn_actions: [],
               sheet_projection: %{
                 areas: %{
                   a: %{
                     matrix: [
                       [%{tree: false, koala: false} | _rest],
                       _row_1,
                       _row_2,
                       [nil | _row_3]
                     ],
                     row_bonuses: [
                       %{kind: :skybridge, to_area: :b, state: :locked},
                       %{kind: :tree, state: :locked},
                       %{kind: :koala, state: :locked},
                       %{kind: :skybridge, to_area: :d, state: :locked}
                     ],
                     column_bonuses: [
                       %{kind: :tree, state: :locked},
                       %{kind: :koala, state: :locked},
                       %{kind: :hospital, state: :locked},
                       %{kind: :volunteer, state: :locked}
                     ]
                   }
                 }
               }
             } = Projection.render(scope, session)
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
