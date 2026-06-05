defmodule D20.Accounts.AnonymousTest do
  use D20.DataCase, async: true

  alias D20.Accounts.Anonymous

  test "builds deterministic anonymous data from id" do
    id = Ecto.UUID.generate()

    assert Anonymous.from_id(id) == Anonymous.from_id(id)
  end

  test "keeps id as the source of truth" do
    id = Ecto.UUID.generate()

    assert %Anonymous{id: ^id, display_name: display_name, avatar: avatar} = Anonymous.from_id(id)

    assert is_binary(display_name)
    assert display_name =~ ~r/^.+ .+$/
    assert is_binary(avatar)
    assert avatar =~ "https://gravatar.com/avatar/"
    assert avatar =~ "d=robohash"
    assert avatar =~ "s=80"
    assert avatar =~ "r=g"
    assert avatar =~ "f=y"
  end

  test "generates anonymous data from a new id" do
    assert %Anonymous{id: id, display_name: display_name, avatar: avatar} = Anonymous.new()
    assert is_binary(id)
    assert {:ok, type_id} = TypeID.from_string(id)
    assert TypeID.prefix(type_id) == "anon"

    assert Anonymous.from_id(id) == %Anonymous{id: id, display_name: display_name, avatar: avatar}
  end
end
