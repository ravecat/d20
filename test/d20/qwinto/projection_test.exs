defmodule D20.Qwinto.ProjectionTest do
  use ExUnit.Case, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.Qwinto.Game
  alias D20.Qwinto.Projection
  alias D20.Sessions.Session

  describe "render/2" do
    test "renders the full session payload with caller-specific fields" do
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

      assert %{
               id: "session-1",
               phase: :in_progress,
               owner_id: "owner",
               members: %{},
               game: %Game{},
               permissions: %{can_see_result: true, can_write_result: true},
               available_slots: available_slots
             } = Projection.render(scope, session)

      assert %{row: :orange, slot: 0} in available_slots
      assert %{row: :purple, slot: 8} in available_slots
      refute Enum.any?(available_slots, &(&1.row == :yellow))
    end
  end

  defp player do
    %{rows: %{orange: %{}, yellow: %{}, purple: %{}}, penalties: 0, status: :ready}
  end
end
