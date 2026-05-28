defmodule D20.Actors.ActorTest do
  use D20.DataCase, async: true

  import D20.AccountsFixtures

  alias D20.Accounts.Anonymous
  alias D20.Actors.Actor

  test "builds user actor from a registered user" do
    user = user_fixture()

    assert Actor.new(user) == %Actor{id: to_string(user.id), type: :user}
  end

  test "builds anonymous actor from anonymous profile" do
    anonymous = Anonymous.from_id("actor-1")

    assert Actor.new(anonymous) == %Actor{id: "actor-1", type: :anonymous}
  end
end
