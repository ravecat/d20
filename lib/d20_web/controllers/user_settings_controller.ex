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

    providers = [
      %{
        available: Google.available?(),
        href: ~p"/users/settings/auth/google",
        id: "google",
        linked: MapSet.member?(linked_providers, :google),
        name: "Google"
      },
      %{
        available: Apple.available?(),
        href: ~p"/users/settings/auth/apple",
        id: "apple",
        linked: MapSet.member?(linked_providers, :apple),
        name: "Apple"
      },
      %{
        available: Discord.available?(),
        href: ~p"/users/settings/auth/discord",
        id: "discord",
        linked: MapSet.member?(linked_providers, :discord),
        name: "Discord"
      }
    ]

    render_inertia(conn, "account_settings", %{
      email: user.email,
      providers: providers,
      username: user.username
    })
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

        message =
          if user.email,
            do: "A link to confirm your email change has been sent to the new address.",
            else: "A link to confirm your email has been sent to the new address."

        conn
        |> put_flash(:info, message)
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

      {:error, %Ecto.Changeset{}} ->
        conn
        |> put_flash(:error, "That email address is no longer available.")
        |> redirect(to: ~p"/users/settings")

      {:error, _reason} ->
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
