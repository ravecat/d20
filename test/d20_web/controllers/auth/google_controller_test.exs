defmodule D20Web.Auth.GoogleControllerTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts
  alias D20.Accounts.User
  alias D20.Accounts.UserIdentity
  alias D20Web.Auth.Google
  alias D20Web.Auth.GoogleController

  setup do
    previous_oauth_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)

    Application.put_env(
      :ueberauth,
      Ueberauth.Strategy.Google.OAuth,
      Keyword.merge(previous_oauth_config || [],
        client_id: "google-client-id",
        client_secret: "google-client-secret"
      )
    )

    on_exit(fn ->
      restore_application_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, previous_oauth_config)
    end)
  end

  describe "GET /auth/google" do
    test "fails locally when Google credentials are unavailable", %{conn: conn} do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
        client_id: nil,
        client_secret: "google-client-secret"
      )

      {conn, log} =
        ExUnit.CaptureLog.with_log(fn ->
          get(conn, "/auth/google?return_to=%2Fgames%2Fqwinto")
        end)

      assert redirected_to(conn) == "/games/qwinto"
      assert get_session(conn, :auth_prompt).message =~ "temporarily unavailable"
      assert {:error, :missing_intent} = Google.fetch_intent(conn)
      refute redirected_to(conn) =~ "google.com"
      refute log =~ "google-client-secret"
    end

    test "uses the fixed minimal scope and strips caller provider overrides", %{conn: conn} do
      conn =
        get(
          conn,
          "/auth/google?return_to=%2Fgames%2Fqwinto&scope=profile&prompt=consent&access_type=offline&include_granted_scopes=true&login_hint=private%40example.com&hd=example.com&hl=pl"
        )

      assert redirected_to(conn, 302) =~ "https://accounts.google.com/o/oauth2/v2/auth?"

      query =
        conn |> redirected_to(302) |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

      assert query["scope"] == "openid email"
      assert query["client_id"] == "google-client-id"
      assert query["redirect_uri"] == "http://example.com/auth/google/callback"
      assert is_binary(query["state"])

      for name <- ~w(prompt access_type include_granted_scopes login_hint hd hl) do
        refute Map.has_key?(query, name)
      end

      assert get_session(conn, :return_to) == "/games/qwinto"
      assert get_session(conn, :google_auth_intent) == :authenticate
    end

    test "rejects an unsafe return destination", %{conn: conn} do
      conn = get(conn, "/auth/google?return_to=https%3A%2F%2Fevil.example%2Fsteal")

      refute get_session(conn, :return_to)
    end

    test "does not expose a dynamic provider route", %{conn: conn} do
      assert conn |> get("/auth/facebook") |> response(404)
    end
  end

  describe "GET /auth/google/callback" do
    test "does not exchange a callback while Google credentials are unavailable", %{conn: conn} do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
        client_id: "google-client-id",
        client_secret: nil
      )

      {conn, log} =
        ExUnit.CaptureLog.with_log(fn ->
          conn
          |> init_test_session(return_to: "/games/qwinto")
          |> Google.put_authenticate_intent()
          |> get("/auth/google/callback?state=provider-state&code=secret-authorization-code")
        end)

      assert redirected_to(conn) == "/games/qwinto"
      assert get_session(conn, :auth_prompt).message =~ "temporarily unavailable"
      refute get_session(conn, :user_token)
      refute log =~ "secret-authorization-code"
    end

    test "rejects invalid state before trusting the authorization code", %{conn: conn} do
      {conn, log} =
        ExUnit.CaptureLog.with_log(fn ->
          conn
          |> init_test_session(return_to: "/games/qwinto")
          |> get("/auth/google/callback?state=invalid&code=secret-authorization-code")
        end)

      assert redirected_to(conn) == "/games/qwinto"
      refute get_session(conn, :user_token)
      assert get_session(conn, :auth_prompt).message =~ "could not be completed"
      refute log =~ "secret-authorization-code"
    end

    test "logs in an exact identity owner, rotates the session, and uses safe return", %{
      conn: conn
    } do
      user = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :google, "returning-subject")

      conn =
        conn
        |> direct_callback_conn(nil,
          return_to: "/games/qwinto",
          anonymous_user_id: "anon_before_google"
        )
        |> Google.put_authenticate_intent()
        |> assign(:ueberauth_auth, google_auth("returning-subject", nil, false))
        |> GoogleController.callback(%{})

      assert redirected_to(conn) == "/games/qwinto"
      assert conn.private.plug_session_info == :renew
      refute get_session(conn, :anonymous_user_id)
      assert session_user(conn).id == user.id
    end

    test "starts completion for an unknown subject with verified unused email", %{conn: conn} do
      email = unique_user_email()

      conn =
        conn
        |> direct_callback_conn()
        |> Google.put_authenticate_intent()
        |> assign(:ueberauth_auth, google_auth("new-subject", email, true))
        |> GoogleController.callback(%{})

      assert redirected_to(conn) == ~p"/auth/google/register"

      assert {:ok, %{provider_uid: "new-subject", email: ^email}} =
               Google.fetch_registration(conn)

      refute Accounts.get_user_by_email(email)
      refute get_session(conn, :user_token)
    end

    test "does not auto-link or authenticate an unknown subject by matching email", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> direct_callback_conn()
        |> Google.put_authenticate_intent()
        |> assign(:ueberauth_auth, google_auth("unlinked-subject", user.email, true))
        |> GoogleController.callback(%{})

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      refute Accounts.get_user_by_identity(:google, "unlinked-subject")
      assert get_session(conn, :auth_prompt).message =~ "already has a D20 account"
    end

    test "rejects unknown identity registration without verified email", %{conn: conn} do
      conn =
        conn
        |> direct_callback_conn()
        |> Google.put_authenticate_intent()
        |> assign(:ueberauth_auth, google_auth("new-subject", "player@example.com", false))
        |> GoogleController.callback(%{})

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert {:error, :invalid_or_expired_completion} = Google.fetch_registration(conn)
    end

    test "fails closed without a valid callback intent", %{conn: conn} do
      conn =
        conn
        |> direct_callback_conn()
        |> assign(:ueberauth_auth, google_auth("new-subject", unique_user_email(), true))
        |> GoogleController.callback(%{})

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert D20.Repo.aggregate(User, :count) == 0
    end
  end

  describe "Google registration completion" do
    test "renders the shared page without exposing the Google identity", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Google.put_registration(%{
          provider_uid: "private-google-subject",
          email: "player@example.com"
        })
        |> get(~p"/auth/google/register")

      assert inertia_component(conn) == "registration_completion"

      assert %{
               email: "player@example.com",
               submission: %{
                 action: "/auth/google/register",
                 credential: %{type: "server_session"}
               },
               cancelAction: "/auth/google/register/cancel"
             } = props = inertia_props(conn)

      refute Map.has_key?(props, :provider_uid)
      refute Map.has_key?(props, :token)
    end

    test "creates and authenticates exactly one complete account", %{conn: conn} do
      email = unique_user_email()

      conn =
        conn
        |> init_test_session(return_to: "/games/qwinto")
        |> Google.put_registration(%{provider_uid: "new-subject", email: email})
        |> post(~p"/auth/google/register", %{
          "user" => %{"username" => "google_player", "remember_me" => "true"}
        })

      assert redirected_to(conn) == "/games/qwinto"
      assert conn.resp_cookies["_d20_web_user_remember_me"]

      assert %User{username: "google_player", confirmed_at: confirmed_at} =
               user = Accounts.get_user_by_email(email)

      assert confirmed_at
      assert Accounts.get_user_by_identity(:google, "new-subject").id == user.id
      assert session_user(conn).id == user.id
      assert {:error, :invalid_or_expired_completion} = Google.fetch_registration(conn)

      replay_conn =
        conn
        |> recycle()
        |> post(~p"/auth/google/register", %{"user" => %{"username" => "other_player"}})

      assert redirected_to(replay_conn) == ~p"/"
      assert D20.Repo.aggregate(User, :count) == 1
      assert D20.Repo.aggregate(UserIdentity, :count) == 1
    end

    test "persists the verified proof email instead of a browser replacement", %{conn: conn} do
      verified_email = unique_user_email()
      browser_email = unique_user_email()

      conn =
        conn
        |> init_test_session(%{})
        |> Google.put_registration(%{
          provider_uid: "verified-email-subject",
          email: verified_email
        })
        |> post(~p"/auth/google/register", %{
          "user" => %{"username" => "verified_email_player", "email" => browser_email}
        })

      assert redirected_to(conn) == ~p"/"
      assert %User{email: ^verified_email} = Accounts.get_user_by_email(verified_email)
      refute Accounts.get_user_by_email(browser_email)
    end

    test "keeps valid completion state after username validation", %{conn: conn} do
      email = unique_user_email()

      conn =
        conn
        |> init_test_session(%{})
        |> Google.put_registration(%{provider_uid: "new-subject", email: email})
        |> inertia_request()
        |> post(~p"/auth/google/register", %{"user" => %{"username" => "invalid name"}})

      assert redirected_to(conn, 303) == ~p"/auth/google/register"
      assert {:ok, %{provider_uid: "new-subject"}} = Google.fetch_registration(conn)
      refute Accounts.get_user_by_email(email)

      response_conn = follow_inertia_redirect(conn)
      assert %{username: _message} = inertia_errors(response_conn)
    end

    test "clears expired completion without creating an account", %{conn: conn} do
      email = unique_user_email()

      conn =
        conn
        |> init_test_session(%{})
        |> Google.put_registration(%{provider_uid: "new-subject", email: email},
          signed_at: System.system_time(:second) - 601
        )
        |> post(~p"/auth/google/register", %{"user" => %{"username" => "google_player"}})

      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_user_by_email(email)
      assert {:error, :invalid_or_expired_completion} = Google.fetch_registration(conn)
    end

    test "clears completion when the player chooses email registration", %{conn: conn} do
      email = unique_user_email()

      conn =
        conn
        |> init_test_session(%{})
        |> Google.put_registration(%{provider_uid: "new-subject", email: email})
        |> post(~p"/auth/google/register/cancel")

      assert redirected_to(conn) == ~p"/"
      assert {:error, :invalid_or_expired_completion} = Google.fetch_registration(conn)
      refute Accounts.get_user_by_email(email)
    end
  end

  describe "GET /users/settings/auth/google" do
    test "requires authentication and sudo mode", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/auth/google")
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).reauthenticate == false

      old_authentication = DateTime.add(DateTime.utc_now(:second), -11, :minute)
      user = user_fixture()

      stale_conn =
        build_conn()
        |> log_in_user(user, token_authenticated_at: old_authentication)
        |> get(~p"/users/settings/auth/google")

      assert redirected_to(stale_conn) == ~p"/"
      assert get_session(stale_conn, :auth_prompt).reauthenticate == true
    end

    test "stores a user-bound link intent and starts only through Google request", %{conn: conn} do
      user = user_fixture()

      conn = conn |> log_in_user(user) |> get(~p"/users/settings/auth/google")

      assert redirected_to(conn) == ~p"/auth/google"
      assert {:ok, {:link, user_id}} = Google.fetch_intent(conn)
      assert user_id == to_string(user.id)
    end

    test "links the subject to the same sudo-valid user", %{conn: conn} do
      user = authenticated_user(user_fixture())

      conn =
        conn
        |> direct_callback_conn(user)
        |> Google.put_link_intent(user)
        |> assign(:ueberauth_auth, google_auth("linked-subject", nil, false))
        |> GoogleController.callback(%{})

      assert redirected_to(conn) == ~p"/users/settings"
      assert Accounts.get_user_by_identity(:google, "linked-subject").id == user.id
      assert session_user(conn).id == user.id
    end

    test "treats the same owner as idempotent", %{conn: conn} do
      user = authenticated_user(user_fixture())
      assert {:ok, identity} = Accounts.link_user_identity(user, :google, "linked-subject")

      conn =
        conn
        |> direct_callback_conn(user)
        |> Google.put_link_intent(user)
        |> assign(:ueberauth_auth, google_auth("linked-subject", nil, false))
        |> GoogleController.callback(%{})

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "linked successfully"
      assert D20.Repo.get!(UserIdentity, identity.id).user_id == user.id
      assert D20.Repo.aggregate(UserIdentity, :count) == 1
    end

    test "reports one generic conflict for another owner or another subject", %{conn: conn} do
      user = authenticated_user(user_fixture())
      other_user = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(other_user, :google, "owned-subject")

      conflict_conn =
        conn
        |> direct_callback_conn(user)
        |> Google.put_link_intent(user)
        |> assign(:ueberauth_auth, google_auth("owned-subject", nil, false))
        |> GoogleController.callback(%{})

      assert redirected_to(conflict_conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conflict_conn.assigns.flash, :error) ==
               "Google could not be linked to this account."

      assert Accounts.get_user_by_identity(:google, "owned-subject").id == other_user.id
    end

    test "rejects a callback bound to a different current user", %{conn: conn} do
      initiating_user = user_fixture()
      current_user = authenticated_user(user_fixture())

      conn =
        conn
        |> direct_callback_conn(current_user)
        |> Google.put_link_intent(initiating_user)
        |> assign(:ueberauth_auth, google_auth("unbound-subject", nil, false))
        |> GoogleController.callback(%{})

      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_user_by_identity(:google, "unbound-subject")
    end
  end

  defp direct_callback_conn(conn, current_user \\ nil, session \\ []) do
    session =
      if current_user do
        Keyword.put_new(session, :user_token, Accounts.generate_user_session_token(current_user))
      else
        session
      end

    conn
    |> init_test_session(session)
    |> Phoenix.Controller.fetch_flash([])
    |> assign(:current_user, current_user)
  end

  defp session_user(conn) do
    conn |> get_session(:user_token) |> Accounts.get_user_by_session_token() |> elem(0)
  end

  defp authenticated_user(user) do
    %{user | authenticated_at: DateTime.utc_now(:second)}
  end

  defp google_auth(subject, email, verified) do
    %Ueberauth.Auth{
      provider: :google,
      uid: subject,
      info: %Ueberauth.Auth.Info{email: email, name: "Player"},
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{user: %{"email_verified" => verified}, token: %{token: "discard-me"}}
      },
      credentials: %Ueberauth.Auth.Credentials{token: "discard-me"}
    }
  end

  defp inertia_request(conn), do: put_req_header(conn, "x-inertia", "true")

  defp follow_inertia_redirect(conn) do
    conn
    |> recycle()
    |> inertia_request()
    |> get(redirected_to(conn, 303))
  end

  defp restore_application_env(application, key, nil),
    do: Application.delete_env(application, key)

  defp restore_application_env(application, key, value),
    do: Application.put_env(application, key, value)
end
