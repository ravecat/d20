defmodule D20Web.Auth.FacebookTest do
  use D20Web.ConnCase, async: false

  alias D20Web.Auth.Facebook

  test "pins minimum Facebook fields and current Graph endpoints" do
    providers = Application.fetch_env!(:ueberauth, Ueberauth)[:providers]
    {_strategy, provider_options} = Keyword.fetch!(providers, :facebook)
    oauth_config = Application.fetch_env!(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)

    assert provider_options[:default_scope] == "email"
    assert provider_options[:profile_fields] == "id,email"
    assert oauth_config[:site] == "https://graph.facebook.com/v26.0"
    assert oauth_config[:authorize_url] == "https://www.facebook.com/dialog/oauth"
    assert oauth_config[:token_url] == "https://graph.facebook.com/v26.0/oauth/access_token"
  end

  test "derives provider availability from both non-blank runtime credentials" do
    previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)

    on_exit(fn ->
      restore_application_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth, previous_config)
    end)

    Application.put_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth,
      client_id: "facebook-client-id",
      client_secret: "facebook-client-secret"
    )

    assert Facebook.available?()

    for config <- [
          [client_id: nil, client_secret: "facebook-client-secret"],
          [client_id: "facebook-client-id", client_secret: "   "],
          []
        ] do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth, config)
      refute Facebook.available?()
    end
  end

  test "normalizes only the exact Facebook UID and optional email candidate" do
    assert {:ok, identity} =
             "facebook-subject" |> facebook_auth("player@example.com") |> Facebook.normalize()

    assert identity == %{
             provider: :facebook,
             provider_uid: "facebook-subject",
             email: "player@example.com"
           }

    refute Map.has_key?(identity, :credentials)
    refute Map.has_key?(identity, :raw_info)
    refute Map.has_key?(identity, :name)
  end

  test "omits absent, malformed, or inconsistent Facebook email candidates" do
    for auth <- [
          facebook_auth("facebook-subject", nil),
          facebook_auth("facebook-subject", "not an email"),
          put_in(
            facebook_auth("facebook-subject", "player@example.com").extra.raw_info.user["email"],
            "different@example.com"
          )
        ] do
      assert {:ok, %{provider_uid: "facebook-subject", email: nil}} = Facebook.normalize(auth)
    end
  end

  test "rejects another provider and malformed or inconsistent UIDs" do
    assert {:error, :unexpected_provider} =
             "facebook-subject"
             |> facebook_auth("player@example.com")
             |> Map.put(:provider, :google)
             |> Facebook.normalize()

    for subject <- [nil, "", "   ", String.duplicate("a", 256)] do
      assert {:error, :invalid_provider_uid} =
               subject |> facebook_auth("player@example.com") |> Facebook.normalize()
    end

    auth = facebook_auth("facebook-subject", "player@example.com")
    inconsistent = put_in(auth.extra.raw_info.user["id"], "different-subject")

    assert {:error, :invalid_provider_uid} = Facebook.normalize(inconsistent)
  end

  test "stores, validates, and consumes bounded intents", %{conn: conn} do
    conn = conn |> init_test_session(%{}) |> Facebook.put_authenticate_intent()

    assert {:ok, :authenticate} = Facebook.fetch_intent(conn)
    assert {{:ok, :authenticate}, consumed_conn} = Facebook.take_intent(conn)
    assert {:error, :invalid_or_expired_intent} = Facebook.fetch_intent(consumed_conn)
  end

  test "binds link and reauthentication intents to the current user", %{conn: conn} do
    user = D20.AccountsFixtures.user_fixture()

    link_conn = conn |> init_test_session(%{}) |> Facebook.put_link_intent(user)
    assert {:ok, {:link, user_id}} = Facebook.fetch_intent(link_conn)
    assert user_id == to_string(user.id)

    reauthentication_conn = Facebook.put_reauthenticate_intent(link_conn, user)
    assert {:ok, {:reauthenticate, ^user_id}} = Facebook.fetch_intent(reauthentication_conn)
  end

  test "rejects expired intent", %{conn: conn} do
    conn = conn |> init_test_session(%{}) |> Facebook.put_authenticate_intent()
    intent = conn |> get_session(:facebook_auth_intent) |> Map.put("issued_at", 0)

    assert {:error, :invalid_or_expired_intent} =
             conn |> put_session(:facebook_auth_intent, intent) |> Facebook.fetch_intent()
  end

  test "binds optional-email registration to the browser session", %{conn: conn} do
    conn =
      conn
      |> init_test_session(%{})
      |> Facebook.put_registration(
        %{provider_uid: "facebook-subject", email: "candidate@example.com"},
        "/games/qwinto"
      )

    assert {:ok,
            %{
              provider_uid: "facebook-subject",
              email: "candidate@example.com",
              return_to: "/games/qwinto"
            }} = Facebook.fetch_registration(conn)

    mismatched = put_session(conn, :facebook_registration_nonce, "different-nonce")
    assert {:error, :invalid_or_expired_registration} = Facebook.fetch_registration(mismatched)
  end

  test "registration permits a null email candidate and expires", %{conn: conn} do
    current_time = System.system_time(:second)

    valid_conn =
      conn
      |> init_test_session(%{})
      |> Facebook.put_registration(%{provider_uid: "facebook-subject", email: nil}, "/",
        signed_at: current_time
      )

    assert {:ok, %{email: nil}} = Facebook.fetch_registration(valid_conn)

    expired_conn =
      conn
      |> recycle()
      |> init_test_session(%{})
      |> Facebook.put_registration(%{provider_uid: "facebook-subject", email: nil}, "/",
        signed_at: current_time - 601
      )

    assert {:error, :invalid_or_expired_registration} = Facebook.fetch_registration(expired_conn)
  end

  test "maps provider failure without retaining callback details" do
    failure = %Ueberauth.Failure{
      provider: :facebook,
      errors: [
        %Ueberauth.Failure.Error{
          message_key: "token",
          message: "authorization-code-and-token-details"
        }
      ]
    }

    assert Facebook.failure_reason(failure) == :provider_failure
  end

  defp facebook_auth(subject, email) do
    %Ueberauth.Auth{
      provider: :facebook,
      uid: subject,
      info: %Ueberauth.Auth.Info{email: email, name: "Discard Me"},
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          token: %{access_token: "discard-me"},
          user: %{"id" => subject, "email" => email, "name" => "Discard Me"}
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
