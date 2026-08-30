defmodule D20Web.Auth.SteamController do
  use D20Web, :controller

  require Logger

  alias D20.Accounts
  alias D20Web.Auth
  alias D20Web.Auth.Steam

  @provider_request_params ~w(
    intent
    return_to
    state
    openid.mode
    openid.ns
    openid.identity
    openid.claimed_id
    openid.realm
    openid.return_to
    openid.op_endpoint
    openid.response_nonce
    openid.signed
    openid.sig
    openid.assoc_handle
  )

  plug :prepare_steam_request when action == :request
  plug :require_steam_available when action in [:request, :callback]
  plug Ueberauth, providers: [:steam]

  def request(conn, _params), do: conn

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    {intent, conn} = Steam.take_intent(conn)
    failure_response(conn, intent, Steam.failure_reason(failure))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    {intent, conn} = Steam.take_intent(conn)

    with {:ok, identity} <- Steam.normalize(auth),
         {:ok, action} <- intent do
      handle_callback(conn, action, identity)
    else
      {:error, reason} -> failure_response(conn, intent, reason)
    end
  end

  def callback(conn, _params) do
    {intent, conn} = Steam.take_intent(conn)
    failure_response(conn, intent, :missing_provider_result)
  end

  def registration(conn, _params) do
    case Steam.fetch_registration(conn) do
      {:ok, %{provider_uid: _provider_uid}} ->
        render_inertia(conn, "registration_completion", %{
          email: nil,
          submission: %{action: ~p"/auth/steam/register", credential: %{type: "server_session"}},
          cancel_action: ~p"/auth/steam/register/cancel"
        })

      {:error, reason} ->
        completion_failure(conn, reason)
    end
  end

  def complete_registration(conn, %{"user" => user_params}) when is_map(user_params) do
    case Steam.fetch_registration(conn) do
      {:ok, registration} -> complete_registration(conn, registration, user_params)
      {:error, reason} -> completion_failure(conn, reason)
    end
  end

  def complete_registration(conn, _params) do
    case Steam.fetch_registration(conn) do
      {:ok, _registration} ->
        conn
        |> assign_errors(%{username: "can't be blank"})
        |> put_status(:see_other)
        |> redirect(to: ~p"/auth/steam/register")

      {:error, reason} ->
        completion_failure(conn, reason)
    end
  end

  def cancel_registration(conn, _params) do
    conn
    |> Steam.clear_registration()
    |> put_flash(:info, "Registration cancelled. Choose another method to create your account.")
    |> redirect(to: ~p"/")
  end

  def link(conn, _params) do
    user = conn.assigns.current_user

    cond do
      not Steam.available?() ->
        conn
        |> put_flash(:error, "Steam is temporarily unavailable. Try again later.")
        |> redirect(to: ~p"/profile")

      steam_linked?(user) ->
        conn
        |> put_flash(:info, "Steam is already linked to your account.")
        |> redirect(to: ~p"/profile")

      true ->
        conn |> Steam.put_link_intent(user) |> redirect(to: ~p"/auth/steam")
    end
  end

  defp handle_callback(conn, :authenticate, identity) do
    case Accounts.get_user_by_identity(:steam, identity.provider_uid) do
      nil -> start_registration(conn, identity)
      user -> conn |> put_flash(:info, "Welcome back!") |> Auth.log_in_user(user)
    end
  end

  defp handle_callback(conn, {:reauthenticate, user_id}, identity) do
    current_user = conn.assigns.current_user
    identity_user = Accounts.get_user_by_identity(:steam, identity.provider_uid)

    if current_user && to_string(current_user.id) == user_id && identity_user &&
         identity_user.id == current_user.id do
      conn
      |> put_flash(:info, "Identity confirmed.")
      |> Auth.log_in_user(current_user)
    else
      reauthentication_failure_response(conn)
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
          message: "You must re-authenticate before linking Steam.",
          reauthenticate: true
        )
        |> redirect(to: ~p"/")

      true ->
        link_identity(conn, user, identity.provider_uid)
    end
  end

  defp start_registration(conn, identity) do
    {:ok, registration} = Steam.registration_data(identity)

    conn
    |> Steam.put_registration(registration)
    |> redirect(to: ~p"/auth/steam/register")
  end

  defp complete_registration(conn, registration, user_params) do
    # Steam supplies no email, so the provider-only account is created with a
    # nil email and only the chosen username.
    attrs = Map.put(user_params, "email", nil)

    case Accounts.register_user_with_identity(attrs, :steam, registration.provider_uid) do
      {:ok, user} ->
        conn
        |> Steam.clear_registration()
        |> put_flash(:info, "Account created successfully.")
        |> Auth.log_in_user(user, user_params)

      {:error, :user, %Ecto.Changeset{} = changeset} ->
        if Keyword.has_key?(changeset.errors, :username) and
             not Keyword.has_key?(changeset.errors, :email) do
          conn
          |> assign_errors(changeset)
          |> put_status(:see_other)
          |> redirect(to: ~p"/auth/steam/register")
        else
          completion_failure(conn, :account_conflict)
        end

      {:error, :identity, %Ecto.Changeset{}} ->
        completion_failure(conn, :identity_conflict)
    end
  end

  defp link_identity(conn, user, provider_uid) do
    case Accounts.get_user_by_identity(:steam, provider_uid) do
      %{id: owner_id} when owner_id == user.id ->
        linked_response(conn)

      nil ->
        case Accounts.link_user_identity(user, :steam, provider_uid) do
          {:ok, _identity} -> linked_response(conn)
          {:error, %Ecto.Changeset{}} -> link_conflict_response(conn)
        end

      _other_user ->
        link_conflict_response(conn)
    end
  end

  defp linked_response(conn) do
    conn
    |> put_flash(:info, "Steam linked successfully.")
    |> redirect(to: ~p"/profile")
  end

  defp link_conflict_response(conn) do
    conn
    |> put_flash(:error, "Steam could not be linked to this account.")
    |> redirect(to: ~p"/profile")
  end

  defp completion_failure(conn, reason) do
    log_failure(conn, :registration_completion, reason)

    conn
    |> Steam.clear_registration()
    |> Auth.put_auth_prompt(
      kind: :error,
      message: "Steam registration expired or could not be completed. Try again or use email.",
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
          |> put_flash(:error, "Steam is temporarily unavailable. Try again later.")
          |> redirect(to: ~p"/profile")
        else
          steam_unavailable_response(conn)
        end

      {{:ok, {:reauthenticate, user_id}}, current_user} when not is_nil(current_user) ->
        if to_string(current_user.id) == user_id,
          do: reauthentication_failure_response(conn),
          else: steam_unavailable_response(conn)

      _other ->
        steam_unavailable_response(conn)
    end
  end

  defp failure_response(conn, intent, reason) do
    log_failure(conn, :callback, reason)

    case {intent, conn.assigns[:current_user]} do
      {{:ok, {:link, user_id}}, current_user} when not is_nil(current_user) ->
        if to_string(current_user.id) == user_id do
          conn
          |> put_flash(:error, "Steam could not be linked to this account.")
          |> redirect(to: ~p"/profile")
        else
          authentication_failure_response(conn)
        end

      {{:ok, {:reauthenticate, user_id}}, current_user} when not is_nil(current_user) ->
        if to_string(current_user.id) == user_id,
          do: reauthentication_failure_response(conn),
          else: authentication_failure_response(conn)

      _other ->
        authentication_failure_response(conn)
    end
  end

  defp authentication_failure_response(conn) do
    conn
    |> Auth.put_auth_prompt(
      kind: :error,
      message: "Steam sign-in could not be completed. Try again or use email.",
      reauthenticate: false
    )
    |> redirect(to: failure_path(conn))
  end

  defp reauthentication_failure_response(conn) do
    conn
    |> Auth.put_auth_prompt(
      kind: :error,
      message: "Steam could not confirm the current account. Try another linked method.",
      reauthenticate: true
    )
    |> redirect(to: failure_path(conn))
  end

  defp steam_unavailable_response(conn) do
    conn
    |> Auth.put_auth_prompt(
      kind: :error,
      message: "Steam sign-in is temporarily unavailable. Use email to continue.",
      reauthenticate: false
    )
    |> redirect(to: failure_path(conn))
  end

  defp prepare_steam_request(conn, _opts) do
    conn = Auth.store_return_to(conn, conn.params["return_to"])

    conn =
      case {conn.params["intent"], Steam.fetch_intent(conn), conn.assigns[:current_user]} do
        {"reauthenticate", _intent, %Accounts.User{} = user} ->
          Steam.put_reauthenticate_intent(conn, user)

        {"reauthenticate", _intent, _current_user} ->
          conn
          |> Auth.put_auth_prompt(
            kind: :error,
            message: "Log in before confirming your identity.",
            reauthenticate: false
          )
          |> redirect(to: ~p"/")
          |> halt()

        {_intent, {:ok, {:link, _user_id}}, _current_user} ->
          conn

        {nil, _intent, nil} ->
          Steam.put_authenticate_intent(conn)

        {nil, _intent, %Accounts.User{}} ->
          signed_in_request_guard(conn)

        {_intent, _stored_intent, _current_user} ->
          conn |> reauthentication_failure_response() |> halt()
      end

    conn
    |> Map.update!(:params, &Map.drop(&1, @provider_request_params))
    |> Map.update!(:query_params, &Map.drop(&1, @provider_request_params))
  end

  # An already-authenticated player must not start an anonymous Steam flow
  # or switch accounts outside explicit sudo-protected linking.
  defp signed_in_request_guard(conn) do
    conn
    |> put_flash(:info, "You are already signed in. Link Steam from Account Settings instead.")
    |> redirect(to: ~p"/profile")
    |> halt()
  end

  defp require_steam_available(conn, _opts) do
    if Steam.available?() do
      conn
    else
      {intent, conn} = Steam.take_intent(conn)

      conn
      |> failure_response(intent, :provider_unavailable)
      |> halt()
    end
  end

  defp steam_linked?(user) do
    user
    |> Accounts.list_user_identities()
    |> Enum.any?(&(&1.provider == :steam))
  end

  defp failure_path(conn) do
    conn
    |> get_session(:return_to)
    |> Auth.safe_local_path(~p"/")
  end

  defp log_failure(_conn, outcome_class, reason) do
    metadata =
      maybe_put_request_id(
        [provider: :steam, outcome_class: outcome_class, reason: reason],
        Logger.metadata()[:request_id]
      )

    Logger.warning("Steam OpenID flow failed", metadata)
  end

  defp maybe_put_request_id(metadata, nil), do: metadata

  defp maybe_put_request_id(metadata, request_id),
    do: Keyword.put(metadata, :request_id, request_id)
end
