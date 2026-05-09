defmodule D20.ActorTest do
  use D20.DataCase, async: true

  import D20.AccountsFixtures

  test "builds user actor from a registered user" do
    user = user_fixture()

    assert D20.Actor.new(user) == %D20.Actor{id: to_string(user.id), type: :user}
  end

  test "builds anonymous actor from an existing id" do
    assert D20.Actor.new("actor-1") == %D20.Actor{id: "actor-1", type: :anonymous}
  end

  test "builds anonymous actor with a generated id" do
    assert %D20.Actor{id: id, type: :anonymous} = D20.Actor.new()
    assert {:ok, _} = Ecto.UUID.cast(id)
  end
end
