defmodule D20.Module.TokenTest do
  use ExUnit.Case, async: true

  alias D20.Actors.Actor

  test "signs and verifies module claims" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}

    claims = %{
      endpoint: "ws://example.com/module",
      slug: "qwinto",
      topic: "session:#{Ecto.UUID.generate()}",
      actor: actor
    }

    token = D20.Module.Token.sign(D20Web.Endpoint, claims)

    assert {:ok, ^claims} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end

  test "rejects signed terms that are not module claims" do
    claims = %{actor_id: Ecto.UUID.generate()}

    token = D20.Module.Token.sign(D20Web.Endpoint, claims)

    assert {:error, :invalid_claims} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end
end
