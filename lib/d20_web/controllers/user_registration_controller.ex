defmodule D20Web.UserRegistrationController do
  use D20Web, :controller

  alias D20.Accounts
  alias D20Web.Auth
  alias D20Web.CoreComponents

  def create(conn, %{"user" => user_params} = params) do
    conn = Auth.store_return_to(conn, params["return_to"])

    case Accounts.register_user_with_magic_link(user_params, &url(~p"/users/log-in/#{&1}")) do
      {:ok, user} ->
        conn
        |> put_flash(
          :info,
          "An email was sent to #{user.email}, please access it to confirm your account."
        )
        |> redirect_to_response(params, ~p"/")

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> assign_errors(registration_errors(changeset))
        |> redirect_to_response(params, ~p"/")

      {:error, :delivery_failed} ->
        conn
        |> assign_errors(%{
          delivery:
            "Your account was created, but we could not send the confirmation email. Log in to request another link."
        })
        |> redirect_to_response(params, ~p"/")
    end
  end

  defp redirect_to_response(conn, params, fallback) do
    conn
    |> put_status(:see_other)
    |> redirect(to: Auth.safe_local_path(params["response_to"], fallback))
  end

  defp registration_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&CoreComponents.translate_error/1)
    |> Map.new(fn {field, messages} -> {field, List.first(messages)} end)
  end
end
