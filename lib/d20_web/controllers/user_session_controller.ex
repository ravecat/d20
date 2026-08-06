defmodule D20Web.UserSessionController do
  use D20Web, :controller

  alias D20.Accounts
  alias D20Web.UserAuth

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> "User confirmed successfully."
        _ -> "Welcome back!"
      end

    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, _expired_tokens}} ->
        conn |> put_flash(:info, info) |> UserAuth.log_in_user(user, user_params)

      {:error, :not_found} ->
        conn
        |> UserAuth.put_auth_prompt(message: "The link is invalid or it has expired.")
        |> redirect(to: ~p"/")
    end
  end

  # email + password login
  def create(
        conn,
        %{"user" => %{"email" => email, "password" => password} = user_params} = params
      ) do
    conn = UserAuth.store_return_to(conn, params["return_to"])

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      invalid_credentials(conn, params)
    end
  end

  # magic link request
  def create(conn, %{"user" => %{"email" => email}} = params) do
    conn = UserAuth.store_return_to(conn, params["return_to"])

    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(user, &url(~p"/users/log-in/#{&1}"))
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions for logging in shortly."
    )
    |> redirect_after_magic_link_request(params)
  end

  def confirm(conn, %{"token" => token}) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      render_inertia(conn, "auth_confirmation", %{
        confirmed: not is_nil(user.confirmed_at),
        email: user.email,
        reauthenticate: not is_nil(conn.assigns.current_user),
        token: token
      })
    else
      conn
      |> UserAuth.put_auth_prompt(message: "Magic link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp invalid_credentials(conn, params) do
    # Do not disclose whether the email or password was incorrect.
    conn
    |> assign_errors(%{credentials: "Invalid email or password"})
    |> redirect_to_response(params, ~p"/")
  end

  defp redirect_after_magic_link_request(conn, params),
    do: redirect_to_response(conn, params, ~p"/")

  defp redirect_to_response(conn, params, fallback) do
    conn
    |> put_status(:see_other)
    |> redirect(to: UserAuth.safe_local_path(params["response_to"], fallback))
  end
end
