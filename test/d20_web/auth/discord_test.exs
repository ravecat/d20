defmodule D20Web.Auth.DiscordTest do
  use D20Web.ConnCase, async: false

  alias D20Web.Auth.Discord

  test "derives provider availability from both runtime credentials" do
    previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth)

    on_exit(fn ->
      restore_application_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth, previous_config)
    end)

    Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth,
      client_id: "discord-client-id",
      client_secret: "discord-client-secret"
    )

    assert Discord.available?()

    for config <- [
          [client_id: nil, client_secret: "discord-client-secret"],
          [client_id: "discord-client-id", client_secret: "   "],
          []
        ] do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth, config)
      refute Discord.available?()
    end
  end

  test "normalizes only a Discord subject and transient verified email" do
    auth = discord_auth("discord-subject", "player@example.com", true)

    assert {:ok, identity} = Discord.normalize(auth)

    assert identity == %{
             provider: :discord,
             provider_uid: "discord-subject",
             email: "player@example.com",
             email_verified: true
           }

    refute Map.has_key?(identity, :credentials)
    refute Map.has_key?(identity, :raw_info)
    refute Map.has_key?(identity, :name)
  end

  test "rejects another provider and invalid subjects" do
    assert {:error, :unexpected_provider} =
             :discord
             |> discord_auth("player@example.com", true)
             |> Map.put(:provider, :facebook)
             |> Discord.normalize()

    for subject <- [nil, "", "   ", String.duplicate("a", 256)] do
      assert {:error, :invalid_provider_uid} =
               subject |> discord_auth("player@example.com", true) |> Discord.normalize()
    end
  end

  test "rejects a normalized UID that disagrees with the Discord user ID" do
    auth = discord_auth("normalized-subject", "player@example.com", true)
    auth = put_in(auth.extra.raw_info.user["id"], "different-subject")

    assert {:error, :invalid_provider_uid} = Discord.normalize(auth)
  end

  test "requires a valid verified email only for registration" do
    assert {:ok, identity} =
             "discord-subject" |> discord_auth("player@example.com", true) |> Discord.normalize()

    assert {:ok, %{provider_uid: "discord-subject", email: "player@example.com"}} =
             Discord.registration_data(identity)

    for {email, verified} <- [{nil, true}, {"not an email", true}, {"player@example.com", false}] do
      assert {:ok, invalid_identity} =
               "discord-subject" |> discord_auth(email, verified) |> Discord.normalize()

      assert {:error, _reason} = Discord.registration_data(invalid_identity)
    end
  end

  test "accepts changed or missing email data for an already linked subject" do
    assert {:ok, %{provider_uid: "linked-subject", email: nil, email_verified: false}} =
             "linked-subject" |> discord_auth(nil, false) |> Discord.normalize()
  end

  test "stores, validates, and consumes signed-session intents", %{conn: conn} do
    conn = conn |> init_test_session(%{}) |> Discord.put_authenticate_intent()

    assert {:ok, :authenticate} = Discord.fetch_intent(conn)
    assert {{:ok, :authenticate}, consumed_conn} = Discord.take_intent(conn)
    assert {:error, :invalid_or_expired_intent} = Discord.fetch_intent(consumed_conn)
  end

  test "rejects an expired link intent", %{conn: conn} do
    user = D20.AccountsFixtures.user_fixture()

    conn = conn |> init_test_session(%{}) |> Discord.put_link_intent(user)
    intent = conn |> get_session(:discord_auth_intent) |> Map.put("issued_at", 0)
    conn = put_session(conn, :discord_auth_intent, intent)

    assert {:error, :invalid_or_expired_intent} = Discord.fetch_intent(conn)
  end

  test "binds registration completion to the session nonce", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})
      |> Discord.put_registration(%{provider_uid: "discord-subject", email: "player@example.com"})

    assert {:ok, %{provider_uid: "discord-subject", email: "player@example.com"}} =
             Discord.fetch_registration(conn)

    mismatched_conn = put_session(conn, :discord_registration_nonce, "another-session-nonce")

    assert {:error, :invalid_or_expired_completion} = Discord.fetch_registration(mismatched_conn)
  end

  test "rejects expired registration completion", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})
      |> Discord.put_registration(%{provider_uid: "discord-subject", email: "player@example.com"},
        signed_at: System.system_time(:second) - 601
      )

    assert {:error, :invalid_or_expired_completion} = Discord.fetch_registration(conn)
  end

  test "maps provider failures without retaining provider details" do
    failure = %Ueberauth.Failure{
      provider: :discord,
      errors: [
        %Ueberauth.Failure.Error{
          message_key: "token",
          message: "authorization-code-and-token-details"
        }
      ]
    }

    assert Discord.failure_reason(failure) == :provider_failure
  end

  defp discord_auth(subject, email, verified) do
    %Ueberauth.Auth{
      provider: :discord,
      uid: subject,
      info: %Ueberauth.Auth.Info{email: email, name: "Player"},
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          token: %{access_token: "discard-me"},
          user: %{
            "id" => subject,
            "email" => email,
            "verified" => verified,
            "username" => "Discard Me"
          }
        }
      },
      credentials: %Ueberauth.Auth.Credentials{token: "discard-me"}
    }
  end

  defp restore_application_env(application, key, nil),
    do: Application.delete_env(application, key)

  defp restore_application_env(application, key, value),
    do: Application.put_env(application, key, value)
end
