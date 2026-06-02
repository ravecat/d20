defmodule D20.Accounts.ScopeTest do
  use D20.DataCase, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor

  test "returns the current actor id" do
    scope = Scope.for_actor(%Actor{id: "actor-1", type: :anonymous})

    assert Scope.actor_id(scope) == "actor-1"
  end
end
