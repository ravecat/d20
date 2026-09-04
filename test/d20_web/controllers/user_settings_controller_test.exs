defmodule D20Web.UserSettingsControllerTest do
  use D20Web.ConnCase, async: false

  alias D20.Accounts
  alias D20Web.Auth.Apple
  import D20.AccountsFixtures

  setup :register_and_log_in_user

  setup do
    original_apple_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Apple)
    original_discord_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth)

    original_facebook_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)

    original_google_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)
    original_steam_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Steam)

    Application.put_env(:ueberauth, Ueberauth.Strategy.Apple, [])

    Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth,
      client_id: "discord-test-client-id",
      client_secret: "discord-test-client-secret"
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth,
      client_id: "facebook-test-client-id",
      client_secret: "facebook-test-client-secret"
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "google-test-client-id",
      client_secret: "google-test-client-secret"
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, api_key: nil)

    on_exit(fn ->
      restore_application_env(:ueberauth, Ueberauth.Strategy.Apple, original_apple_config)

      restore_application_env(
        :ueberauth,
        Ueberauth.Strategy.Discord.OAuth,
        original_discord_config
      )

      restore_application_env(
        :ueberauth,
        Ueberauth.Strategy.Facebook.OAuth,
        original_facebook_config
      )

      restore_application_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, original_google_config)
      restore_application_env(:ueberauth, Ueberauth.Strategy.Steam, original_steam_config)
    end)
  end

  describe "removed /users/settings route family" do
    test "does not route the page or nested flows" do
      for path <- [
            "/users/settings",
            "/users/settings/auth/google",
            "/users/settings/confirm-email/token"
          ] do
        assert get(build_conn(), path).status == 404
      end
    end

    test "does not route account updates" do
      assert put(build_conn(), "/users/settings", %{}).status == 404
    end
  end

  describe "GET /profile" do
    test "renders settings as an Inertia page", %{conn: conn, user: user} do
      conn = get(conn, ~p"/profile")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert inertia_component(conn) == "account_settings"
      props = inertia_props(conn)

      assert props.email == user.email
      assert props.username == user.username

      assert props.providers == [
               %{
                 available: true,
                 href: ~p"/profile/auth/google",
                 id: "google",
                 linked: false,
                 name: "Google"
               },
               %{
                 available: false,
                 href: ~p"/profile/auth/apple",
                 id: "apple",
                 linked: false,
                 name: "Apple"
               },
               %{
                 available: true,
                 href: ~p"/profile/auth/discord",
                 id: "discord",
                 linked: false,
                 name: "Discord"
               },
               %{
                 available: true,
                 href: ~p"/profile/auth/facebook",
                 id: "facebook",
                 linked: false,
                 name: "Facebook"
               },
               %{
                 available: false,
                 href: ~p"/profile/auth/steam",
                 id: "steam",
                 linked: false,
                 name: "Steam"
               }
             ]

      refute Map.has_key?(props, :apple)
      refute Map.has_key?(props, :discord)
      refute Map.has_key?(props, :facebook)
      refute Map.has_key?(props, :google)
      refute Map.has_key?(props, :steam)
    end

    test "reports a linked Steam method", %{conn: conn, user: user} do
      put_steam_strategy_configured(true)
      assert {:ok, _identity} = Accounts.link_user_identity(user, :steam, "76561198012345678")

      conn = get(conn, ~p"/profile")

      assert Enum.find(inertia_props(conn).providers, &(&1.id == "steam")) == %{
               available: true,
               href: ~p"/profile/auth/steam",
               id: "steam",
               linked: true,
               name: "Steam"
             }
    end

    test "omits Steam when its strategy is unavailable", %{conn: conn} do
      put_steam_strategy_configured(false)

      conn = get(conn, ~p"/profile")

      refute Enum.any?(inertia_props(conn).providers, &(&1.id == "steam" and &1.available))
    end

    test "preserves a linked Steam identity while the strategy is unavailable", %{
      conn: conn,
      user: user
    } do
      put_steam_strategy_configured(true)
      assert {:ok, _identity} = Accounts.link_user_identity(user, :steam, "76561198012345678")
      put_steam_strategy_configured(false)

      conn = get(conn, ~p"/profile")

      assert %{available: false, linked: true} =
               Enum.find(inertia_props(conn).providers, &(&1.id == "steam"))

      assert Accounts.get_user_by_identity(:steam, "76561198012345678").id == user.id
    end

    test "renders provider-only settings with null email and linked identity" do
      user = provider_user_fixture(%{username: "provider_only"}, :google)

      conn = build_conn() |> log_in_user(user) |> get(~p"/profile")

      assert %{email: nil, username: "provider_only", providers: providers} = inertia_props(conn)
      assert Enum.find(providers, &(&1.id == "google")).linked
    end

    test "reports a linked Apple method", %{conn: conn, user: user} do
      put_apple_auth_config()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :apple, "settings-subject")

      conn = get(conn, ~p"/profile")

      assert Enum.find(inertia_props(conn).providers, &(&1.id == "apple")) == %{
               available: true,
               href: ~p"/profile/auth/apple",
               id: "apple",
               linked: true,
               name: "Apple"
             }
    end

    test "converts a verified Apple link cookie to flash", %{conn: conn, user: user} do
      put_apple_auth_config()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :apple, "settings-subject")

      conn = get_settings_with_apple_result(conn, :linked)

      assert redirected_to(conn) == ~p"/profile"
      assert conn.resp_cookies[Apple.link_result_cookie()].max_age == 0
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Apple was linked to this account."
    end

    test "does not trust an Apple result query parameter", %{conn: conn} do
      put_apple_auth_config()

      conn = get(conn, ~p"/profile?apple=linked")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert inertia_component(conn) == "account_settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == nil
    end

    test "keeps provider-owned Apple failures generic", %{conn: conn} do
      conflict_conn = get_settings_with_apple_result(conn, :conflict)

      assert redirected_to(conflict_conn) == ~p"/profile"

      assert Phoenix.Flash.get(conflict_conn.assigns.flash, :error) ==
               "Apple could not be linked because that identity is unavailable."

      failed_conn = get_settings_with_apple_result(conn, :failed)

      assert redirected_to(failed_conn) == ~p"/profile"

      assert Phoenix.Flash.get(failed_conn.assigns.flash, :error) ==
               "Apple could not be linked. Try again."
    end

    test "rejects a signed linked result when Apple is not durably linked", %{conn: conn} do
      conn = get_settings_with_apple_result(conn, :linked)

      assert html_response(conn, 200) =~ ~s(id="app")
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == nil
      assert conn.resp_cookies[Apple.link_result_cookie()].max_age == 0
    end

    test "reports a linked Discord method", %{conn: conn, user: user} do
      assert {:ok, _identity} = Accounts.link_user_identity(user, :discord, "settings-subject")

      conn = get(conn, ~p"/profile")

      assert Enum.find(inertia_props(conn).providers, &(&1.id == "discord")) == %{
               available: true,
               href: ~p"/profile/auth/discord",
               id: "discord",
               linked: true,
               name: "Discord"
             }
    end

    test "reports Discord as unavailable without hiding linked state", %{conn: conn, user: user} do
      previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth)

      on_exit(fn ->
        restore_application_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth, previous_config)
      end)

      Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth,
        client_id: nil,
        client_secret: nil
      )

      assert {:ok, _identity} = Accounts.link_user_identity(user, :discord, "settings-subject")

      conn = get(conn, ~p"/profile")

      assert Enum.find(inertia_props(conn).providers, &(&1.id == "discord")) == %{
               available: false,
               href: ~p"/profile/auth/discord",
               id: "discord",
               linked: true,
               name: "Discord"
             }
    end

    test "reports a linked Facebook method", %{conn: conn, user: user} do
      assert {:ok, _identity} = Accounts.link_user_identity(user, :facebook, "settings-subject")

      conn = get(conn, ~p"/profile")

      assert Enum.find(inertia_props(conn).providers, &(&1.id == "facebook")) == %{
               available: true,
               href: ~p"/profile/auth/facebook",
               id: "facebook",
               linked: true,
               name: "Facebook"
             }
    end

    test "reports a linked Google method", %{conn: conn, user: user} do
      assert {:ok, _identity} = Accounts.link_user_identity(user, :google, "settings-subject")

      conn = get(conn, ~p"/profile")

      assert Enum.find(inertia_props(conn).providers, &(&1.id == "google")) == %{
               available: true,
               href: ~p"/profile/auth/google",
               id: "google",
               linked: true,
               name: "Google"
             }
    end

    test "reports Google as unavailable without hiding linked state", %{conn: conn, user: user} do
      previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)

      on_exit(fn ->
        restore_application_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, previous_config)
      end)

      Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
        client_id: nil,
        client_secret: nil
      )

      assert {:ok, _identity} = Accounts.link_user_identity(user, :google, "settings-subject")

      conn = get(conn, ~p"/profile")

      assert Enum.find(inertia_props(conn).providers, &(&1.id == "google")) == %{
               available: false,
               href: ~p"/profile/auth/google",
               id: "google",
               linked: true,
               name: "Google"
             }
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/profile")
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).reauthenticate == false
      assert get_session(conn, :auth_prompt).return_to == "/profile"
    end

    @tag token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -11, :minute)
    test "redirects if user is not in sudo mode", %{conn: conn} do
      conn = get(conn, ~p"/profile")
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).reauthenticate == true
      assert get_session(conn, :auth_prompt).return_to == "/profile"
    end
  end

  describe "PUT /profile (change password form)" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, ~p"/profile", %{
          "action" => "update_password",
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == ~p"/profile"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_identifier_and_password(user.email, "new valid password")
    end

    test "sets a username password for a provider-only user" do
      user = provider_user_fixture(%{username: "provider_only"}, :google)

      conn =
        build_conn()
        |> log_in_user(user)
        |> put(~p"/profile", %{
          "action" => "update_password",
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == ~p"/profile"
      assert Accounts.get_user_by_identifier_and_password("provider_only", "new valid password")
      assert Accounts.get_user!(user.id).email == nil
    end

    test "returns flat password validation through the Inertia redirect", %{conn: conn} do
      old_password_conn =
        conn
        |> inertia_request()
        |> put(~p"/profile", %{
          "action" => "update_password",
          "user" => %{"password" => "too short", "password_confirmation" => "does not match"}
        })

      assert redirected_to(old_password_conn, 303) == ~p"/profile"

      response_conn = follow_inertia_redirect(old_password_conn)

      assert %{
               password: "should be at least 12 character(s)",
               password_confirmation: "does not match password"
             } = inertia_errors(response_conn)

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /profile (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/profile", %{
          "action" => "update_email",
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == ~p"/profile"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "A link to confirm your email"

      assert Accounts.get_user_by_email(user.email)
    end

    @tag :capture_log
    test "ignores a forged administrator role when updating settings", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/profile", %{
          "action" => "update_email",
          "user" => %{"email" => unique_user_email(), "role" => "admin"}
        })

      assert redirected_to(conn) == ~p"/profile"
      assert Accounts.get_user!(user.id).role == :user
    end

    test "starts first-email verification without persisting the candidate" do
      assert_receive {:email, _setup_email}
      user = provider_user_fixture(%{username: "provider_only"}, :google)
      email = unique_user_email()

      conn =
        build_conn()
        |> log_in_user(user)
        |> put(~p"/profile", %{"action" => "update_email", "user" => %{"email" => email}})

      assert redirected_to(conn) == ~p"/profile"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "confirm your email"
      assert Accounts.get_user!(user.id).email == nil

      assert_receive {:email, %Swoosh.Email{text_body: body}}
      [_, token] = Regex.run(~r{/profile/confirm-email/([^\s]+)}, body)

      confirmed_conn = conn |> recycle() |> get(~p"/profile/confirm-email/#{token}")
      assert redirected_to(confirmed_conn) == ~p"/profile"
      assert Accounts.get_user!(user.id).email == email
    end

    test "returns flat email validation through the Inertia redirect", %{conn: conn} do
      conn =
        conn
        |> inertia_request()
        |> put(~p"/profile", %{"action" => "update_email", "user" => %{"email" => "with spaces"}})

      assert redirected_to(conn, 303) == ~p"/profile"

      response_conn = follow_inertia_redirect(conn)

      assert inertia_errors(response_conn) == %{email: "must have the @ sign and no spaces"}
    end
  end

  describe "GET /profile/confirm-email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, ~p"/profile/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/profile"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Email changed successfully"

      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, ~p"/profile/confirm-email/#{token}")

      assert redirected_to(conn) == ~p"/profile"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/profile/confirm-email/oops")
      assert redirected_to(conn) == ~p"/profile"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, ~p"/profile/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).reauthenticate == false
      assert get_session(conn, :auth_prompt).return_to == "/profile/confirm-email/#{token}"
    end
  end

  defp inertia_request(conn) do
    put_req_header(conn, "x-inertia", "true")
  end

  defp follow_inertia_redirect(conn) do
    redirect_path = redirected_to(conn, 303)

    conn
    |> recycle()
    |> inertia_request()
    |> get(redirect_path)
  end

  defp put_apple_auth_config do
    previous_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Apple)

    Application.put_env(:ueberauth, Ueberauth.Strategy.Apple,
      client_id: "com.example.d20.web",
      team_id: "TEAM123456",
      key_id: "KEY1234567",
      private_key_base64: "test-private-key",
      callback_url: "https://accounts.example.com/auth/apple/callback"
    )

    on_exit(fn ->
      restore_application_env(:ueberauth, Ueberauth.Strategy.Apple, previous_config)
    end)
  end

  defp put_steam_strategy_configured(configured?) do
    previous_config = Application.fetch_env!(:ueberauth, Ueberauth)
    previous_steam = Application.get_env(:ueberauth, Ueberauth.Strategy.Steam)

    providers =
      previous_config
      |> Keyword.fetch!(:providers)
      |> then(fn providers ->
        if configured? do
          Keyword.put(
            providers,
            :steam,
            {Ueberauth.Strategy.Steam,
             [request_path: "/auth/steam", callback_path: "/auth/steam/callback"]}
          )
        else
          Keyword.delete(providers, :steam)
        end
      end)

    Application.put_env(
      :ueberauth,
      Ueberauth,
      Keyword.put(previous_config, :providers, providers)
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Steam,
      api_key: if(configured?, do: "steam-api-key")
    )

    on_exit(fn ->
      Application.put_env(:ueberauth, Ueberauth, previous_config)
      restore_application_env(:ueberauth, Ueberauth.Strategy.Steam, previous_steam)
    end)
  end

  defp get_settings_with_apple_result(conn, result) do
    cookie =
      build_conn()
      |> Apple.put_link_result(result)
      |> then(& &1.resp_cookies[Apple.link_result_cookie()].value)

    conn
    |> put_req_cookie(Apple.link_result_cookie(), cookie)
    |> get(~p"/profile")
  end

  defp restore_application_env(application, key, nil),
    do: Application.delete_env(application, key)

  defp restore_application_env(application, key, value),
    do: Application.put_env(application, key, value)
end
