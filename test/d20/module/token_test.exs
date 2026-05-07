defmodule D20.Module.TokenTest do
  use ExUnit.Case, async: true

  test "signs and verifies module claims" do
    claims = %{
      actor_id: Ecto.UUID.generate(),
      actor_type: :anonymous,
      module_id: "qwinto",
      session_id: Ecto.UUID.generate()
    }

    token = D20.Module.Token.sign(D20Web.Endpoint, claims)

    assert {:ok, ^claims} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end

  test "rejects malformed module claims" do
    token = D20.Module.Token.sign(D20Web.Endpoint, %{actor_id: Ecto.UUID.generate()})

    assert {:error, :invalid_claims} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end
end
