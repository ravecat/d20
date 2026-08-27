defmodule D20Web.Auth.AppleControllerTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts
  alias D20.Accounts.User
  alias D20Web.Auth.Apple
  alias D20Web.Auth.AppleController
  alias Ueberauth.Auth
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Auth.Info
  alias Ueberauth.Strategy.Apple, as: AppleStrategy

  setup do
    original_apple_config = Application.get_env(:ueberauth, AppleStrategy)
    {_metadata, private_key} = {:ec, "P-256"} |> JOSE.JWK.generate_key() |> JOSE.JWK.to_pem()

    Application.put_env(:ueberauth, AppleStrategy,
      client_id: "com.example.d20.web",
      team_id: "TEAM123456",
      key_id: "KEY1234567",
      private_key_base64: Base.encode64(private_key),
      callback_url: "https://accounts.example.com/auth/apple/callback"
    )

    on_exit(fn -> restore_env(:ueberauth, AppleStrategy, original_apple_config) end)

    :ok
  end

  describe "provider request and routes" do
    test "disabled provider fails closed", %{conn: conn} do
      Application.put_env(:ueberauth, AppleStrategy, [])

      conn = get(conn, ~p"/auth/apple")

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).kind == :error
      assert get_session(conn, :auth_prompt).message =~ "temporarily unavailable"
      refute conn.resp_cookies[Apple.flow_cookie()]
    end

    test "uses fixed email scope, form_post, nonce state, and a safe return", %{conn: conn} do
      conn =
        get(
          conn,
          "/auth/apple?scope=name&response_mode=query&return_to=" <>
            URI.encode_www_form("https://evil.example/steal")
        )

      location = redirected_to(conn)
      query = location |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

      assert String.starts_with?(location, "https://appleid.apple.com/auth/authorize?")
      assert query["client_id"] == "com.example.d20.web"
      assert query["scope"] == "email"
      assert query["response_mode"] == "form_post"
      assert query["response_type"] == "code id_token"
      assert query["redirect_uri"] == "https://accounts.example.com/auth/apple/callback"
      assert query["state"] == query["nonce"]

      assert conn.resp_cookies["ueberauth.state_param"].same_site == "None"
      assert conn.resp_cookies["ueberauth.state_param"].secure

      attempt_cookie = conn.resp_cookies[Apple.flow_cookie()]
      request = request_with_cookie(Apple.flow_cookie(), attempt_cookie.value)

      assert {_, {:ok, %{action: :authenticate, return_to: "/"}}} = Apple.consume_attempt(request)
    end

    test "requires a sudo-valid session and binds linking to that exact user", %{conn: conn} do
      user = user_fixture()

      signed_out_conn = get(conn, ~p"/users/settings/auth/apple")
      assert redirected_to(signed_out_conn) == ~p"/"
      refute signed_out_conn.resp_cookies[Apple.flow_cookie()]

      stale_conn =
        conn
        |> log_in_user(user,
          token_authenticated_at: DateTime.add(DateTime.utc_now(), -11, :minute)
        )
        |> get(~p"/users/settings/auth/apple")

      assert redirected_to(stale_conn) == ~p"/"
      refute stale_conn.resp_cookies[Apple.flow_cookie()]

      link_conn = build_conn() |> log_in_user(user) |> get(~p"/users/settings/auth/apple")
      assert redirected_to(link_conn) == ~p"/auth/apple?intent=link"

      linked_conn = link_conn |> recycle() |> get(redirected_to(link_conn))

      assert redirected_to(linked_conn) =~ "https://appleid.apple.com/auth/authorize?"

      request =
        request_with_cookie(
          Apple.flow_cookie(),
          linked_conn.resp_cookies[Apple.flow_cookie()].value
        )

      assert {_, {:ok, %{action: :link, return_to: "/users/settings", user_id: user_id}}} =
               Apple.consume_attempt(request)

      assert user_id == to_string(user.id)
    end

    test "binds reauthentication requests to the current user", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/auth/apple?intent=reauthenticate&return_to=/users/settings")

      request =
        request_with_cookie(Apple.flow_cookie(), conn.resp_cookies[Apple.flow_cookie()].value)

      assert {_, {:ok, %{action: :reauthenticate, user_id: user_id}}} =
               Apple.consume_attempt(request)

      assert user_id == to_string(user.id)
    end

    test "exposes only GET request and POST callback methods", %{conn: conn} do
      assert response(get(conn, "/auth/apple/callback"), 404)
      assert response(post(conn, "/auth/apple"), 404)
      assert response(get(conn, "/auth/facebook"), 404)
    end
  end

  describe "callback" do
    test "logs in an exact returning Apple subject and renews the session", %{conn: conn} do
      user = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :apple, "000321.returning")

      conn =
        conn
        |> callback_conn(%{action: :authenticate, return_to: "/games", user_id: nil})
        |> assign(:ueberauth_auth, apple_auth("000321.returning", nil))
        |> AppleController.callback(%{})

      assert redirected_to(conn) == "/games"
      refute get_session(conn, :fixation_marker)

      assert {logged_in_user, _inserted_at} =
               Accounts.get_user_by_session_token(get_session(conn, :user_token))

      assert logged_in_user.id == user.id
      assert conn.private.plug_session_info == :renew
      assert conn.resp_cookies[Apple.flow_cookie()].max_age == 0
    end

    test "reauthenticates only the current user with an exact linked subject", %{conn: conn} do
      user = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :apple, "000321.reauth")

      conn =
        conn
        |> callback_conn(%{
          action: :reauthenticate,
          return_to: "/users/settings",
          user_id: to_string(user.id)
        })
        |> assign(:ueberauth_auth, apple_auth("000321.reauth", nil))
        |> AppleController.callback(%{})

      assert redirected_to(conn) == ~p"/users/settings"

      assert {session_user, _inserted_at} =
               Accounts.get_user_by_session_token(get_session(conn, :user_token))

      assert session_user.id == user.id
    end

    test "does not switch accounts during Apple reauthentication", %{conn: conn} do
      current_user = user_fixture()
      other_user = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(other_user, :apple, "000321.other")

      conn =
        conn
        |> callback_conn(%{
          action: :reauthenticate,
          return_to: "/users/settings",
          user_id: to_string(current_user.id)
        })
        |> put_session(:user_token, Accounts.generate_user_session_token(current_user))
        |> assign(:current_user, current_user)
        |> assign(:ueberauth_auth, apple_auth("000321.other", nil))
        |> AppleController.callback(%{})

      assert redirected_to(conn) == ~p"/auth/apple/reauthentication"
      assert conn.resp_cookies[Apple.reauthentication_result_cookie()]
      refute get_session(conn, :auth_prompt)

      result_cookie = conn.resp_cookies[Apple.reauthentication_result_cookie()].value

      same_site_conn =
        build_conn()
        |> log_in_user(current_user)
        |> put_req_cookie(Apple.reauthentication_result_cookie(), result_cookie)
        |> get(~p"/auth/apple/reauthentication")

      assert redirected_to(same_site_conn) == ~p"/"
      assert %{reauthenticate: true} = get_session(same_site_conn, :auth_prompt)
      assert same_site_conn.resp_cookies[Apple.reauthentication_result_cookie()].max_age == 0

      assert {session_user, _inserted_at} =
               Accounts.get_user_by_session_token(get_session(same_site_conn, :user_token))

      assert session_user.id == current_user.id
    end

    test "starts username completion for a new subject with a signed email", %{conn: conn} do
      conn =
        conn
        |> callback_conn(%{action: :authenticate, return_to: "/games/qwinto", user_id: nil})
        |> assign(:ueberauth_auth, apple_auth("000321.new", "relay@privaterelay.appleid.com"))
        |> AppleController.callback(%{})

      assert redirected_to(conn) == ~p"/auth/apple/register"
      assert conn.resp_cookies[Apple.flow_cookie()].same_site == "Lax"
      refute Accounts.get_user_by_identity(:apple, "000321.new")
    end

    test "starts distinct registration instead of merging an existing email", %{conn: conn} do
      existing_user = user_fixture()

      conn =
        conn
        |> callback_conn(%{action: :authenticate, return_to: "/games", user_id: nil})
        |> assign(
          :ueberauth_auth,
          apple_auth("000321.email-match", String.upcase(existing_user.email))
        )
        |> AppleController.callback(%{})

      assert redirected_to(conn) == ~p"/auth/apple/register"
      refute get_session(conn, :user_token)
      refute Accounts.get_user_by_identity(:apple, "000321.email-match")
      assert Accounts.get_user_by_email(existing_user.email).id == existing_user.id
    end

    test "starts provider-only registration for an unknown subject without email", %{conn: conn} do
      conn =
        conn
        |> callback_conn(%{action: :authenticate, return_to: "/", user_id: nil})
        |> assign(:ueberauth_auth, apple_auth("000321.no-email", nil))
        |> AppleController.callback(%{})

      assert redirected_to(conn) == ~p"/auth/apple/register"
      refute get_session(conn, :user_token)
      assert conn.resp_cookies[Apple.flow_cookie()].same_site == "Lax"
    end

    test "does not overwrite the Lax application session on a cross-site link callback", %{
      conn: conn
    } do
      user = user_fixture()

      attempt_response =
        conn
        |> init_test_session(%{})
        |> Apple.put_attempt(%{
          action: :link,
          return_to: "/users/settings",
          user_id: to_string(user.id)
        })

      conn =
        build_conn()
        |> put_req_cookie(
          Apple.flow_cookie(),
          attempt_response.resp_cookies[Apple.flow_cookie()].value
        )
        |> put_req_cookie("ueberauth.state_param", "apple-state")
        |> post(~p"/auth/apple/callback", %{"error" => "user_cancelled", "state" => "apple-state"})

      assert redirected_to(conn) == "/users/settings"
      assert conn.resp_cookies[Apple.link_result_cookie()]
      refute conn.resp_cookies["_d20_key"]
    end
  end

  describe "registration completion" do
    test "renders the shared page without exposing the Apple identity or flow state", %{
      conn: conn
    } do
      cookie =
        registration_cookie(conn, %{
          provider_uid: "private-apple-subject",
          email: "relay@privaterelay.appleid.com",
          return_to: "/games"
        })

      conn =
        conn |> request_with_cookie(Apple.flow_cookie(), cookie) |> get(~p"/auth/apple/register")

      assert inertia_component(conn) == "registration_completion"

      assert %{
               email: "relay@privaterelay.appleid.com",
               submission: %{action: "/auth/apple/register", credential: %{type: "server_cookie"}},
               cancelAction: "/auth/apple/register/cancel"
             } = props = inertia_props(conn)

      refute Map.has_key?(props, :provider_uid)
      refute Map.has_key?(props, :token)
    end

    test "retries username validation with the same flow state, then registers atomically", %{
      conn: conn
    } do
      completion = %{
        provider_uid: "000321.complete",
        email: "relay@privaterelay.appleid.com",
        return_to: "/games"
      }

      cookie = registration_cookie(conn, completion)

      invalid_conn =
        conn
        |> request_with_cookie(Apple.flow_cookie(), cookie)
        |> post(~p"/auth/apple/register", %{"user" => %{"username" => "-invalid-"}})

      assert redirected_to(invalid_conn, 303) == ~p"/auth/apple/register"
      refute invalid_conn.resp_cookies[Apple.flow_cookie()]
      refute Accounts.get_user_by_identity(:apple, "000321.complete")

      valid_conn =
        build_conn()
        |> request_with_cookie(Apple.flow_cookie(), cookie)
        |> post(~p"/auth/apple/register", %{
          "user" => %{"username" => "apple_player", "remember_me" => "true"}
        })

      assert redirected_to(valid_conn) == "/games"
      assert valid_conn.resp_cookies[Apple.flow_cookie()].max_age == 0

      assert %User{username: "apple_player", confirmed_at: confirmed_at} =
               Accounts.get_user_by_identity(:apple, "000321.complete")

      assert confirmed_at

      assert {_user, _inserted_at} =
               Accounts.get_user_by_session_token(get_session(valid_conn, :user_token))
    end

    test "creates a provider-only account when completion has no email", %{conn: conn} do
      cookie =
        registration_cookie(conn, %{
          provider_uid: "000321.provider-only",
          email: nil,
          return_to: "/"
        })

      conn =
        conn
        |> request_with_cookie(Apple.flow_cookie(), cookie)
        |> post(~p"/auth/apple/register", %{"user" => %{"username" => "apple_only"}})

      assert redirected_to(conn) == ~p"/"

      assert %User{email: nil, username: "apple_only"} =
               Accounts.get_user_by_identity(:apple, "000321.provider-only")
    end

    test "discards an already-owned email during Apple completion", %{conn: conn} do
      owner = user_fixture()

      cookie =
        registration_cookie(conn, %{
          provider_uid: "000321.owned-email",
          email: String.upcase(owner.email),
          return_to: "/"
        })

      conn =
        conn
        |> request_with_cookie(Apple.flow_cookie(), cookie)
        |> post(~p"/auth/apple/register", %{"user" => %{"username" => "apple_distinct"}})

      assert redirected_to(conn) == ~p"/"

      assert %User{email: nil, username: "apple_distinct"} =
               Accounts.get_user_by_identity(:apple, "000321.owned-email")

      assert Accounts.get_user_by_email(owner.email).id == owner.id
    end

    test "rejects missing registration state", %{conn: conn} do
      conn = post conn, ~p"/auth/apple/register", %{"user" => %{"username" => "player"}}

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
    end
  end

  describe "linking" do
    test "links the exact subject to the flow-bound user and is idempotent", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> callback_conn(%{
          action: :link,
          return_to: "/users/settings",
          user_id: to_string(user.id)
        })
        |> assign(:ueberauth_auth, apple_auth("000321.link", user.email))
        |> AppleController.callback(%{})

      assert redirected_to(conn) == "/users/settings"
      assert conn.resp_cookies[Apple.link_result_cookie()]
      assert Accounts.get_user_by_identity(:apple, "000321.link").id == user.id
      refute get_session(conn, :user_token)

      second_conn =
        build_conn()
        |> callback_conn(%{
          action: :link,
          return_to: "/users/settings",
          user_id: to_string(user.id)
        })
        |> assign(:ueberauth_auth, apple_auth("000321.link", nil))
        |> AppleController.callback(%{})

      assert redirected_to(second_conn) == "/users/settings"
      assert second_conn.resp_cookies[Apple.link_result_cookie()]
      assert length(Accounts.list_user_identities(user)) == 1
    end

    test "keeps ownership conflicts generic", %{conn: conn} do
      owner = user_fixture()
      requester = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(owner, :apple, "000321.owned")

      conn =
        conn
        |> callback_conn(%{
          action: :link,
          return_to: "/users/settings",
          user_id: to_string(requester.id)
        })
        |> assign(:ueberauth_auth, apple_auth("000321.owned", requester.email))
        |> AppleController.callback(%{})

      assert redirected_to(conn) == "/users/settings"
      assert conn.resp_cookies[Apple.link_result_cookie()]
      assert Accounts.get_user_by_identity(:apple, "000321.owned").id == owner.id
      refute get_session(conn, :user_token)
    end
  end

  defp apple_auth(uid, email) do
    %Auth{
      provider: :apple,
      uid: uid,
      info: %Info{email: email},
      credentials: %Credentials{token: "secret-access-token"},
      extra: %Extra{raw_info: %{id_token: "secret-id-token"}}
    }
  end

  defp callback_conn(conn, attempt) do
    response = conn |> init_test_session(%{}) |> Apple.put_attempt(attempt)

    conn
    |> recycle()
    |> init_test_session(%{fixation_marker: "must-be-cleared"})
    |> Phoenix.Controller.fetch_flash([])
    |> put_req_cookie(Apple.flow_cookie(), response.resp_cookies[Apple.flow_cookie()].value)
  end

  defp registration_cookie(conn, completion) do
    conn
    |> init_test_session(%{})
    |> Apple.put_registration(completion)
    |> then(& &1.resp_cookies[Apple.flow_cookie()].value)
  end

  defp request_with_cookie(conn, name, value) do
    conn
    |> Map.replace!(:secret_key_base, D20Web.Endpoint.config(:secret_key_base))
    |> put_req_cookie(name, value)
  end

  defp request_with_cookie(name, value), do: request_with_cookie(build_conn(), name, value)

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
