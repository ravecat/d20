defmodule D20Web.UserSettingsControllerTest do
  use D20Web.ConnCase, async: false

  alias D20.Accounts
  alias D20Web.Auth.Apple
  import D20.AccountsFixtures

  setup :register_and_log_in_user

  setup do
    original_apple_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Apple)
    original_discord_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth)

    original_google_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)

    Application.put_env(:ueberauth, Ueberauth.Strategy.Apple, [])

    Application.put_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth,
      client_id: "discord-test-client-id",
      client_secret: "discord-test-client-secret"
    )

    Application.put_env(:ueberauth, Ueberauth.Strategy.Google.OAuth,
      client_id: "google-test-client-id",
      client_secret: "google-test-client-secret"
    )

    on_exit(fn ->
      restore_application_env(:ueberauth, Ueberauth.Strategy.Apple, original_apple_config)

      restore_application_env(
        :ueberauth,
        Ueberauth.Strategy.Discord.OAuth,
        original_discord_config
      )

      restore_application_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, original_google_config)
    end)
  end

  describe "GET /users/settings" do
    test "renders settings as an Inertia page", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/settings")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert inertia_component(conn) == "account_settings"
      assert inertia_props(conn).email == user.email
      assert inertia_props(conn).username == user.username
      assert inertia_props(conn).apple == %{available: false, linked: false}
      assert inertia_props(conn).discord == %{available: true, linked: false}
      assert inertia_props(conn).google == %{available: true, linked: false}
    end

    test "reports a linked Apple method", %{conn: conn, user: user} do
      put_apple_auth_config()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :apple, "settings-subject")

      conn = get(conn, ~p"/users/settings")

      assert inertia_props(conn).apple == %{available: true, linked: true}
    end

    test "converts a verified Apple link cookie to flash", %{conn: conn, user: user} do
      put_apple_auth_config()
      assert {:ok, _identity} = Accounts.link_user_identity(user, :apple, "settings-subject")

      conn = get_settings_with_apple_result(conn, :linked)

      assert redirected_to(conn) == ~p"/users/settings"
      assert conn.resp_cookies[Apple.link_result_cookie()].max_age == 0
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Apple was linked to this account."
    end

    test "does not trust an Apple result query parameter", %{conn: conn} do
      put_apple_auth_config()

      conn = get(conn, ~p"/users/settings?apple=linked")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert inertia_component(conn) == "account_settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == nil
    end

    test "keeps provider-owned Apple failures generic", %{conn: conn} do
      conflict_conn = get_settings_with_apple_result(conn, :conflict)

      assert redirected_to(conflict_conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conflict_conn.assigns.flash, :error) ==
               "Apple could not be linked because that identity is unavailable."

      failed_conn = get_settings_with_apple_result(conn, :failed)

      assert redirected_to(failed_conn) == ~p"/users/settings"

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

      conn = get(conn, ~p"/users/settings")

      assert inertia_props(conn).discord == %{available: true, linked: true}
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

      conn = get(conn, ~p"/users/settings")

      assert inertia_props(conn).discord == %{available: false, linked: true}
    end

    test "reports a linked Google method", %{conn: conn, user: user} do
      assert {:ok, _identity} = Accounts.link_user_identity(user, :google, "settings-subject")

      conn = get(conn, ~p"/users/settings")

      assert inertia_props(conn).google == %{available: true, linked: true}
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

      conn = get(conn, ~p"/users/settings")

      assert inertia_props(conn).google == %{available: false, linked: true}
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).reauthenticate == false
      assert get_session(conn, :auth_prompt).return_to == "/users/settings"
    end

    @tag token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -11, :minute)
    test "redirects if user is not in sudo mode", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).reauthenticate == true
      assert get_session(conn, :auth_prompt).return_to == "/users/settings"
    end
  end

  describe "PUT /users/settings (change password form)" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_password",
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == ~p"/users/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_identifier_and_password(user.email, "new valid password")
    end

    test "returns flat password validation through the Inertia redirect", %{conn: conn} do
      old_password_conn =
        conn
        |> inertia_request()
        |> put(~p"/users/settings", %{
          "action" => "update_password",
          "user" => %{"password" => "too short", "password_confirmation" => "does not match"}
        })

      assert redirected_to(old_password_conn, 303) == ~p"/users/settings"

      response_conn = follow_inertia_redirect(old_password_conn)

      assert %{
               password: "should be at least 12 character(s)",
               password_confirmation: "does not match password"
             } = inertia_errors(response_conn)

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "A link to confirm your email"

      assert Accounts.get_user_by_email(user.email)
    end

    test "returns flat email validation through the Inertia redirect", %{conn: conn} do
      conn =
        conn
        |> inertia_request()
        |> put(~p"/users/settings", %{
          "action" => "update_email",
          "user" => %{"email" => "with spaces"}
        })

      assert redirected_to(conn, 303) == ~p"/users/settings"

      response_conn = follow_inertia_redirect(conn)

      assert inertia_errors(response_conn) == %{email: "must have the @ sign and no spaces"}
    end
  end

  describe "GET /users/settings/confirm-email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Email changed successfully"

      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")

      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/settings/confirm-email/oops")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).reauthenticate == false
      assert get_session(conn, :auth_prompt).return_to == "/users/settings/confirm-email/#{token}"
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

  defp get_settings_with_apple_result(conn, result) do
    cookie =
      build_conn()
      |> Apple.put_link_result(result)
      |> then(& &1.resp_cookies[Apple.link_result_cookie()].value)

    conn
    |> put_req_cookie(Apple.link_result_cookie(), cookie)
    |> get(~p"/users/settings")
  end

  defp restore_application_env(application, key, nil),
    do: Application.delete_env(application, key)

  defp restore_application_env(application, key, value),
    do: Application.put_env(application, key, value)
end
