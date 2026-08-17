defmodule D20Web.Auth.GoogleController do
  use D20Web, :controller

  require Logger

  alias D20.Accounts
  alias D20Web.Auth
  alias D20Web.Auth.Google

  import D20Web.Auth, only: [require_authenticated_user: 2, require_sudo_mode: 2]

  @provider_request_params ~w(
    scope
    prompt
    access_type
    include_granted_scopes
    login_hint
    hd
    hl
  )

  plug :require_authenticated_user when action == :link
  plug :require_sudo_mode when action == :link

  plug :prepare_google_request when action == :request
  plug :require_google_available when action in [:request, :callback]
  plug Ueberauth, providers: [:google]

  def request(conn, _params), do: conn

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    {intent, conn} = Google.take_intent(conn)
    failure_response(conn, intent, Google.failure_reason(failure))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    {intent, conn} = Google.take_intent(conn)

    with {:ok, identity} <- Google.normalize(auth),
         {:ok, action} <- intent do
      handle_callback(conn, action, identity)
    else
      {:error, reason} -> failure_response(conn, intent, reason)
    end
  end

  def callback(conn, _params) do
    {intent, conn} = Google.take_intent(conn)
    failure_response(conn, intent, :missing_provider_result)
  end

  def registration(conn, _params) do
    case Google.fetch_registration(conn) do
      {:ok, %{email: email}} ->
        render_inertia(conn, "registration_completion", %{
          email: email,
          submission: %{action: ~p"/auth/google/register", credential: %{type: "server_session"}},
          cancel_action: ~p"/auth/google/register/cancel"
        })

      {:error, reason} ->
        completion_failure(conn, reason)
    end
  end

  def complete_registration(conn, %{"user" => user_params}) when is_map(user_params) do
    case Google.fetch_registration(conn) do
      {:ok, registration} -> complete_registration(conn, registration, user_params)
      {:error, reason} -> completion_failure(conn, reason)
    end
  end

  def complete_registration(conn, _params) do
    case Google.fetch_registration(conn) do
      {:ok, _registration} ->
        conn
        |> assign_errors(%{username: "can't be blank"})
        |> put_status(:see_other)
        |> redirect(to: ~p"/auth/google/register")

      {:error, reason} ->
        completion_failure(conn, reason)
    end
  end

  def cancel_registration(conn, _params) do
    conn
    |> Google.clear_registration()
    |> put_flash(:info, "Registration cancelled. Choose another method to create your account.")
    |> redirect(to: ~p"/")
  end

  def link(conn, _params) do
    user = conn.assigns.current_user

    if google_linked?(user) do
      conn
      |> put_flash(:info, "Google is already linked to your account.")
      |> redirect(to: ~p"/users/settings")
    else
      conn
      |> Google.put_link_intent(user)
      |> redirect(to: ~p"/auth/google")
    end
  end

  defp handle_callback(conn, :authenticate, identity) do
    case Accounts.get_user_by_identity(:google, identity.provider_uid) do
      nil -> start_registration(conn, identity)
      user -> conn |> put_flash(:info, "Welcome back!") |> Auth.log_in_user(user)
    end
  end

  defp handle_callback(conn, {:link, user_id}, identity) do
    user = conn.assigns.current_user

    cond do
      is_nil(user) or to_string(user.id) != user_id ->
        failure_response(conn, {:ok, {:link, user_id}}, :invalid_link_binding)

      not Accounts.sudo_mode?(user, -10) ->
        conn
        |> Auth.put_auth_prompt(
          kind: :warning,
          message: "You must re-authenticate before linking Google.",
          reauthenticate: true
        )
        |> redirect(to: ~p"/")

      true ->
        link_identity(conn, user, identity.provider_uid)
    end
  end

  defp start_registration(conn, identity) do
    with {:ok, registration} <- Google.registration_data(identity),
         nil <- Accounts.get_user_by_email(registration.email) do
      conn
      |> Google.put_registration(registration)
      |> redirect(to: ~p"/auth/google/register")
    else
      %Accounts.User{} ->
        conn
        |> Auth.put_auth_prompt(
          kind: :warning,
          message:
            "That email already has a D20 account. Log in with an existing method, then link Google in Account Settings.",
          reauthenticate: false
        )
        |> redirect(to: failure_path(conn))

      {:error, reason} ->
        failure_response(conn, {:ok, :authenticate}, reason)
    end
  end

  defp complete_registration(conn, registration, user_params) do
    attrs = Map.put(user_params, "email", registration.email)

    case Accounts.register_user_with_identity(attrs, :google, registration.provider_uid) do
      {:ok, user} ->
        conn
        |> Google.clear_registration()
        |> put_flash(:info, "Account created successfully.")
        |> Auth.log_in_user(user, user_params)

      {:error, :user, %Ecto.Changeset{} = changeset} ->
        if Keyword.has_key?(changeset.errors, :username) and
             not Keyword.has_key?(changeset.errors, :email) do
          conn
          |> assign_errors(changeset)
          |> put_status(:see_other)
          |> redirect(to: ~p"/auth/google/register")
        else
          completion_failure(conn, :account_conflict)
        end

      {:error, :identity, %Ecto.Changeset{}} ->
        completion_failure(conn, :identity_conflict)
    end
  end

  defp link_identity(conn, user, provider_uid) do
    case Accounts.get_user_by_identity(:google, provider_uid) do
      %{id: owner_id} when owner_id == user.id ->
        linked_response(conn)

      nil ->
        case Accounts.link_user_identity(user, :google, provider_uid) do
          {:ok, _identity} -> linked_response(conn)
          {:error, %Ecto.Changeset{}} -> link_conflict_response(conn)
        end

      _other_user ->
        link_conflict_response(conn)
    end
  end

  defp linked_response(conn) do
    conn
    |> put_flash(:info, "Google linked successfully.")
    |> redirect(to: ~p"/users/settings")
  end

  defp link_conflict_response(conn) do
    conn
    |> put_flash(:error, "Google could not be linked to this account.")
    |> redirect(to: ~p"/users/settings")
  end

  defp completion_failure(conn, reason) do
    log_failure(conn, :registration_completion, reason)

    conn
    |> Google.clear_registration()
    |> Auth.put_auth_prompt(
      kind: :error,
      message: "Google registration expired or could not be completed. Try again or use email.",
      reauthenticate: false
    )
    |> redirect(to: failure_path(conn))
  end

  defp failure_response(conn, intent, :provider_unavailable) do
    log_failure(conn, :availability, :provider_unavailable)

    case {intent, conn.assigns[:current_user]} do
      {{:ok, {:link, user_id}}, current_user} when not is_nil(current_user) ->
        if to_string(current_user.id) == user_id do
          conn
          |> put_flash(:error, "Google is temporarily unavailable. Try again later.")
          |> redirect(to: ~p"/users/settings")
        else
          google_unavailable_response(conn)
        end

      _other ->
        google_unavailable_response(conn)
    end
  end

  defp failure_response(conn, intent, reason) do
    log_failure(conn, :callback, reason)

    case {intent, conn.assigns[:current_user]} do
      {{:ok, {:link, user_id}}, current_user} when not is_nil(current_user) ->
        if to_string(current_user.id) == user_id do
          conn
          |> put_flash(:error, "Google could not be linked to this account.")
          |> redirect(to: ~p"/users/settings")
        else
          authentication_failure_response(conn)
        end

      _other ->
        authentication_failure_response(conn)
    end
  end

  defp authentication_failure_response(conn) do
    conn
    |> Auth.put_auth_prompt(
      kind: :error,
      message: "Google sign-in could not be completed. Try again or use email.",
      reauthenticate: false
    )
    |> redirect(to: failure_path(conn))
  end

  defp google_unavailable_response(conn) do
    conn
    |> Auth.put_auth_prompt(
      kind: :error,
      message: "Google sign-in is temporarily unavailable. Use email to continue.",
      reauthenticate: false
    )
    |> redirect(to: failure_path(conn))
  end

  defp prepare_google_request(conn, _opts) do
    conn = Auth.store_return_to(conn, conn.params["return_to"])

    conn =
      case Google.fetch_intent(conn) do
        {:ok, {:link, _user_id}} -> conn
        _other -> Google.put_authenticate_intent(conn)
      end

    %{
      conn
      | params: Map.drop(conn.params, @provider_request_params),
        query_params: Map.drop(conn.query_params, @provider_request_params)
    }
  end

  defp require_google_available(conn, _opts) do
    if Google.available?() do
      conn
    else
      {intent, conn} = Google.take_intent(conn)

      conn
      |> failure_response(intent, :provider_unavailable)
      |> halt()
    end
  end

  defp google_linked?(user) do
    user
    |> Accounts.list_user_identities()
    |> Enum.any?(&(&1.provider == :google))
  end

  defp failure_path(conn) do
    conn
    |> get_session(:return_to)
    |> Auth.safe_local_path(~p"/")
  end

  defp log_failure(_conn, outcome_class, reason) do
    metadata =
      maybe_put_request_id(
        [provider: :google, outcome_class: outcome_class, reason: reason],
        Logger.metadata()[:request_id]
      )

    Logger.warning("Google OAuth flow failed", metadata)
  end

  defp maybe_put_request_id(metadata, nil), do: metadata

  defp maybe_put_request_id(metadata, request_id),
    do: Keyword.put(metadata, :request_id, request_id)
end
