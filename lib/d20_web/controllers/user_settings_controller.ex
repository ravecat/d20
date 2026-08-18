defmodule D20Web.UserSettingsController do
  use D20Web, :controller

  alias D20.Accounts
  alias D20Web.Auth
  alias D20Web.Auth.Apple
  alias D20Web.Auth.Discord
  alias D20Web.Auth.Google

  def edit(conn, _params) do
    user = conn.assigns.current_user
    linked_providers = user |> Accounts.list_user_identities() |> MapSet.new(& &1.provider)
    apple_linked = MapSet.member?(linked_providers, :apple)
    discord_linked = MapSet.member?(linked_providers, :discord)
    google_linked = MapSet.member?(linked_providers, :google)

    render_inertia(conn, "account_settings", %{
      apple: %{available: Apple.available?(), linked: apple_linked},
      discord: %{available: Discord.available?(), linked: discord_linked},
      email: user.email,
      username: user.username,
      google: %{available: Google.available?(), linked: google_linked}
    })
  end

  def update(conn, %{"action" => "claim_username", "user" => user_params}) do
    case Accounts.claim_username(conn.assigns.current_user, user_params) do
      {:ok, _user} ->
        conn |> put_flash(:info, "Username saved successfully.") |> redirect_to_settings()

      {:error, %Ecto.Changeset{} = changeset} ->
        conn |> assign_errors(changeset) |> redirect_to_settings()

      {:error, :not_found} ->
        conn |> put_flash(:error, "Account no longer exists.") |> Auth.log_out_user()
    end
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/users/settings")

      changeset ->
        conn |> assign_errors(%{changeset | action: :insert}) |> redirect_to_settings()
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, user_params) do
      {:ok, {user, _}} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:return_to, ~p"/users/settings")
        |> Auth.log_in_user(user)

      {:error, changeset} ->
        conn |> assign_errors(changeset) |> redirect_to_settings()
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/users/settings")

      {:error, _} ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  defp redirect_to_settings(conn) do
    conn
    |> put_status(:see_other)
    |> redirect(to: ~p"/users/settings")
  end
end
