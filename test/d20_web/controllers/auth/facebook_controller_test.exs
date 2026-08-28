defmodule D20Web.Auth.FacebookControllerTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts
  alias D20.Accounts.User
  alias D20Web.Auth.Facebook
  alias D20Web.Auth.FacebookController

  setup do
    previous_oauth_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)

    Application.put_env(
      :ueberauth,
      Ueberauth.Strategy.Facebook.OAuth,
      Keyword.merge(previous_oauth_config || [],
        client_id: "facebook-client-id",
        client_secret: "facebook-client-secret"
      )
    )

    on_exit(fn ->
      restore_application_env(
        :ueberauth,
        Ueberauth.Strategy.Facebook.OAuth,
        previous_oauth_config
      )
    end)
  end

  describe "GET /auth/facebook" do
    test "fails locally when Facebook credentials are unavailable", %{conn: conn} do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth,
        client_id: nil,
        client_secret: "facebook-client-secret"
      )

      {conn, log} =
        ExUnit.CaptureLog.with_log(fn ->
          get(conn, "/auth/facebook?return_to=%2Fgames%2Fqwinto")
        end)

      assert redirected_to(conn) == "/games/qwinto"
      assert get_session(conn, :auth_prompt).kind == :error
      assert get_session(conn, :auth_prompt).message =~ "temporarily unavailable"
      refute redirected_to(conn) =~ "facebook.com"
      refute log =~ "facebook-client-secret"
    end

    test "uses fixed scope and strips caller-controlled provider parameters", %{conn: conn} do
      conn =
        get(
          conn,
          "/auth/facebook?return_to=%2Fgames%2Fqwinto&scope=user_friends&auth_type=rerequest&display=popup&locale=pl_PL&redirect_uri=https%3A%2F%2Fevil.example&response_type=token&client_id=attacker&state=attacker"
        )

      assert redirected_to(conn, 302) =~ "https://www.facebook.com/dialog/oauth?"

      query =
        conn |> redirected_to(302) |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

      assert query["scope"] == "email"
      assert query["client_id"] == "facebook-client-id"
      assert query["redirect_uri"] == "http://example.com/auth/facebook/callback"
      assert query["response_type"] == "code"
      assert is_binary(query["state"])

      for name <- ~w(auth_type display locale) do
        refute Map.has_key?(query, name)
      end

      assert get_session(conn, :return_to) == "/games/qwinto"
      assert %{"action" => "authenticate"} = get_session(conn, :facebook_auth_intent)
    end

    test "binds reauthentication requests to the current user", %{conn: conn} do
      user = provider_user_fixture(%{}, :facebook)

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/auth/facebook?intent=reauthenticate&return_to=/users/settings")

      assert redirected_to(conn, 302) =~ "https://www.facebook.com/dialog/oauth?"
      assert {:ok, {:reauthenticate, user_id}} = Facebook.fetch_intent(conn)
      assert user_id == to_string(user.id)
    end

    test "rejects unsafe return destinations", %{conn: conn} do
      conn = get(conn, "/auth/facebook?return_to=https%3A%2F%2Fevil.example%2Fsteal")
      refute get_session(conn, :return_to)
    end
  end

  describe "Facebook callback outcomes" do
    test "rejects invalid state before trusting the authorization code", %{conn: conn} do
      {conn, log} =
        ExUnit.CaptureLog.with_log(fn ->
          conn
          |> init_test_session(return_to: "/games/qwinto")
          |> get("/auth/facebook/callback?state=invalid&code=secret-facebook-authorization-code")
        end)

      assert redirected_to(conn) == "/games/qwinto"
      refute get_session(conn, :user_token)
      assert get_session(conn, :auth_prompt).message =~ "could not be completed"
      refute log =~ "secret-facebook-authorization-code"
    end

    test "logs in the exact identity owner and rotates the session", %{conn: conn} do
      user = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :facebook, "returning-subject")

      conn =
        conn
        |> direct_callback_conn(nil,
          return_to: "/games/qwinto",
          anonymous_user_id: "anon_before_facebook"
        )
        |> Facebook.put_authenticate_intent()
        |> assign(:ueberauth_auth, facebook_auth("returning-subject", nil))
        |> FacebookController.callback(%{})

      assert redirected_to(conn) == "/games/qwinto"
      assert conn.private.plug_session_info == :renew
      refute get_session(conn, :anonymous_user_id)
      assert session_user(conn).id == user.id
    end

    test "reauthenticates only the current provider-only user with an exact linked identity", %{
      conn: conn
    } do
      user = provider_user_fixture(%{}, :facebook) |> authenticated_user()
      [%{provider_uid: provider_uid}] = Accounts.list_user_identities(user)

      conn =
        conn
        |> direct_callback_conn(user, return_to: "/users/settings")
        |> Facebook.put_reauthenticate_intent(user)
        |> assign(:ueberauth_auth, facebook_auth(provider_uid, nil))
        |> FacebookController.callback(%{})

      assert redirected_to(conn) == ~p"/users/settings"
      assert session_user(conn).id == user.id
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Identity confirmed."
    end

    test "does not switch accounts during Facebook reauthentication", %{conn: conn} do
      current_user = provider_user_fixture(%{}, :facebook) |> authenticated_user()
      other_user = provider_user_fixture(%{}, :facebook)
      [%{provider_uid: other_uid}] = Accounts.list_user_identities(other_user)

      conn =
        conn
        |> direct_callback_conn(current_user, return_to: "/users/settings")
        |> Facebook.put_reauthenticate_intent(current_user)
        |> assign(:ueberauth_auth, facebook_auth(other_uid, nil))
        |> FacebookController.callback(%{})

      assert redirected_to(conn) == ~p"/users/settings"
      assert session_user(conn).id == current_user.id
      assert get_session(conn, :auth_prompt).reauthenticate
    end

    test "starts username-only registration with an optional email candidate", %{conn: conn} do
      for {subject, email} <- [
            {"candidate-subject", "candidate@example.com"},
            {"provider-only-subject", nil}
          ] do
        result =
          conn
          |> direct_callback_conn()
          |> Facebook.put_authenticate_intent()
          |> assign(:ueberauth_auth, facebook_auth(subject, email))
          |> FacebookController.callback(%{})

        assert redirected_to(result) == ~p"/auth/facebook/register"

        assert {:ok, %{provider_uid: ^subject, email: ^email}} =
                 Facebook.fetch_registration(result)

        refute get_session(result, :user_token)
      end
    end

    test "fails closed without a valid callback intent", %{conn: conn} do
      conn =
        conn
        |> direct_callback_conn()
        |> assign(:ueberauth_auth, facebook_auth("new-subject", "candidate@example.com"))
        |> FacebookController.callback(%{})

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert D20.Repo.aggregate(User, :count) == 0
    end

    test "redacts provider failure details", %{conn: conn} do
      failure = %Ueberauth.Failure{
        provider: :facebook,
        errors: [%Ueberauth.Failure.Error{message_key: "token", message: "secret-code-and-token"}]
      }

      {conn, log} =
        ExUnit.CaptureLog.with_log(fn ->
          conn
          |> direct_callback_conn()
          |> Facebook.put_authenticate_intent()
          |> assign(:ueberauth_failure, failure)
          |> FacebookController.callback(%{})
        end)

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      refute log =~ "secret-code-and-token"
    end
  end

  describe "username-only Facebook registration" do
    test "renders a server-owned email candidate without an editable email contract", %{
      conn: conn
    } do
      conn =
        conn
        |> init_test_session(%{})
        |> Facebook.put_registration(
          %{provider_uid: "private-facebook-subject", email: "candidate@example.com"},
          "/games/qwinto"
        )
        |> get(~p"/auth/facebook/register")

      assert inertia_component(conn) == "registration_completion"

      assert %{
               email: "candidate@example.com",
               submission: %{
                 action: "/auth/facebook/register",
                 credential: %{type: "server_session"}
               },
               cancelAction: "/auth/facebook/register/cancel"
             } = props = inertia_props(conn)

      refute Map.has_key?(props, :emailEditable)
      refute Map.has_key?(props, :emailSent)
      refute Map.has_key?(props, :provider_uid)
      refute Map.has_key?(props, :token)
    end

    test "invalid username creates no user or identity", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Facebook.put_registration(
          %{provider_uid: "facebook-invalid-username", email: nil},
          "/"
        )
        |> inertia_request()
        |> post(~p"/auth/facebook/register", %{
          "user" => %{"email" => "browser@example.com", "username" => "?"}
        })

      assert redirected_to(conn, 303) == ~p"/auth/facebook/register"
      refute Accounts.get_user_by_email("browser@example.com")
      refute Accounts.get_user_by_identity(:facebook, "facebook-invalid-username")
      refute get_session(conn, :user_token)
    end

    test "registers immediately with an unused server-owned email candidate", %{conn: conn} do
      email = unique_user_email()

      conn =
        conn
        |> init_test_session(return_to: "/games/qwinto")
        |> Facebook.put_registration(
          %{provider_uid: "facebook-candidate-subject", email: email},
          "/games/qwinto"
        )
        |> post(~p"/auth/facebook/register", %{
          "user" => %{"username" => "facebook_player", "remember_me" => "true"}
        })

      assert redirected_to(conn) == "/games/qwinto"
      assert conn.resp_cookies["_d20_web_user_remember_me"]

      assert %User{email: ^email, username: "facebook_player", confirmed_at: confirmed_at} =
               user = Accounts.get_user_by_identity(:facebook, "facebook-candidate-subject")

      assert confirmed_at
      assert session_user(conn).id == user.id
      assert {:error, :invalid_or_expired_registration} = Facebook.fetch_registration(conn)
    end

    test "registers a provider-only account when Facebook returns no email", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Facebook.put_registration(
          %{provider_uid: "facebook-provider-only-subject", email: nil},
          "/"
        )
        |> post(~p"/auth/facebook/register", %{"user" => %{"username" => "provider_only_player"}})

      assert redirected_to(conn) == ~p"/"

      assert %User{email: nil, username: "provider_only_player", confirmed_at: confirmed_at} =
               user = Accounts.get_user_by_identity(:facebook, "facebook-provider-only-subject")

      assert confirmed_at
      assert session_user(conn).id == user.id
    end

    test "discards an already-owned email candidate without merging accounts", %{conn: conn} do
      owner = user_fixture()
      assert_receive {:email, _confirmation_email}

      conn =
        conn
        |> init_test_session(%{})
        |> Facebook.put_registration(
          %{provider_uid: "unlinked-facebook-subject", email: owner.email},
          "/"
        )
        |> post(~p"/auth/facebook/register", %{
          "user" => %{"username" => "facebook_distinct_player"}
        })

      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_user_by_email(owner.email).id == owner.id

      assert %User{email: nil, username: "facebook_distinct_player"} =
               provider_user =
               Accounts.get_user_by_identity(:facebook, "unlinked-facebook-subject")

      assert provider_user.id != owner.id
      assert session_user(conn).id == provider_user.id
    end

    test "ignores a browser-submitted email replacement", %{conn: conn} do
      server_email = unique_user_email()
      browser_email = unique_user_email()

      conn =
        conn
        |> init_test_session(%{})
        |> Facebook.put_registration(
          %{provider_uid: "facebook-server-email-subject", email: server_email},
          "/"
        )
        |> post(~p"/auth/facebook/register", %{
          "user" => %{"email" => browser_email, "username" => "server_email_player"}
        })

      assert redirected_to(conn) == ~p"/"

      assert %User{email: ^server_email} =
               Accounts.get_user_by_identity(:facebook, "facebook-server-email-subject")

      refute Accounts.get_user_by_email(browser_email)
    end

    test "cancellation clears registration state", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Facebook.put_registration(%{provider_uid: "facebook-subject", email: nil}, "/")
        |> post(~p"/auth/facebook/register/cancel")

      assert redirected_to(conn) == ~p"/"
      assert {:error, :invalid_or_expired_registration} = Facebook.fetch_registration(conn)
    end
  end

  describe "Facebook linking" do
    test "sudo-valid user links the exact unowned identity", %{conn: conn} do
      user = authenticated_user(user_fixture())

      conn =
        conn
        |> direct_callback_conn(user)
        |> Facebook.put_link_intent(user)
        |> assign(:ueberauth_auth, facebook_auth("link-subject", nil))
        |> FacebookController.callback(%{})

      assert redirected_to(conn) == ~p"/users/settings"
      assert Accounts.get_user_by_identity(:facebook, "link-subject").id == user.id
      assert session_user(conn).id == user.id
    end

    test "provider-only user links Facebook without adding email", %{conn: conn} do
      user = authenticated_user(provider_user_fixture())

      conn =
        conn
        |> direct_callback_conn(user)
        |> Facebook.put_link_intent(user)
        |> assign(:ueberauth_auth, facebook_auth("provider-only-link-subject", nil))
        |> FacebookController.callback(%{})

      assert redirected_to(conn) == ~p"/users/settings"
      assert Accounts.get_user_by_identity(:facebook, "provider-only-link-subject").id == user.id
      assert is_nil(Accounts.get_user!(user.id).email)
    end

    test "link intent bound to another user never switches accounts", %{conn: conn} do
      initiating_user = authenticated_user(user_fixture())
      current_user = authenticated_user(user_fixture())

      conn =
        conn
        |> direct_callback_conn(current_user)
        |> Facebook.put_link_intent(initiating_user)
        |> assign(:ueberauth_auth, facebook_auth("link-subject", nil))
        |> FacebookController.callback(%{})

      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_user_by_identity(:facebook, "link-subject")
      assert session_user(conn).id == current_user.id
    end

    test "identity owned by another user returns a generic conflict", %{conn: conn} do
      owner = user_fixture()
      current_user = authenticated_user(user_fixture())
      assert {:ok, _identity} = Accounts.link_user_identity(owner, :facebook, "owned-subject")

      conn =
        conn
        |> direct_callback_conn(current_user)
        |> Facebook.put_link_intent(current_user)
        |> assign(:ueberauth_auth, facebook_auth("owned-subject", nil))
        |> FacebookController.callback(%{})

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "could not be linked"
      assert Accounts.get_user_by_identity(:facebook, "owned-subject").id == owner.id
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

  defp authenticated_user(user), do: %{user | authenticated_at: DateTime.utc_now(:second)}

  defp facebook_auth(subject, email) do
    %Ueberauth.Auth{
      provider: :facebook,
      uid: subject,
      info: %Ueberauth.Auth.Info{email: email, name: "Discard Me"},
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          user: %{"id" => subject, "email" => email, "name" => "Discard Me"},
          token: %{token: "discard-me"}
        }
      },
      credentials: %Ueberauth.Auth.Credentials{token: "discard-me"}
    }
  end

  defp inertia_request(conn), do: put_req_header(conn, "x-inertia", "true")

  defp restore_application_env(application, key, nil),
    do: Application.delete_env(application, key)

  defp restore_application_env(application, key, value),
    do: Application.put_env(application, key, value)
end
