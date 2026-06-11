defmodule D20Web.ProjectionTest do
  use ExUnit.Case, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
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
               phase: :waiting_for_players,
               owner_id: "owner",
               members: %{},
               game: %Game{},
               permissions: %{can_start_game: true, can_see_result: false}
             } = Projection.render(scope, session)
    end

    test "renders an empty permissions object for sessions without a game-specific projection" do
      session = %Session{
        id: "session-1",
        phase: :waiting_for_players,
        owner_id: "owner",
        members: %{},
        game: %{phase: :ready}
      }

      scope = Scope.for_actor(%Actor{id: "owner", type: :anonymous})

      assert %{permissions: %{}} = Projection.render(scope, session)
    end
  end

  defp player do
    %{rows: %{orange: %{}, yellow: %{}, purple: %{}}, penalties: 0, status: :ready}
  end
end
