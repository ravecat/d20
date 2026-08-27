defmodule D20Web.UserSessionControllerTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures
  alias D20.Accounts
  alias D20.Actors.Actor

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), user: user_fixture()}
  end

  describe "GET /users/log-in" do
    test "is not exposed as a standalone page", %{conn: conn} do
      conn = get(conn, "/users/log-in")

      assert response(conn, 404)
    end
  end

  describe "GET /users/log-in/:token" do
    test "renders an Inertia confirmation page for an unconfirmed user", %{
      conn: conn,
      unconfirmed_user: user
    } do
      token = extract_user_token(fn url -> Accounts.deliver_login_instructions(user, url) end)

      conn = get(conn, ~p"/users/log-in/#{token}")

      assert html_response(conn, 200) =~ ~s(id="app")
      assert inertia_component(conn) == "registration_completion"

      assert %{
               email: email,
               submission: %{
                 action: "/users/log-in",
                 credential: %{type: "magic_link", token: ^token}
               }
             } = inertia_props(conn)

      assert email == user.email
      assert %Accounts.User{confirmed_at: nil, username: nil} = Accounts.get_user!(user.id)
      assert Accounts.get_user_by_magic_link_token(token)
      refute get_session(conn, :user_token)
    end

    test "renders an Inertia login confirmation for a confirmed user", %{conn: conn, user: user} do
      token = extract_user_token(fn url -> Accounts.deliver_login_instructions(user, url) end)

      conn = get(conn, ~p"/users/log-in/#{token}")

      assert inertia_component(conn) == "auth_confirmation"
      assert %{email: email, token: ^token, reauthenticate: false} = inertia_props(conn)
      assert email == user.email
    end

    test "redirects an invalid token to the modal host", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in/invalid-token")
      assert redirected_to(conn) == ~p"/"

      assert %{
               kind: :error,
               message: "Magic link is invalid or it has expired.",
               reauthenticate: false,
               return_to: "/"
             } = get_session(conn, :auth_prompt)
    end
  end

  describe "POST /users/log-in - username or email and password" do
    test "logs the user in by username", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{
            "identifier" => String.upcase(user.username),
            "password" => valid_user_password()
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      conn = get(conn, ~p"/")
      assert_logged_in_inertia_home(conn, user)
    end

    test "logs a provider-only user in by username and password", %{conn: conn} do
      user = %{username: "provider_only"} |> provider_user_fixture(:google) |> set_password()

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"identifier" => "PROVIDER_ONLY", "password" => valid_user_password()}
        })

      assert redirected_to(conn) == ~p"/"

      assert {session_user, _inserted_at} =
               Accounts.get_user_by_session_token(get_session(conn, :user_token))

      assert session_user.id == user.id
    end

    test "does not switch accounts during password reauthentication", %{conn: conn, user: user} do
      current_user = set_password(user)
      other_user = set_password(user_fixture())

      conn =
        conn
        |> log_in_user(current_user)
        |> post(~p"/users/log-in", %{
          "user" => %{"identifier" => other_user.username, "password" => valid_user_password()}
        })

      assert redirected_to(conn, 303) == ~p"/"

      assert {session_user, _inserted_at} =
               Accounts.get_user_by_session_token(get_session(conn, :user_token))

      assert session_user.id == current_user.id
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{
            "identifier" => user.email,
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
        |> init_test_session(return_to: "/foo/bar")
        |> post(~p"/users/log-in", %{
          "user" => %{"identifier" => user.email, "password" => valid_user_password()}
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "logs an Inertia caller in and returns to the submitted local path", %{
      conn: conn,
      user: user
    } do
      user = set_password(user)

      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"identifier" => user.email, "password" => valid_user_password()},
          "response_to" => "/games/qwinto?session=table-1",
          "return_to" => "/games/qwinto?session=table-1"
        })

      assert get_session(conn, :user_token)
      assert conn.status == 409
      assert get_resp_header(conn, "x-inertia-location") == ["/games/qwinto?session=table-1"]
    end

    test "rejects an external Inertia return path", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"identifier" => user.email, "password" => valid_user_password()},
          "response_to" => "/",
          "return_to" => "//example.org/steal-session"
        })

      assert get_session(conn, :user_token)
      assert conn.status == 409
      assert get_resp_header(conn, "x-inertia-location") == [~p"/"]
    end

    test "returns a flat generic error through the Inertia redirect", %{conn: conn, user: user} do
      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"identifier" => user.username, "password" => "invalid_password"},
          "response_to" => "/",
          "return_to" => "/"
        })

      assert redirected_to(conn, 303) == "/"

      response_conn = follow_inertia_redirect(conn)

      assert inertia_errors(response_conn) == %{
               credentials: "Invalid username, email, or password"
             }

      refute get_session(conn, :user_token)
    end

    test "returns the same generic error for a passwordless account", %{conn: conn, user: user} do
      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"identifier" => user.username, "password" => valid_user_password()},
          "response_to" => "/",
          "return_to" => "/"
        })

      response_conn = follow_inertia_redirect(conn)

      assert inertia_errors(response_conn) == %{
               credentials: "Invalid username, email, or password"
             }

      refute get_session(conn, :user_token)
    end
  end

  describe "POST /users/log-in - magic link" do
    test "sends magic link email when user exists", %{conn: conn, user: user} do
      conn = post conn, ~p"/users/log-in", %{"user" => %{"email" => user.email}}

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert D20.Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "login"
    end

    test "returns the same neutral Inertia result for an unknown email", %{conn: conn} do
      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"email" => unique_user_email()},
          "response_to" => "/games/qwinto",
          "return_to" => "/games/qwinto"
        })

      assert redirected_to(conn, 303) == "/games/qwinto"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert get_session(conn, :return_to) == "/games/qwinto"
      refute get_session(conn, :user_token)
    end

    test "keeps the neutral Inertia result without an HTML error dialog on timeout", %{
      conn: conn,
      user: user
    } do
      use_mailer_adapter(D20.FailingMailerAdapter, failure_reason: :timeout)

      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"email" => user.email},
          "response_to" => "/games/qwinto",
          "return_to" => "/games/qwinto"
        })

      assert redirected_to(conn, 303) == "/games/qwinto"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert D20.Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "login"

      response_conn = follow_inertia_redirect(conn)

      assert inertia_errors(response_conn) == %{}
    end

    test "returns a modal request to its host while storing the later authentication path", %{
      conn: conn,
      user: user
    } do
      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"email" => user.email},
          "response_to" => "/",
          "return_to" => "/games/qwinto"
        })

      assert redirected_to(conn, 303) == "/"
      assert get_session(conn, :return_to) == "/games/qwinto"
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

    test "logs a provider-created account in by Magic Link without duplicating it", %{conn: conn} do
      email = unique_user_email()

      assert {:ok, provider_user} =
               Accounts.register_user_with_identity(
                 %{email: email, username: "provider_magic_player"},
                 :google,
                 "provider-magic-subject"
               )

      token =
        extract_user_token(fn url -> Accounts.deliver_login_instructions(provider_user, url) end)

      user_count = D20.Repo.aggregate(Accounts.User, :count)
      conn = post conn, ~p"/users/log-in", %{"user" => %{"token" => token}}

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert D20.Repo.aggregate(Accounts.User, :count) == user_count

      assert Accounts.get_user_by_identity(:google, "provider-magic-subject").id ==
               provider_user.id

      conn = get(conn, ~p"/")
      assert_logged_in_inertia_home(conn, provider_user)
    end

    test "confirms unconfirmed user", %{conn: conn, unconfirmed_user: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)
      refute user.confirmed_at

      conn =
        post conn, ~p"/users/log-in", %{
          "user" => %{"token" => token, "username" => "table_master"},
          "_action" => "confirmed"
        }

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "User confirmed successfully."

      assert %Accounts.User{confirmed_at: confirmed_at, username: "table_master"} =
               Accounts.get_user!(user.id)

      assert confirmed_at

      conn = get(conn, ~p"/")
      assert_logged_in_inertia_home(conn, user)
    end

    test "keeps the confirmation token after a username validation error", %{
      conn: conn,
      unconfirmed_user: user
    } do
      {token, _hashed_token} = generate_user_magic_link_token(user)

      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"token" => token, "username" => "invalid name"},
          "_action" => "confirmed"
        })

      assert redirected_to(conn, 303) == ~p"/users/log-in/#{token}"
      refute get_session(conn, :user_token)

      response_conn = follow_inertia_redirect(conn)

      assert %{username: _message} = inertia_errors(response_conn)
      assert %Accounts.User{confirmed_at: nil, username: nil} = Accounts.get_user!(user.id)
      assert Accounts.get_user_by_magic_link_token(token)
    end

    test "keeps the confirmation token when another user owns the username", %{
      conn: conn,
      unconfirmed_user: user
    } do
      existing_user = user_fixture(username: "table_master")
      {token, _hashed_token} = generate_user_magic_link_token(user)

      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/log-in", %{
          "user" => %{"token" => token, "username" => "table_master"},
          "_action" => "confirmed"
        })

      assert redirected_to(conn, 303) == ~p"/users/log-in/#{token}"
      response_conn = follow_inertia_redirect(conn)
      assert inertia_errors(response_conn).username == "has already been taken"
      assert Accounts.get_user!(existing_user.id).username == "table_master"
      assert %Accounts.User{confirmed_at: nil, username: nil} = Accounts.get_user!(user.id)
      assert Accounts.get_user_by_magic_link_token(token)
    end

    test "does not switch accounts during Magic Link reauthentication", %{conn: conn, user: user} do
      other_user = user_fixture()
      {token, _hashed_token} = generate_user_magic_link_token(other_user)

      conn =
        conn |> log_in_user(user) |> post(~p"/users/log-in", %{"user" => %{"token" => token}})

      assert redirected_to(conn) == ~p"/"

      assert {session_user, _inserted_at} =
               Accounts.get_user_by_session_token(get_session(conn, :user_token))

      assert session_user.id == user.id
      assert get_session(conn, :auth_prompt).reauthenticate
      assert Accounts.get_user_by_magic_link_token(token).id == other_user.id
    end

    test "redirects when a submitted magic link is invalid", %{conn: conn} do
      conn = post conn, ~p"/users/log-in", %{"user" => %{"token" => "invalid"}}

      assert redirected_to(conn) == ~p"/"

      assert %{
               kind: :error,
               message: "The link is invalid or it has expired.",
               reauthenticate: false,
               return_to: "/"
             } = get_session(conn, :auth_prompt)
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

    assert {:ok, %Actor{id: actor_id, type: :user}} =
             D20.Actors.Token.verify(D20Web.Endpoint, token)

    assert actor_id == to_string(user.id)
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

  defp use_mailer_adapter(adapter, config) do
    previous_config = Application.fetch_env!(:d20, D20.Mailer)

    test_config = previous_config |> Keyword.put(:adapter, adapter) |> Keyword.merge(config)

    Application.put_env(:d20, D20.Mailer, test_config)

    on_exit(fn -> Application.put_env(:d20, D20.Mailer, previous_config) end)
  end
end
