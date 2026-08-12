defmodule D20Web.Auth.GoogleTest do
  use D20Web.ConnCase, async: false

  alias D20Web.Auth.Google

  test "derives provider availability from both runtime credentials" do
    previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)

    on_exit(fn ->
      restore_application_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, previous_config)
    end)

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "google-client-id",
      client_secret: "google-client-secret"
    )

    assert Google.available?()

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "",
      client_secret: "   "
    )

    assert Google.available?()

    for config <- [
          [client_id: nil, client_secret: "google-client-secret"],
          [client_id: "google-client-id", client_secret: nil],
          []
        ] do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, config)
      refute Google.available?()
    end
  end

  test "normalizes only a Google subject and transient verified email" do
    auth = google_auth("google-subject", "player@example.com", true)

    assert {:ok, identity} = Google.normalize(auth)

    assert identity == %{
             provider: :google,
             provider_uid: "google-subject",
             email: "player@example.com",
             email_verified: true
           }

    refute Map.has_key?(identity, :credentials)
    refute Map.has_key?(identity, :raw_info)
    refute Map.has_key?(identity, :name)
  end

  test "rejects another provider" do
    assert {:error, :unexpected_provider} =
             :google
             |> google_auth("player@example.com", true)
             |> Map.put(:provider, :facebook)
             |> Google.normalize()
  end

  test "treats subjects extracted by the Google strategy as opaque values" do
    for subject <- ["", "   ", String.duplicate("a", 256)] do
      assert {:ok, %{provider_uid: ^subject}} =
               subject |> google_auth("player@example.com", true) |> Google.normalize()
    end
  end

  test "requires a valid verified email only for registration" do
    assert {:ok, identity} =
             "google-subject" |> google_auth("player@example.com", true) |> Google.normalize()

    assert {:ok, %{provider_uid: "google-subject", email: "player@example.com"}} =
             Google.registration_data(identity)

    for {email, verified} <- [{nil, true}, {"not an email", true}, {"player@example.com", false}] do
      assert {:ok, invalid_identity} =
               "google-subject" |> google_auth(email, verified) |> Google.normalize()

      assert {:error, _reason} = Google.registration_data(invalid_identity)
    end
  end

  test "accepts changed or missing email data for an already linked subject" do
    assert {:ok, %{provider_uid: "linked-subject", email: nil, email_verified: false}} =
             "linked-subject" |> google_auth(nil, false) |> Google.normalize()
  end

  test "stores and consumes an authentication intent", %{conn: conn} do
    conn = conn |> init_test_session(%{}) |> Google.put_authenticate_intent()

    assert get_session(conn, :google_auth_intent) == :authenticate
    assert {:ok, :authenticate} = Google.fetch_intent(conn)
    assert {{:ok, :authenticate}, consumed_conn} = Google.take_intent(conn)
    assert {:error, :missing_intent} = Google.fetch_intent(consumed_conn)
  end

  test "stores a link intent bound to the user", %{conn: conn} do
    user = D20.AccountsFixtures.user_fixture()

    conn = conn |> init_test_session(%{}) |> Google.put_link_intent(user)

    assert get_session(conn, :google_auth_intent) == {:link, to_string(user.id)}
    assert {:ok, {:link, user_id}} = Google.fetch_intent(conn)
    assert user_id == to_string(user.id)
  end

  test "binds registration completion to the session nonce", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})
      |> Google.put_registration(%{provider_uid: "google-subject", email: "player@example.com"})

    assert {:ok, %{provider_uid: "google-subject", email: "player@example.com"}} =
             Google.fetch_registration(conn)

    mismatched_conn = put_session(conn, :google_registration_nonce, "another-session-nonce")

    assert {:error, :invalid_or_expired_completion} = Google.fetch_registration(mismatched_conn)
  end

  test "preserves the opaque provider subject in registration completion", %{conn: conn} do
    subject = String.duplicate("subject-", 40)

    conn =
      conn
      |> init_test_session(%{})
      |> Google.put_registration(%{provider_uid: subject, email: "player@example.com"})

    assert {:ok, %{provider_uid: ^subject}} = Google.fetch_registration(conn)
  end

  test "rejects expired registration completion", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})
      |> Google.put_registration(%{provider_uid: "google-subject", email: "player@example.com"},
        signed_at: System.system_time(:second) - 601
      )

    assert {:error, :invalid_or_expired_completion} = Google.fetch_registration(conn)
  end

  test "maps provider failures without retaining provider details" do
    failure = %Ueberauth.Failure{
      provider: :google,
      errors: [
        %Ueberauth.Failure.Error{
          message_key: "token",
          message: "authorization-code-and-token-details"
        }
      ]
    }

    assert Google.failure_reason(failure) == :provider_failure
  end

  defp google_auth(subject, email, verified) do
    %Ueberauth.Auth{
      provider: :google,
      uid: subject,
      info: %Ueberauth.Auth.Info{email: email, name: "Player"},
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          token: %{access_token: "discard-me"},
          user: %{"email_verified" => verified, "name" => "Discard Me"}
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
