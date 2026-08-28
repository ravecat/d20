defmodule D20Web.Auth.Facebook do
  @moduledoc """
  Normalizes Facebook results and owns short-lived registration and intent state.

  The exact Facebook UID is authoritative. A consistent valid email is retained
  only as an optional server-owned registration candidate. Provider credentials
  and unrelated raw claims must not leave this boundary.
  """

  import Plug.Conn

  alias D20.Accounts.User

  @flow_max_age 600
  @intent_session_key :facebook_auth_intent
  @registration_salt "facebook registration"
  @registration_token_session_key :facebook_registration_token
  @registration_nonce_session_key :facebook_registration_nonce

  @type normalized_identity :: %{
          provider: :facebook,
          provider_uid: String.t(),
          email: String.t() | nil
        }

  @type registration :: %{
          provider_uid: String.t(),
          email: String.t() | nil,
          return_to: String.t()
        }

  @doc """
  Reports whether both runtime credentials required by Facebook OAuth are configured.
  """
  @spec available?() :: boolean()
  def available? do
    case Application.get_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth, []) do
      config when is_list(config) ->
        configured_credential?(config[:client_id]) and
          configured_credential?(config[:client_secret])

      _config ->
        false
    end
  end

  @doc """
  Reduces a Facebook callback to its app-scoped user ID and optional email candidate.
  """
  @spec normalize(Ueberauth.Auth.t()) :: {:ok, normalized_identity()} | {:error, atom()}
  def normalize(%Ueberauth.Auth{
        provider: provider,
        uid: provider_uid,
        info: %Ueberauth.Auth.Info{email: info_email},
        extra: %Ueberauth.Auth.Extra{raw_info: %{user: raw_user}}
      })
      when provider in [:facebook, "facebook"] and is_map(raw_user) do
    raw_uid = raw_user["id"] || raw_user[:id]
    raw_email = raw_user["email"] || raw_user[:email]

    with :ok <- validate_provider_uid(provider_uid),
         true <- raw_uid == provider_uid do
      {:ok,
       %{
         provider: :facebook,
         provider_uid: provider_uid,
         email: normalize_email_candidate(info_email, raw_email)
       }}
    else
      _ -> {:error, :invalid_provider_uid}
    end
  end

  def normalize(%Ueberauth.Auth{}), do: {:error, :unexpected_provider}
  def normalize(_auth), do: {:error, :invalid_provider_result}

  @doc false
  def failure_reason(%Ueberauth.Failure{provider: provider})
      when provider in [:facebook, "facebook"],
      do: :provider_failure

  def failure_reason(%Ueberauth.Failure{}), do: :unexpected_provider
  def failure_reason(_failure), do: :invalid_provider_failure

  @doc """
  Stores a normal authentication intent in the signed browser session.
  """
  def put_authenticate_intent(conn) do
    put_intent(conn, %{"action" => "authenticate"})
  end

  @doc """
  Stores a link intent bound to the initiating D20 user.
  """
  def put_link_intent(conn, user) do
    put_intent(conn, %{"action" => "link", "user_id" => to_string(user.id)})
  end

  @doc """
  Stores a reauthentication intent bound to the current D20 user.
  """
  def put_reauthenticate_intent(conn, user) do
    put_intent(conn, %{"action" => "reauthenticate", "user_id" => to_string(user.id)})
  end

  @doc """
  Reads a valid current intent without consuming it.
  """
  def fetch_intent(conn) do
    conn
    |> get_session(@intent_session_key)
    |> validate_intent()
  end

  @doc """
  Reads and consumes the current intent.
  """
  def take_intent(conn) do
    {fetch_intent(conn), delete_session(conn, @intent_session_key)}
  end

  @doc """
  Stores the unknown Facebook identity needed by username-only registration.
  """
  def put_registration(conn, identity, return_to, opts \\ []) do
    nonce = nonce()

    token =
      Phoenix.Token.sign(
        D20Web.Endpoint,
        @registration_salt,
        %{
          provider_uid: identity.provider_uid,
          email: identity.email,
          return_to: return_to,
          nonce: nonce
        },
        Keyword.take(opts, [:signed_at])
      )

    conn
    |> put_session(@registration_token_session_key, token)
    |> put_session(@registration_nonce_session_key, nonce)
  end

  @doc """
  Reads the short-lived session-bound registration state.
  """
  @spec fetch_registration(Plug.Conn.t()) :: {:ok, registration()} | {:error, atom()}
  def fetch_registration(conn) do
    token = get_session(conn, @registration_token_session_key)
    session_nonce = get_session(conn, @registration_nonce_session_key)

    with true <- is_binary(token) and is_binary(session_nonce),
         {:ok,
          %{provider_uid: provider_uid, email: email, return_to: return_to, nonce: token_nonce}} <-
           Phoenix.Token.verify(D20Web.Endpoint, @registration_salt, token,
             max_age: @flow_max_age
           ),
         true <- secure_nonce?(token_nonce, session_nonce),
         :ok <- validate_provider_uid(provider_uid),
         true <- is_nil(email) or is_binary(email),
         true <- is_binary(return_to) do
      {:ok, %{provider_uid: provider_uid, email: email, return_to: return_to}}
    else
      _ -> {:error, :invalid_or_expired_registration}
    end
  end

  @doc """
  Clears provider registration state.
  """
  def clear_registration(conn) do
    conn
    |> delete_session(@registration_token_session_key)
    |> delete_session(@registration_nonce_session_key)
  end

  defp put_intent(conn, intent) do
    put_session(
      conn,
      @intent_session_key,
      Map.put(intent, "issued_at", System.system_time(:second))
    )
  end

  defp validate_intent(%{"action" => action, "issued_at" => issued_at} = intent)
       when action in ["authenticate", "link", "reauthenticate"] and is_integer(issued_at) do
    age = System.system_time(:second) - issued_at

    cond do
      age < 0 or age > @flow_max_age ->
        {:error, :invalid_or_expired_intent}

      action == "authenticate" ->
        {:ok, :authenticate}

      action == "link" and valid_registration_value?(intent["user_id"]) ->
        {:ok, {:link, intent["user_id"]}}

      action == "reauthenticate" and valid_registration_value?(intent["user_id"]) ->
        {:ok, {:reauthenticate, intent["user_id"]}}

      true ->
        {:error, :invalid_or_expired_intent}
    end
  end

  defp validate_intent(_intent), do: {:error, :invalid_or_expired_intent}

  defp normalize_email_candidate(info_email, raw_email)
       when is_binary(info_email) and info_email == raw_email do
    changeset = User.email_candidate_changeset(%{email: info_email})

    if changeset.valid?, do: Ecto.Changeset.get_change(changeset, :email), else: nil
  end

  defp normalize_email_candidate(_info_email, _raw_email), do: nil

  defp validate_provider_uid(provider_uid)
       when is_binary(provider_uid) and byte_size(provider_uid) > 0 and
              byte_size(provider_uid) <= 255 do
    if String.valid?(provider_uid) and String.trim(provider_uid) != "" do
      :ok
    else
      {:error, :invalid_provider_uid}
    end
  end

  defp validate_provider_uid(_provider_uid), do: {:error, :invalid_provider_uid}

  defp valid_registration_value?(value) when is_binary(value),
    do: String.valid?(value) and String.trim(value) != ""

  defp valid_registration_value?(_value), do: false

  defp configured_credential?(value) when is_binary(value), do: String.trim(value) != ""
  defp configured_credential?(_value), do: false

  defp secure_nonce?(token_nonce, session_nonce)
       when is_binary(token_nonce) and byte_size(token_nonce) == byte_size(session_nonce),
       do: Plug.Crypto.secure_compare(token_nonce, session_nonce)

  defp secure_nonce?(_token_nonce, _session_nonce), do: false

  defp nonce, do: 32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
end
