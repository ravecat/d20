defmodule D20Web.UserRegistrationControllerTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts
  alias D20.Accounts.User
  alias D20.Accounts.UserToken

  describe "GET /users/register" do
    test "is not exposed as a standalone page", %{conn: conn} do
      conn = get(conn, "/users/register")

      assert response(conn, 404)
    end
  end

  describe "POST /users/register" do
    test "creates an account and returns to the originating page without logging in", %{
      conn: conn
    } do
      email = unique_user_email()

      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/register", %{
          "user" => %{"email" => email},
          "response_to" => "/games/qwinto",
          "return_to" => "/games/qwinto"
        })

      assert redirected_to(conn, 303) == "/games/qwinto"
      assert conn.status == 303

      refute get_session(conn, :user_token)
      assert get_session(conn, :return_to) == "/games/qwinto"
      assert %User{confirmed_at: nil, hashed_password: nil} = Accounts.get_user_by_email(email)
    end

    test "returns a flat field error through the Inertia redirect", %{conn: conn} do
      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/register", %{
          "user" => %{"email" => "with spaces"},
          "response_to" => "/",
          "return_to" => "/"
        })

      assert redirected_to(conn, 303) == "/"

      response_conn = follow_inertia_redirect(conn)

      assert inertia_errors(response_conn) == %{email: "must have the @ sign and no spaces"}
    end

    test "returns the duplicate changeset error without sending another email", %{conn: conn} do
      user = unconfirmed_user_fixture()

      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/register", %{
          "user" => %{"email" => String.upcase(user.email)},
          "response_to" => "/",
          "return_to" => "/"
        })

      response_conn = follow_inertia_redirect(conn)

      assert inertia_errors(response_conn) == %{email: "has already been taken"}

      assert D20.Repo.aggregate(User, :count) == 1
      refute_receive {:email, _email}, 20
    end

    test "returns a flat recovery error through the Inertia redirect when delivery fails", %{
      conn: conn
    } do
      use_mailer_adapter(D20.FailingMailerAdapter)
      email = unique_user_email()

      conn =
        conn
        |> inertia_request()
        |> post(~p"/users/register", %{
          "user" => %{"email" => email},
          "response_to" => "/",
          "return_to" => "/"
        })

      response_conn = follow_inertia_redirect(conn)

      assert %{delivery: message} = inertia_errors(response_conn)
      assert message =~ "could not send the confirmation email"
      assert %User{confirmed_at: nil} = user = Accounts.get_user_by_email(email)
      assert D20.Repo.get_by(UserToken, user_id: user.id, context: "login")
    end

    test "redirects an authenticated caller before account creation", %{conn: conn} do
      conn =
        conn
        |> log_in_user(user_fixture())
        |> inertia_request()
        |> post(~p"/users/register", %{
          "user" => %{"email" => unique_user_email()},
          "response_to" => "/games/qwinto",
          "return_to" => "/games/qwinto"
        })

      assert redirected_to(conn) == ~p"/"
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

  defp use_mailer_adapter(adapter) do
    previous_config = Application.fetch_env!(:d20, D20.Mailer)
    Application.put_env(:d20, D20.Mailer, Keyword.put(previous_config, :adapter, adapter))

    on_exit(fn -> Application.put_env(:d20, D20.Mailer, previous_config) end)
  end
end
