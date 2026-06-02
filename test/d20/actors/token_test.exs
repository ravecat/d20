defmodule D20.Actors.TokenTest do
  use ExUnit.Case, async: true

  alias D20.Actors.Actor
  alias D20.Actors.Token

  test "verifies signed actor claims as actors" do
    actor = %Actor{id: Ecto.UUID.generate(), type: :anonymous}

    token = Token.sign(D20Web.Endpoint, actor)

    assert {:ok, ^actor} = Token.verify(D20Web.Endpoint, token)
  end

  test "rejects malformed actor claims" do
    token = Phoenix.Token.sign(D20Web.Endpoint, "actor", %{id: Ecto.UUID.generate()})

    assert {:error, :invalid_token} = Token.verify(D20Web.Endpoint, token)
  end
end
