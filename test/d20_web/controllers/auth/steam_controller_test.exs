defmodule D20Web.Auth.SteamControllerTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts
  alias D20.Accounts.User
  alias D20.Accounts.UserIdentity
  alias D20Web.Auth.Steam
  alias D20Web.Auth.SteamController

  @steam_id "76561198012345678"

  setup do
    previous_ueberauth = Application.fetch_env!(:ueberauth, Ueberauth)
    previous_steam = Application.get_env(:ueberauth, Ueberauth.Strategy.Steam)

    Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, api_key: "steam-api-key")

    on_exit(fn ->
      Application.put_env(:ueberauth, Ueberauth, previous_ueberauth)

      if previous_steam,
        do: Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, previous_steam),
        else: Application.delete_env(:ueberauth, Ueberauth.Strategy.Steam)
    end)
  end

  describe "GET /auth/steam" do
    test "fails locally when the community adapter API key is missing", %{conn: conn} do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, api_key: nil)

      {conn, log} =
        ExUnit.CaptureLog.with_log(fn -> get(conn, "/auth/steam?return_to=%2Fgames%2Fqwinto") end)

      assert redirected_to(conn) == "/games/qwinto"
      assert get_session(conn, :auth_prompt).message =~ "temporarily unavailable"
      refute redirected_to(conn) =~ "steamcommunity.com"
      refute log =~ "steam-api-key"
    end

    test "invokes the allowlisted community strategy and ignores injected provider params", %{
      conn: conn
    } do
      conn =
        get(
          conn,
          "/auth/steam?return_to=%2Fgames%2Fqwinto&openid.realm=https%3A%2F%2Fevil.example&openid.return_to=https%3A%2F%2Fevil.example%2Fcb&openid.mode=cancel&state=attacker"
        )

      location = redirected_to(conn, 302)
      uri = URI.parse(location)
      query = URI.decode_query(uri.query)

      assert uri.scheme == "https"
      assert uri.host == "steamcommunity.com"
      assert uri.path == "/openid/login"
      assert query["openid.mode"] == "checkid_setup"
      assert query["openid.ns"] == "http://specs.openid.net/auth/2.0"
      refute location =~ "evil.example"
      refute location =~ "attacker"
      assert is_binary(get_session(conn, "ueberauth_steam_state"))
      assert get_session(conn, :return_to) == "/games/qwinto"
      assert {:ok, :authenticate} = Steam.fetch_intent(conn)
    end

    test "starts account-bound reauthentication through the same request route", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> get(~p"/auth/steam?intent=reauthenticate&return_to=/users/settings")

      assert redirected_to(conn, 302) =~ "https://steamcommunity.com/openid/login?"
      assert {:ok, {:reauthenticate, user_id}} = Steam.fetch_intent(conn)
      assert user_id == to_string(user.id)
    end
  end

  describe "community adapter callback boundary" do
    test "logs in the exact identity owner, rotates the session, and consumes intent", %{
      conn: conn
    } do
      user = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :steam, @steam_id)

      conn =
        conn
        |> direct_callback_conn(nil, return_to: "/games/qwinto", anonymous_user_id: "actor-old")
        |> Steam.put_authenticate_intent()
        |> assign(:ueberauth_auth, steam_auth())
        |> SteamController.callback(%{})

      assert redirected_to(conn) == "/games/qwinto"
      refute get_session(conn, :anonymous_user_id)
      assert session_user(conn).id == user.id
      assert {:error, :invalid_or_expired_intent} = Steam.fetch_intent(conn)

      repeated =
        build_conn()
        |> direct_callback_conn(nil, return_to: "/games/qwinto")
        |> assign(:ueberauth_auth, steam_auth())
        |> SteamController.callback(%{})

      assert redirected_to(repeated) == "/games/qwinto"
      refute get_session(repeated, :user_token)
      assert get_session(repeated, :auth_prompt).message =~ "could not be completed"
    end

    test "trusts the normalized community result instead of revalidating callback fields", %{
      conn: conn
    } do
      user = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :steam, @steam_id)

      conn =
        conn
        |> direct_callback_conn()
        |> Steam.put_authenticate_intent()
        |> assign(:ueberauth_auth, steam_auth())
        |> SteamController.callback(%{
          "openid.identity" => "https://steamcommunity.com/openid/id/76561198000000000"
        })

      assert session_user(conn).id == user.id
      assert D20.Repo.aggregate(User, :count) == 1
    end

    test "starts provider-only completion for an unknown verified SteamID", %{conn: conn} do
      conn =
        conn
        |> direct_callback_conn()
        |> Steam.put_authenticate_intent()
        |> assign(:ueberauth_auth, steam_auth())
        |> SteamController.callback(%{})

      assert redirected_to(conn) == ~p"/auth/steam/register"
      refute get_session(conn, :user_token)
      assert {:ok, %{provider_uid: @steam_id}} = Steam.fetch_registration(conn)
      assert D20.Repo.aggregate(User, :count) == 0
      assert D20.Repo.aggregate(UserIdentity, :count) == 0
    end

    test "keeps reauthentication bound to the current exact identity", %{conn: conn} do
      user = authenticated_user(user_fixture())
      assert {:ok, _identity} = Accounts.link_user_identity(user, :steam, @steam_id)

      success =
        conn
        |> direct_callback_conn(user, return_to: "/users/settings")
        |> Steam.put_reauthenticate_intent(user)
        |> assign(:ueberauth_auth, steam_auth())
        |> SteamController.callback(%{})

      assert redirected_to(success) == ~p"/users/settings"
      assert session_user(success).id == user.id

      other = authenticated_user(user_fixture())

      failure =
        build_conn()
        |> direct_callback_conn(other, return_to: "/users/settings")
        |> Steam.put_reauthenticate_intent(other)
        |> assign(:ueberauth_auth, steam_auth())
        |> SteamController.callback(%{})

      assert redirected_to(failure) == ~p"/users/settings"
      assert session_user(failure).id == other.id
      assert get_session(failure, :auth_prompt).reauthenticate
    end

    test "normalizes community failures without exposing profile or callback data", %{conn: conn} do
      failure = %Ueberauth.Failure{
        provider: :steam,
        errors: [%Ueberauth.Failure.Error{message_key: "invalid_user", message: "profile failed"}]
      }

      {conn, log} =
        ExUnit.CaptureLog.with_log(fn ->
          conn
          |> direct_callback_conn(nil, return_to: "/games/qwinto")
          |> Steam.put_authenticate_intent()
          |> assign(:ueberauth_failure, failure)
          |> SteamController.callback(%{"openid.sig" => "secret-signature"})
        end)

      assert redirected_to(conn) == "/games/qwinto"
      refute get_session(conn, :user_token)
      assert get_session(conn, :auth_prompt).message =~ "could not be completed"
      refute log =~ "profile failed"
      refute log =~ "secret-signature"
    end
  end

  describe "Steam provider-only registration completion" do
    test "renders the shared username page without exposing Steam or adapter data", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Steam.put_registration(%{provider_uid: @steam_id})
        |> get(~p"/auth/steam/register")

      assert inertia_component(conn) == "registration_completion"

      assert %{
               email: nil,
               submission: %{
                 action: "/auth/steam/register",
                 credential: %{type: "server_session"}
               },
               cancelAction: "/auth/steam/register/cancel"
             } = props = inertia_props(conn)

      refute Map.has_key?(props, :provider_uid)
      refute Map.has_key?(props, :steam_id)
      refute Map.has_key?(props, :api_key)
      refute Map.has_key?(props, :profile)
    end

    test "creates and authenticates one provider-only account while ignoring forged email", %{
      conn: conn
    } do
      conn =
        conn
        |> init_test_session(return_to: "/games/qwinto")
        |> Steam.put_registration(%{provider_uid: @steam_id})
        |> post(~p"/auth/steam/register", %{
          "user" => %{
            "username" => "steam_player",
            "remember_me" => "true",
            "email" => "forged@example.com"
          }
        })

      assert redirected_to(conn) == "/games/qwinto"
      assert conn.resp_cookies["_d20_web_user_remember_me"]

      assert %User{email: nil, username: "steam_player", confirmed_at: confirmed_at} =
               user = Accounts.get_user_by_identity(:steam, @steam_id)

      assert confirmed_at
      assert session_user(conn).id == user.id
      assert {:error, :invalid_or_expired_completion} = Steam.fetch_registration(conn)
    end

    test "keeps completion after username validation failure", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Steam.put_registration(%{provider_uid: @steam_id})
        |> inertia_request()
        |> post(~p"/auth/steam/register", %{"user" => %{"username" => "invalid name"}})

      assert redirected_to(conn, 303) == ~p"/auth/steam/register"
      assert {:ok, %{provider_uid: @steam_id}} = Steam.fetch_registration(conn)
      assert D20.Repo.aggregate(User, :count) == 0
      assert D20.Repo.aggregate(UserIdentity, :count) == 0

      response_conn = follow_inertia_redirect(conn)
      assert %{username: _message} = inertia_errors(response_conn)
    end

    test "rolls back and clears completion when the SteamID gained an owner", %{conn: conn} do
      owner = user_fixture()
      assert {:ok, _identity} = Accounts.link_user_identity(owner, :steam, @steam_id)

      conn =
        conn
        |> init_test_session(%{})
        |> Steam.put_registration(%{provider_uid: @steam_id})
        |> post(~p"/auth/steam/register", %{"user" => %{"username" => "losing_player"}})

      assert redirected_to(conn) == ~p"/"
      assert {:error, :invalid_or_expired_completion} = Steam.fetch_registration(conn)
      refute D20.Repo.get_by(User, username: "losing_player")
      assert Accounts.get_user_by_identity(:steam, @steam_id).id == owner.id
    end

    test "clears completion when the player cancels", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Steam.put_registration(%{provider_uid: @steam_id})
        |> post(~p"/auth/steam/register/cancel")

      assert redirected_to(conn) == ~p"/"
      assert {:error, :invalid_or_expired_completion} = Steam.fetch_registration(conn)
      assert D20.Repo.aggregate(User, :count) == 0
    end
  end

  describe "GET /users/settings/auth/steam" do
    test "requires authentication and sudo mode", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/auth/steam")
      assert redirected_to(conn) == ~p"/"

      old_authentication = DateTime.add(DateTime.utc_now(:second), -11, :minute)
      user = user_fixture()

      stale_conn =
        build_conn()
        |> log_in_user(user, token_authenticated_at: old_authentication)
        |> get(~p"/users/settings/auth/steam")

      assert redirected_to(stale_conn) == ~p"/"
      assert get_session(stale_conn, :auth_prompt).reauthenticate
    end

    test "stores a user-bound link intent", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get(~p"/users/settings/auth/steam")

      assert redirected_to(conn) == ~p"/auth/steam"
      assert {:ok, {:link, user_id}} = Steam.fetch_intent(conn)
      assert user_id == to_string(user.id)
    end

    test "links only to the same sudo-valid user and reports conflicts generically", %{conn: conn} do
      user = authenticated_user(user_fixture())

      linked =
        conn
        |> direct_callback_conn(user)
        |> Steam.put_link_intent(user)
        |> assign(:ueberauth_auth, steam_auth())
        |> SteamController.callback(%{})

      assert redirected_to(linked) == ~p"/users/settings"
      assert Accounts.get_user_by_identity(:steam, @steam_id).id == user.id

      other = authenticated_user(user_fixture())

      conflict =
        build_conn()
        |> direct_callback_conn(other)
        |> Steam.put_link_intent(other)
        |> assign(:ueberauth_auth, steam_auth())
        |> SteamController.callback(%{})

      assert redirected_to(conflict) == ~p"/users/settings"
      assert Phoenix.Flash.get(conflict.assigns.flash, :error) =~ "could not be linked"
      assert Accounts.get_user_by_identity(:steam, @steam_id).id == user.id
    end
  end

  describe "callback diagnostics" do
    test "global Phoenix filtering covers Steam OpenID callback values" do
      sensitive = %{
        "openid.claimed_id" => @steam_id,
        "openid.identity" => @steam_id,
        "openid.response_nonce" => "nonce",
        "openid.sig" => "signature",
        "state" => "state"
      }

      assert Map.new(sensitive, fn {key, _value} -> {key, "[FILTERED]"} end) ==
               Phoenix.Logger.filter_values(sensitive)
    end

    test "unavailable callback uses standard filtered logs and starts no provider call", %{
      conn: conn
    } do
      Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, api_key: nil)
      secret = "76561198012345678-secret-signature"

      {conn, log} =
        ExUnit.CaptureLog.with_log(fn ->
          conn
          |> init_test_session(return_to: "/")
          |> Steam.put_authenticate_intent()
          |> get(
            "/auth/steam/callback?openid.mode=id_res&openid.claimed_id=#{@steam_id}&openid.sig=#{secret}"
          )
        end)

      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      refute log =~ @steam_id
      refute log =~ secret
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

  defp steam_auth do
    %Ueberauth.Auth{
      provider: :steam,
      uid: String.to_integer(@steam_id),
      info: %Ueberauth.Auth.Info{name: "Transient persona", image: "https://steam/avatar"},
      extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{realname: "Transient profile"}}},
      credentials: %Ueberauth.Auth.Credentials{}
    }
  end

  defp inertia_request(conn), do: put_req_header(conn, "x-inertia", "true")

  defp follow_inertia_redirect(conn) do
    conn
    |> recycle()
    |> inertia_request()
    |> get(redirected_to(conn, 303))
  end
end
