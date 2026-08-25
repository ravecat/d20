defmodule D20.Module.TokenTest do
  use ExUnit.Case, async: true

  alias D20.Actors.Actor

  test "signs and verifies module claims" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}

    claims = %{
      endpoint: "ws://example.com/module",
      game_id: TypeID.new("game"),
      topic: "session:#{Ecto.UUID.generate()}",
      actor: actor
    }

    token = D20.Module.Token.sign(D20Web.Endpoint, claims)

    assert {:ok, ^claims} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end

  test "rejects signed terms that are not module claims" do
    claims = %{actor_id: Ecto.UUID.generate()}
    token = Phoenix.Token.sign(D20Web.Endpoint, "module", claims)

    assert {:error, :invalid_claims} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end

  test "rejects malformed and wrong-prefix game claims" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}

    for game_id <- ["not-a-typeid", TypeID.new("user") |> TypeID.to_string()] do
      token =
        Phoenix.Token.sign(D20Web.Endpoint, "module", %{
          endpoint: "ws://example.com/module",
          game_id: game_id,
          topic: "session:#{Ecto.UUID.generate()}",
          actor: actor
        })

      assert {:error, :invalid_claims} = D20.Module.Token.verify(D20Web.Endpoint, token)
    end
  end
end
