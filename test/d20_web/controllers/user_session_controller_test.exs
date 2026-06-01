defmodule D20Web.UserSessionControllerTest do
  use D20Web.ConnCase, async: true

  import D20.AccountsFixtures
  alias D20.Accounts

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), user: user_fixture()}
  end

  describe "GET /users/log-in" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in")
      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ ~p"/users/register"
      assert response =~ "Log in with email"
      assert token = conn.assigns.actor_token
      assert response =~ ~s(window.actorToken = "#{token}")

      assert {:ok, %{id: _actor_id, type: :anonymous}} =
               D20.Actors.Token.verify(D20Web.Endpoint, token)
    end

    test "renders login page with email filled in (sudo mode)", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(~p"/users/log-in")

      html = html_response(conn, 200)

      assert html =~ "You need to reauthenticate"
      refute html =~ "Register"
      assert html =~ "Log in with email"
      assert token = conn.assigns.actor_token
      assert html =~ ~s(window.actorToken = "#{token}")

      assert {:ok, %{id: actor_id, type: :user}} = D20.Actors.Token.verify(D20Web.Endpoint, token)

      assert actor_id == to_string(user.id)

      assert html =~
               ~s(<input type="email" name="user[email]" id="login_form_magic_email" value="#{user.email}")
    end

    test "renders login page (email + password)", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in?mode=password")
      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ ~p"/users/register"
      assert response =~ "Log in with email"
    end
  end

  describe "GET /users/log-in/:token" do
    test "renders confirmation page for unconfirmed user", %{conn: conn, unconfirmed_user: user} do
      token = extract_user_token(fn url -> Accounts.deliver_login_instructions(user, url) end)

      conn = get(conn, ~p"/users/log-in/#{token}")
      assert html_response(conn, 200) =~ "Confirm and stay logged in"
    end

    test "renders login page for confirmed user", %{conn: conn, user: user} do
      token = extract_user_token(fn url -> Accounts.deliver_login_instructions(user, url) end)

      conn = get(conn, ~p"/users/log-in/#{token}")
      html = html_response(conn, 200)
      refute html =~ "Confirm my account"
      assert html =~ "Log in"
    end

    test "raises error for invalid token", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in/invalid-token")
      assert redirected_to(conn) == ~p"/users/log-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Magic link is invalid or it has expired."
    end
  end

  describe "POST /users/log-in - email and password" do
    test "logs the user in", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      conn = get(conn, ~p"/")
      assert_logged_in_inertia_home(conn, user)
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_d20_web_user_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in?mode=password", %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ "Invalid email or password"
    end
  end

  describe "POST /users/log-in - magic link" do
    test "sends magic link email when user exists", %{conn: conn, user: user} do
      conn = post conn, ~p"/users/log-in", %{"user" => %{"email" => user.email}}

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert D20.Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "login"
    end

    test "logs the user in", %{conn: conn, user: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)

      conn = post conn, ~p"/users/log-in", %{"user" => %{"token" => token}}

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      conn = get(conn, ~p"/")
      assert_logged_in_inertia_home(conn, user)
    end

    test "confirms unconfirmed user", %{conn: conn, unconfirmed_user: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)
      refute user.confirmed_at

      conn =
        post conn, ~p"/users/log-in", %{"user" => %{"token" => token}, "_action" => "confirmed"}

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "User confirmed successfully."

      assert Accounts.get_user!(user.id).confirmed_at

      conn = get(conn, ~p"/")
      assert_logged_in_inertia_home(conn, user)
    end

    test "emits error message when magic link is invalid", %{conn: conn} do
      conn = post conn, ~p"/users/log-in", %{"user" => %{"token" => "invalid"}}

      assert html_response(conn, 200) =~ "The link is invalid or it has expired."
    end
  end

  describe "DELETE /users/log-out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end

  defp assert_logged_in_inertia_home(conn, user) do
    response = html_response(conn, 200)

    assert response =~ ~s(id="app")
    assert inertia_component(conn) == "home"
    assert conn.assigns.current_user.id == user.id
    assert token = conn.assigns.actor_token
    assert response =~ ~s(window.actorToken = "#{token}")

    assert {:ok, %{id: actor_id, type: :user}} = D20.Actors.Token.verify(D20Web.Endpoint, token)

    assert actor_id == to_string(user.id)
  end
end
