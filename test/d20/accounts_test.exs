defmodule D20.AccountsTest do
  use D20.DataCase

  alias D20.Accounts

  import D20.AccountsFixtures
  alias D20.Accounts.User
  alias D20.Accounts.UserIdentity
  alias D20.Accounts.UserToken

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_identifier_and_password/2" do
    test "does not return the user if the identifier does not exist" do
      refute Accounts.get_user_by_identifier_and_password("unknown", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = set_password(user_fixture())
      refute Accounts.get_user_by_identifier_and_password(user.email, "invalid")
    end

    test "does not return a passwordless user" do
      user = user_fixture()

      refute Accounts.get_user_by_identifier_and_password(user.username, valid_user_password())
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = set_password(user_fixture())

      assert %User{id: ^id} =
               Accounts.get_user_by_identifier_and_password(
                 String.upcase(user.email),
                 valid_user_password()
               )
    end

    test "returns the user if the username and password are valid" do
      %{id: id} = set_password(user_fixture(username: "table_master"))

      assert %User{id: ^id} =
               Accounts.get_user_by_identifier_and_password("TABLE_MASTER", valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if user does not exist" do
      user = user_fixture()
      id = user.id
      Repo.delete!(user)

      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(id) end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "get_user/1" do
    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} = Accounts.get_user(user.id)
      assert %User{id: ^id} = Accounts.get_user(to_string(user.id))
    end

    test "returns nil for missing ids" do
      user = user_fixture()
      id = user.id
      Repo.delete!(user)

      refute Accounts.get_user(id)
    end

    test "raises for ids that cannot be cast to a user primary key" do
      assert_raise Ecto.Query.CastError, fn -> Accounts.get_user("not-a-typeid") end
    end
  end

  describe "external provider identities" do
    test "links an identity and resolves its exact owner" do
      %{id: user_id} = user = user_fixture()

      assert {:ok, %UserIdentity{} = identity} =
               Accounts.link_user_identity(user, :google, "google-account-1")

      assert identity.user_id == user.id
      assert identity.provider == :google
      assert identity.provider_uid == "google-account-1"
      assert {:ok, identity_id} = identity.id |> to_string() |> TypeID.from_string()
      assert TypeID.prefix(identity_id) == "identity"
      assert %User{id: ^user_id} = Accounts.get_user_by_identity(:google, "google-account-1")

      refute Accounts.get_user_by_identity(:google, "unknown")
      refute Accounts.get_user_by_identity(:facebook, "google-account-1")
    end

    test "returns controlled errors for invalid link data" do
      user = user_fixture()

      assert {:error, changeset} = Accounts.link_user_identity(user, :github, "account-1")
      assert %{provider: ["is invalid"]} = errors_on(changeset)

      assert {:error, changeset} = Accounts.link_user_identity(user, :google, "")
      assert %{provider_uid: ["can't be blank"]} = errors_on(changeset)
    end

    test "lists only identities owned by the user" do
      user = user_fixture()
      other_user = user_fixture()

      assert {:ok, google_identity} =
               Accounts.link_user_identity(user, :google, "google-account-1")

      assert {:ok, discord_identity} =
               Accounts.link_user_identity(user, :discord, "discord-account-1")

      assert {:ok, _other_identity} =
               Accounts.link_user_identity(other_user, :apple, "apple-account-1")

      identity_ids = user |> Accounts.list_user_identities() |> Enum.map(& &1.id) |> MapSet.new()

      assert identity_ids == MapSet.new([google_identity.id, discord_identity.id])
    end

    test "prevents one provider identity from having multiple owners" do
      user = user_fixture()
      other_user = user_fixture()

      assert {:ok, _identity} =
               Accounts.link_user_identity(user, :google, "shared-google-account")

      assert {:error, changeset} =
               Accounts.link_user_identity(other_user, :google, "shared-google-account")

      assert "has already been taken" in errors_on(changeset).provider_uid
    end

    test "prevents a user from linking two identities for one provider" do
      user = user_fixture()

      assert {:ok, _identity} = Accounts.link_user_identity(user, :discord, "discord-account-1")

      assert {:error, changeset} =
               Accounts.link_user_identity(user, :discord, "discord-account-2")

      assert "has already been taken" in errors_on(changeset).provider
    end

    test "treats equal UIDs from different providers as distinct identities" do
      user = user_fixture()

      assert {:ok, google_identity} =
               Accounts.link_user_identity(user, :google, "provider-local-account")

      assert {:ok, apple_identity} =
               Accounts.link_user_identity(user, :apple, "provider-local-account")

      assert google_identity.provider_uid == apple_identity.provider_uid
      assert google_identity.provider != apple_identity.provider
    end

    test "deletes identities with their owning user" do
      user = user_fixture()
      assert {:ok, identity} = Accounts.link_user_identity(user, :facebook, "facebook-account-1")

      Repo.delete!(user)

      refute Repo.get(UserIdentity, identity.id)
    end
  end

  describe "get_user_or_anonymous/1" do
    test "returns public profile data for registered user ids" do
      user = user_fixture()

      assert Accounts.get_user_or_anonymous(to_string(user.id)) == %{
               id: to_string(user.id),
               display_name: user.username,
               avatar: nil
             }
    end

    test "uses email as the display name for an account without a username" do
      user = user_without_username_fixture()

      assert %{display_name: display_name} = Accounts.get_user_or_anonymous(to_string(user.id))
      assert display_name == user.email
    end

    test "returns deterministic anonymous profile data for unknown actor ids" do
      id = "anon_profile_test"

      assert %{id: ^id, display_name: display_name, avatar: avatar} =
               Accounts.get_user_or_anonymous(id)

      assert is_binary(display_name)
      assert is_binary(avatar)
      assert Accounts.get_user_or_anonymous(id) == Accounts.get_user_or_anonymous(id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the uppercased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users without password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.id
      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.username)
      assert is_nil(user.password)
    end
  end

  describe "register_user_with_magic_link/2" do
    test "creates one passwordless account and confirms the same stable identity" do
      email = unique_user_email()
      parent = self()

      assert {:ok, user} =
               Accounts.register_user_with_magic_link(%{email: email}, fn token ->
                 send(parent, {:registration_token, token})
                 "https://example.com/users/log-in/#{token}"
               end)

      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert_receive {:registration_token, token}

      assert_receive {:email,
                      %Swoosh.Email{
                        from: {"D20", "noreply@d20.ravecat.io"},
                        reply_to: {"D20 Support", "support@ravecat.io"}
                      }}

      assert {:ok, {confirmed_user, _expired_tokens}} =
               Accounts.login_user_by_magic_link(token, %{username: "table_master"})

      assert confirmed_user.id == user.id
      assert confirmed_user.username == "table_master"
      assert D20.Accounts.Scope.for_actor(confirmed_user).actor.id == to_string(user.id)
    end

    test "does not send another registration email for an equivalent existing email" do
      email = unique_user_email()

      assert {:ok, _user} =
               Accounts.register_user_with_magic_link(
                 %{email: email},
                 &"https://example.com/#{&1}"
               )

      assert_receive {:email, _email}

      assert {:error, changeset} =
               Accounts.register_user_with_magic_link(
                 %{email: String.upcase(email)},
                 &"https://example.com/#{&1}"
               )

      assert "has already been taken" in errors_on(changeset).email
      assert Repo.aggregate(from(user in User, where: user.email == ^email), :count) == 1
      refute_receive {:email, _email}, 20
    end

    test "keeps the account and token when delivery fails" do
      use_mailer_adapter(D20.FailingMailerAdapter)
      email = unique_user_email()

      assert {:error, :delivery_failed} =
               Accounts.register_user_with_magic_link(
                 %{email: email},
                 &"https://example.com/#{&1}"
               )

      assert %User{confirmed_at: nil} = user = Accounts.get_user_by_email(email)
      assert Repo.get_by(UserToken, user_id: user.id, context: "login")
    end

    test "keeps the account and token when delivery times out" do
      use_mailer_adapter(D20.FailingMailerAdapter, failure_reason: :timeout)
      email = unique_user_email()

      assert {:error, :delivery_failed} =
               Accounts.register_user_with_magic_link(
                 %{email: email},
                 &"https://example.com/#{&1}"
               )

      assert %User{confirmed_at: nil} = user = Accounts.get_user_by_email(email)
      assert Repo.get_by(UserToken, user_id: user.id, context: "login")
    end

    test "database uniqueness converts competing equivalent inserts into one controlled error" do
      email = unique_user_email()

      changesets = [
        User.email_changeset(%User{}, %{email: email}),
        User.email_changeset(%User{}, %{email: String.upcase(email)})
      ]

      results =
        changesets
        |> Task.async_stream(&Repo.insert/1, max_concurrency: 2, ordered: false)
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.count(results, &match?({:ok, %User{}}, &1)) == 1
      assert [{:error, changeset}] = Enum.filter(results, &match?({:error, _}, &1))
      assert "has already been taken" in errors_on(changeset).email
      assert Repo.aggregate(from(user in User, where: user.email == ^email), :count) == 1
    end
  end

  describe "claim_username/2" do
    test "assigns a canonical username once" do
      user = user_without_username_fixture()

      assert {:ok, %User{username: "table_master"}} =
               Accounts.claim_username(user, %{username: "table_master"})

      assert {:error, changeset} = Accounts.claim_username(user, %{username: "another_name"})
      assert %{username: ["has already been set"]} = errors_on(changeset)
      assert Repo.get!(User, user.id).username == "table_master"
    end

    test "validates username syntax" do
      user = user_without_username_fixture()

      for username <- [
            "ab",
            "-player",
            "player-",
            "player name",
            "Table_Master",
            " table_master ",
            String.duplicate("a", 33)
          ] do
        assert {:error, changeset} = Accounts.claim_username(user, %{username: username})
        assert Map.has_key?(errors_on(changeset), :username)
      end

      assert is_nil(Repo.get!(User, user.id).username)
    end

    test "rejects a duplicate canonical username" do
      first_user = user_without_username_fixture()
      second_user = user_without_username_fixture()

      assert {:ok, %User{username: "table_master"}} =
               Accounts.claim_username(first_user, %{username: "table_master"})

      assert {:error, changeset} =
               Accounts.claim_username(second_user, %{username: "table_master"})

      assert "has already been taken" in errors_on(changeset).username
      assert is_nil(Repo.get!(User, second_user.id).username)
    end

    test "database uniqueness converts a case-equivalent prepared claim into a controlled error" do
      first_user = user_without_username_fixture()
      second_user = user_without_username_fixture()

      first_changeset = User.username_changeset(first_user, %{username: "shared_name"})

      second_changeset =
        second_user
        |> Ecto.Changeset.change(username: "SHARED_NAME")
        |> Ecto.Changeset.unique_constraint(:username, name: :users_username_index)

      assert first_changeset.valid?
      assert second_changeset.valid?
      assert {:ok, %User{username: "shared_name"}} = Repo.update(first_changeset)
      assert {:error, changeset} = Repo.update(second_changeset)
      assert "has already been taken" in errors_on(changeset).username
    end

    test "keeps email and password authentication available without a username" do
      user = set_password(user_without_username_fixture())

      assert %User{id: user_id} =
               Accounts.get_user_by_identifier_and_password(user.email, valid_user_password())

      assert user_id == user.id
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -11, :minute)}, -10)

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token with the configured sender headers", %{user: user} do
      assert {:ok,
              %Swoosh.Email{
                from: {"D20", "noreply@d20.ravecat.io"},
                reply_to: {"D20 Support", "support@ravecat.io"}
              } = email} =
               Accounts.deliver_user_update_email_instructions(
                 user,
                 "current@example.com",
                 &"[TOKEN]#{&1}[TOKEN]"
               )

      [_, token | _] = String.split(email.text_body, "[TOKEN]")

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_user_email(user, token) == {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{"password" => "new valid password"},
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, {user, expired_tokens}} =
        Accounts.update_user_password(user, %{password: "new valid password"})

      assert expired_tokens == []
      assert is_nil(user.password)
      assert Accounts.get_user_by_identifier_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, {_, _}} = Accounts.update_user_password(user, %{password: "new valid password"})

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"
      assert user_token.authenticated_at != nil

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      user = %{user | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == user.authenticated_at
      assert DateTime.compare(user_token.inserted_at, user.authenticated_at) == :gt
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/2" do
    test "assigns username, confirms user, and expires tokens" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, {user, [%{token: ^hashed_token}]}} =
               Accounts.login_user_by_magic_link(encoded_token, %{username: "table_master"})

      assert user.confirmed_at
      assert user.username == "table_master"
    end

    test "retains the token and unconfirmed user when username validation fails" do
      user = unconfirmed_user_fixture()
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:error, changeset} =
               Accounts.login_user_by_magic_link(encoded_token, %{username: "invalid name"})

      assert Map.has_key?(errors_on(changeset), :username)
      assert %User{confirmed_at: nil, username: nil} = Repo.get!(User, user.id)
      assert Repo.get_by(UserToken, token: hashed_token)
      assert Accounts.get_user_by_magic_link_token(encoded_token)
    end

    test "retains the token when the username is already assigned" do
      existing_user = user_fixture(username: "table_master")
      user = unconfirmed_user_fixture()
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:error, changeset} =
               Accounts.login_user_by_magic_link(encoded_token, %{username: "table_master"})

      assert "has already been taken" in errors_on(changeset).username
      assert Repo.get!(User, existing_user.id).username == "table_master"
      assert %User{confirmed_at: nil, username: nil} = Repo.get!(User, user.id)
      assert Repo.get_by(UserToken, token: hashed_token)
    end

    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, {^user, []}} = Accounts.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = unconfirmed_user_fixture()
      {1, nil} = Repo.update_all(User, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_user_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token = extract_user_token(fn url -> Accounts.deliver_login_instructions(user, url) end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  defp use_mailer_adapter(adapter, config \\ []) do
    previous_config = Application.fetch_env!(:d20, D20.Mailer)

    test_config = previous_config |> Keyword.put(:adapter, adapter) |> Keyword.merge(config)

    Application.put_env(:d20, D20.Mailer, test_config)

    on_exit(fn -> Application.put_env(:d20, D20.Mailer, previous_config) end)
  end
end
