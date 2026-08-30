defmodule D20Web.Auth.AppleController do
  use D20Web, :controller

  alias D20.Accounts
  alias D20.Accounts.User
  alias D20Web.Auth
  alias D20Web.Auth.Apple

  plug :require_apple_available when action in [:request, :callback]
  plug :prepare_apple_request when action == :request
  plug :run_ueberauth when action in [:request, :callback]

  def request(conn, _params), do: conn

  def reauthentication(conn, _params), do: redirect(conn, to: ~p"/")

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    {conn, attempt_result} = Apple.consume_attempt(conn)

    with {:ok, attempt} <- attempt_result,
         {:ok, identity} <- Apple.normalize(auth) do
      handle_callback(conn, attempt, identity)
    else
      {:error, reason} -> callback_failure(conn, attempt_result, reason)
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    {conn, attempt_result} = Apple.consume_attempt(conn)
    callback_failure(conn, attempt_result, Apple.failure_reason(failure))
  end

  def callback(conn, _params) do
    {conn, attempt_result} = Apple.consume_attempt(conn)
    callback_failure(conn, attempt_result, :missing_provider_result)
  end

  def registration(conn, _params) do
    case Apple.fetch_registration(conn) do
      {:ok, completion} ->
        render_inertia(conn, "registration_completion", %{
          email: completion.email,
          submission: %{action: ~p"/auth/apple/register", credential: %{type: "server_cookie"}},
          cancel_action: ~p"/auth/apple/register/cancel"
        })

      {:error, reason} ->
        completion_failure(conn, reason, ~p"/")
    end
  end

  def complete_registration(conn, %{"user" => user_params}) when is_map(user_params) do
    case Apple.fetch_registration(conn) do
      {:ok, completion} -> complete_registration(conn, completion, user_params)
      {:error, reason} -> completion_failure(conn, reason, ~p"/")
    end
  end

  def complete_registration(conn, _params) do
    case Apple.fetch_registration(conn) do
      {:ok, _completion} ->
        conn
        |> assign_errors(%{username: "can't be blank"})
        |> put_status(:see_other)
        |> redirect(to: ~p"/auth/apple/register")

      {:error, reason} ->
        completion_failure(conn, reason, ~p"/")
    end
  end

  def cancel_registration(conn, _params) do
    conn
    |> Apple.clear_registration()
    |> put_flash(:info, "Registration cancelled. Choose another method to create your account.")
    |> redirect(to: ~p"/")
  end

  def link(conn, _params) do
    user = conn.assigns.current_user

    if apple_linked?(user) do
      conn
      |> put_flash(:info, "Apple is already linked to your account.")
      |> redirect(to: ~p"/profile")
    else
      redirect(conn, to: ~p"/auth/apple?intent=link")
    end
  end

  defp prepare_apple_request(conn, _opts) do
    with {:ok, action} <- request_action(conn.params["intent"]),
         {:ok, user_id} <- authorize_attempt(conn, action) do
      return_to = Auth.safe_local_path(conn.params["return_to"], default_return(action))

      conn
      |> Apple.put_attempt(%{action: action, return_to: return_to, user_id: user_id})
      |> Map.put(:params, %{})
      |> Map.put(:query_params, %{})
    else
      {:error, reason} ->
        conn
        |> request_failure(request_action_or_default(conn.params["intent"]), reason)
        |> halt()
    end
  end

  defp run_ueberauth(conn, _opts) do
    case conn.private.phoenix_action do
      :request -> Ueberauth.run_request(conn, :apple, Apple.provider_config())
      :callback -> Ueberauth.run_callback(conn, :apple, Apple.provider_config())
    end
  end

  defp request_action(nil), do: {:ok, :authenticate}
  defp request_action("link"), do: {:ok, :link}
  defp request_action("reauthenticate"), do: {:ok, :reauthenticate}
  defp request_action(_intent), do: {:error, :invalid_intent}

  defp request_action_or_default("link"), do: :link
  defp request_action_or_default("reauthenticate"), do: :reauthenticate
  defp request_action_or_default(_intent), do: :authenticate

  defp authorize_attempt(%{assigns: %{current_user: %User{} = user}}, :link) do
    if Accounts.sudo_mode?(user, -10),
      do: {:ok, to_string(user.id)},
      else: {:error, :sudo_required}
  end

  defp authorize_attempt(%{assigns: %{current_user: %User{} = user}}, :reauthenticate),
    do: {:ok, to_string(user.id)}

  defp authorize_attempt(%{assigns: %{current_user: nil}}, :authenticate), do: {:ok, nil}
  defp authorize_attempt(_conn, :authenticate), do: {:error, :already_authenticated}

  defp authorize_attempt(_conn, action) when action in [:link, :reauthenticate],
    do: {:error, :authentication_required}

  defp handle_callback(conn, %{action: :link} = attempt, identity) do
    complete_link(conn, attempt, identity)
  end

  defp handle_callback(conn, %{action: :reauthenticate} = attempt, identity) do
    expected_user = Accounts.get_user(attempt.user_id)
    identity_user = Accounts.get_user_by_identity(:apple, identity.provider_uid)

    if expected_user && identity_user && identity_user.id == expected_user.id do
      conn
      |> put_session(:return_to, attempt.return_to)
      |> put_flash(:info, "Identity confirmed.")
      |> Auth.log_in_user(expected_user)
    else
      cross_site_reauthentication_failure(conn, attempt)
    end
  end

  defp handle_callback(conn, %{action: :authenticate} = attempt, identity) do
    case Accounts.get_user_by_identity(:apple, identity.provider_uid) do
      %User{} = user ->
        conn
        |> put_session(:return_to, attempt.return_to)
        |> put_flash(:info, "Welcome back!")
        |> Auth.log_in_user(user)

      nil ->
        start_registration(conn, attempt, identity)
    end
  end

  defp start_registration(conn, attempt, identity) do
    {:ok, registration} = Apple.registration_data(identity)

    conn
    |> Apple.put_registration(%{
      provider_uid: registration.provider_uid,
      email: registration.email,
      return_to: attempt.return_to
    })
    |> redirect(to: ~p"/auth/apple/register")
  end

  defp complete_registration(conn, completion, user_params) do
    attrs = Map.put(user_params, "email", completion.email)

    case Accounts.register_user_with_identity(attrs, :apple, completion.provider_uid) do
      {:ok, user} ->
        conn
        |> Apple.clear_registration()
        |> put_session(:return_to, completion.return_to)
        |> put_flash(:info, "Account created successfully.")
        |> Auth.log_in_user(user, user_params)

      {:error, :user, %Ecto.Changeset{} = changeset} ->
        if Keyword.has_key?(changeset.errors, :username) and
             not Keyword.has_key?(changeset.errors, :email) do
          conn
          |> assign_errors(changeset)
          |> put_status(:see_other)
          |> redirect(to: ~p"/auth/apple/register")
        else
          completion_failure(conn, :account_conflict, completion.return_to)
        end

      {:error, :identity, %Ecto.Changeset{}} ->
        completion_failure(conn, :identity_conflict, completion.return_to)
    end
  end

  defp complete_link(conn, attempt, identity) do
    case Accounts.get_user(attempt.user_id) do
      %User{} = user -> link_identity(conn, user, identity.provider_uid)
      nil -> link_result(conn, :failed)
    end
  end

  defp link_identity(conn, user, provider_uid) do
    case Accounts.get_user_by_identity(:apple, provider_uid) do
      %User{id: owner_id} when owner_id == user.id ->
        link_result(conn, :linked)

      %User{} ->
        link_result(conn, :conflict)

      nil ->
        case Accounts.link_user_identity(user, :apple, provider_uid) do
          {:ok, _identity} -> link_result(conn, :linked)
          {:error, %Ecto.Changeset{}} -> resolve_link_race(conn, user, provider_uid)
        end
    end
  end

  defp resolve_link_race(conn, user, provider_uid) do
    case Accounts.get_user_by_identity(:apple, provider_uid) do
      %User{id: owner_id} when owner_id == user.id -> link_result(conn, :linked)
      _other -> link_result(conn, :conflict)
    end
  end

  defp callback_failure(conn, {:ok, %{action: :link}}, _reason),
    do: link_result(conn, :failed)

  defp callback_failure(conn, {:ok, %{action: :reauthenticate} = attempt}, _reason),
    do: cross_site_reauthentication_failure(conn, attempt)

  defp callback_failure(conn, {:ok, attempt}, reason),
    do: authentication_failure(conn, reason, attempt.return_to)

  defp callback_failure(conn, _attempt_result, reason),
    do: authentication_failure(conn, reason, ~p"/")

  defp request_failure(conn, :link, _reason), do: link_result(conn, :failed)

  defp request_failure(conn, :reauthenticate, _reason) do
    reauthentication_failure(
      conn,
      Auth.safe_local_path(conn.params["return_to"], default_return(:reauthenticate))
    )
  end

  defp request_failure(conn, :authenticate, reason),
    do:
      authentication_failure(conn, reason, Auth.safe_local_path(conn.params["return_to"], ~p"/"))

  defp completion_failure(conn, reason, return_to) do
    conn
    |> Apple.clear_registration()
    |> authentication_failure(reason, return_to)
  end

  defp authentication_failure(conn, reason, return_to) do
    conn
    |> Auth.store_return_to(return_to)
    |> Auth.put_auth_prompt(kind: :error, message: failure_message(reason), reauthenticate: false)
    |> redirect(to: Auth.safe_local_path(return_to, ~p"/"))
  end

  defp cross_site_reauthentication_failure(conn, attempt) do
    conn
    |> Apple.put_reauthentication_result(attempt.user_id, attempt.return_to)
    |> redirect(to: ~p"/auth/apple/reauthentication")
  end

  defp reauthentication_failure(conn, return_to) do
    conn
    |> Auth.store_return_to(return_to)
    |> Auth.put_auth_prompt(
      kind: :error,
      message: "Apple could not confirm the current account. Try another linked method.",
      reauthenticate: true
    )
    |> redirect(to: Auth.safe_local_path(return_to, ~p"/"))
  end

  defp link_result(conn, result) do
    conn
    |> Apple.put_link_result(result)
    |> redirect(to: ~p"/profile")
  end

  defp require_apple_available(conn, _opts) do
    if Apple.available?() do
      conn
    else
      unavailable_response(conn)
      |> halt()
    end
  end

  defp unavailable_response(%{private: %{phoenix_action: :callback}} = conn) do
    {conn, attempt_result} = Apple.consume_attempt(conn)
    callback_failure(conn, attempt_result, :provider_unavailable)
  end

  defp unavailable_response(conn) do
    request_failure(conn, request_action_or_default(conn.params["intent"]), :provider_unavailable)
  end

  defp apple_linked?(user) do
    user
    |> Accounts.list_user_identities()
    |> Enum.any?(&(&1.provider == :apple))
  end

  defp default_return(:link), do: ~p"/profile"
  defp default_return(:reauthenticate), do: ~p"/"
  defp default_return(:authenticate), do: ~p"/"

  defp failure_message(:provider_unavailable) do
    "Apple sign-in is temporarily unavailable. Use email to continue."
  end

  defp failure_message(_reason) do
    "Apple sign-in could not be completed. Try again or use email."
  end
end
