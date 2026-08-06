defmodule D20Web.UserSettingsControllerTest do
  use D20Web.ConnCase, async: true

  alias D20.Accounts
  import D20.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings as an Inertia page", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/settings")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert inertia_component(conn) == "account_settings"
      assert inertia_props(conn).email == user.email
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

      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
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
end
