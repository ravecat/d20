defmodule D20.Games.PolicyTest do
  use D20.DataCase, async: true

  alias D20.Games.Policy

  import D20.AccountsFixtures

  test "permits an administrator to manage the catalog" do
    admin = %{user_fixture() | role: :admin}

    assert :ok = Bodyguard.permit(Policy, :manage_games, admin)
  end

  test "denies ordinary and anonymous callers" do
    user = user_fixture()

    assert {:error, :unauthorized} = Bodyguard.permit(Policy, :manage_games, user)
    assert {:error, :unauthorized} = Bodyguard.permit(Policy, :manage_games, nil)
  end

  test "denies unknown actions even for an administrator" do
    admin = %{user_fixture() | role: :admin}

    assert {:error, :unauthorized} = Bodyguard.permit(Policy, :manage_users, admin)
  end
end
