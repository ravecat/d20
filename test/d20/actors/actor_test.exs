defmodule D20.Actors.ActorTest do
  use D20.DataCase, async: true

  import D20.AccountsFixtures

  alias D20.Accounts.Anonymous
  alias D20.Actors.Actor

  test "builds user actor from a registered user" do
    user = user_fixture()

    actor = Actor.new(user)

    assert actor == %Actor{id: to_string(user.id), type: :user}
    assert {:ok, type_id} = TypeID.from_string(actor.id)
    assert TypeID.prefix(type_id) == "user"
  end

  test "builds anonymous actor from anonymous profile" do
    anonymous = Anonymous.from_id("actor-1")

    assert Actor.new(anonymous) == %Actor{id: "actor-1", type: :anonymous}
  end

  test "builds anonymous actor from a serialized anon TypeID" do
    actor = Actor.new(Anonymous.new())

    assert {:ok, type_id} = TypeID.from_string(actor.id)
    assert TypeID.prefix(type_id) == "anon"
  end
end
