defmodule D20Web.UserSessionController do
  use D20Web, :controller

  alias D20.Accounts
  alias D20Web.Auth

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> "User confirmed successfully."
        _ -> "Welcome back!"
      end

    case Accounts.login_user_by_magic_link(token, user_params) do
      {:ok, {user, _expired_tokens}} ->
        conn |> put_flash(:info, info) |> Auth.log_in_user(user, user_params)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> assign_errors(changeset)
        |> put_status(:see_other)
        |> redirect(to: ~p"/users/log-in/#{token}")

      {:error, :not_found} ->
        conn
        |> Auth.put_auth_prompt(message: "The link is invalid or it has expired.")
        |> redirect(to: ~p"/")
    end
  end

  # username or email + password login
  def create(
        conn,
        %{"user" => %{"identifier" => identifier, "password" => password} = user_params} = params
      ) do
    conn = Auth.store_return_to(conn, params["return_to"])

    if user = Accounts.get_user_by_identifier_and_password(identifier, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> Auth.log_in_user(user, user_params)
    else
      invalid_credentials(conn, params)
    end
  end

  # magic link request
  def create(conn, %{"user" => %{"email" => email}} = params) do
    conn = Auth.store_return_to(conn, params["return_to"])

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
      if user.confirmed_at do
        render_inertia(conn, "auth_confirmation", %{
          email: user.email,
          reauthenticate: not is_nil(conn.assigns.current_user),
          token: token
        })
      else
        render_inertia(conn, "registration_completion", %{
          email: user.email,
          submission: %{
            action: ~p"/users/log-in",
            credential: %{type: "magic_link", token: token}
          }
        })
      end
    else
      conn
      |> Auth.put_auth_prompt(message: "Magic link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> Auth.log_out_user()
  end

  defp invalid_credentials(conn, params) do
    # Do not disclose whether the identifier or password was incorrect.
    conn
    |> assign_errors(%{credentials: "Invalid username, email, or password"})
    |> redirect_to_response(params, ~p"/")
  end

  defp redirect_after_magic_link_request(conn, params),
    do: redirect_to_response(conn, params, ~p"/")

  defp redirect_to_response(conn, params, fallback) do
    conn
    |> put_status(:see_other)
    |> redirect(to: Auth.safe_local_path(params["response_to"], fallback))
  end
end
