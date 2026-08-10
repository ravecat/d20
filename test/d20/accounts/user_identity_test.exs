defmodule D20.Accounts.UserIdentityTest do
  use D20.DataCase

  alias D20.Accounts.UserIdentity

  import D20.AccountsFixtures

  describe "changeset/2" do
    setup do
      %{user: user_fixture()}
    end

    test "accepts every supported provider", %{user: user} do
      for provider <- [:google, :facebook, :apple, :discord] do
        changeset =
          UserIdentity.changeset(%UserIdentity{user_id: user.id}, %{
            provider: provider,
            provider_uid: "uid-#{provider}"
          })

        assert changeset.valid?
      end
    end

    test "requires ownership, provider, and provider UID", %{user: user} do
      changeset = UserIdentity.changeset(%UserIdentity{}, %{})

      assert errors_on(changeset) == %{
               provider: ["can't be blank"],
               provider_uid: ["can't be blank"],
               user_id: ["can't be blank"]
             }

      changeset =
        UserIdentity.changeset(%UserIdentity{user_id: user.id}, %{
          provider: :google,
          provider_uid: ""
        })

      assert %{provider_uid: ["can't be blank"]} = errors_on(changeset)
    end

    test "rejects unsupported providers", %{user: user} do
      changeset =
        UserIdentity.changeset(%UserIdentity{user_id: user.id}, %{
          provider: :github,
          provider_uid: "account-1"
        })

      assert %{provider: ["is invalid"]} = errors_on(changeset)
    end

    test "limits opaque provider UIDs to the database string capacity", %{user: user} do
      changeset =
        UserIdentity.changeset(%UserIdentity{user_id: user.id}, %{
          provider: :google,
          provider_uid: String.duplicate("a", 256)
        })

      assert "should be at most 255 character(s)" in errors_on(changeset).provider_uid
    end

    test "contains no provider credentials, claims, or profile fields" do
      assert UserIdentity.__schema__(:fields) == [
               :id,
               :provider,
               :provider_uid,
               :user_id,
               :inserted_at,
               :updated_at
             ]
    end
  end
end
