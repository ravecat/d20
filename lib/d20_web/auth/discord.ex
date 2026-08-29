defmodule D20Web.Auth.Discord do
  @moduledoc """
  Normalizes Discord results and owns short-lived browser-session flow state.

  Provider credentials and raw claims must not leave this boundary.
  """

  import Plug.Conn

  alias D20.Accounts.User

  @completion_max_age 600
  @completion_salt "discord registration completion"
  @intent_max_age 600
  @intent_session_key :discord_auth_intent
  @completion_token_session_key :discord_registration_token
  @completion_nonce_session_key :discord_registration_nonce

  @type normalized_identity :: %{
          provider: :discord,
          provider_uid: String.t(),
          email: String.t() | nil,
          email_verified: boolean()
        }

  @doc """
  Reports whether both runtime credentials required by Discord OAuth are configured.
  """
  @spec available?() :: boolean()
  def available? do
    case Application.get_env(:ueberauth, Ueberauth.Strategy.Discord.OAuth, []) do
      config when is_list(config) ->
        configured_credential?(config[:client_id]) and
          configured_credential?(config[:client_secret])

      _config ->
        false
    end
  end

  @doc """
  Reduces a Discord callback to the stable user ID and transient email policy data.
  """
  @spec normalize(Ueberauth.Auth.t()) :: {:ok, normalized_identity()} | {:error, atom()}
  def normalize(%Ueberauth.Auth{
        provider: provider,
        uid: provider_uid,
        info: %Ueberauth.Auth.Info{email: info_email},
        extra: %Ueberauth.Auth.Extra{raw_info: %{user: raw_user}}
      })
      when provider in [:discord, "discord"] and is_map(raw_user) do
    raw_uid = raw_claim(raw_user, :id)
    raw_email = raw_claim(raw_user, :email)
    verified = raw_claim(raw_user, :verified)

    with :ok <- validate_provider_uid(provider_uid),
         true <- raw_uid == provider_uid do
      {:ok,
       %{
         provider: :discord,
         provider_uid: provider_uid,
         email: info_email,
         email_verified: verified == true and raw_email == info_email
       }}
    else
      _ -> {:error, :invalid_provider_uid}
    end
  end

  def normalize(%Ueberauth.Auth{}), do: {:error, :unexpected_provider}
  def normalize(_auth), do: {:error, :invalid_provider_result}

  @doc """
  Retains a syntactically valid verified Discord email as an optional candidate.
  """
  @spec registration_data(normalized_identity()) ::
          {:ok, %{provider_uid: String.t(), email: String.t() | nil}}
  def registration_data(%{provider_uid: provider_uid} = identity) do
    email =
      if identity.email_verified do
        email_candidate(identity.email)
      end

    {:ok, %{provider_uid: provider_uid, email: email}}
  end

  @doc false
  def failure_reason(%Ueberauth.Failure{provider: provider})
      when provider in [:discord, "discord"],
      do: :provider_failure

  def failure_reason(%Ueberauth.Failure{}), do: :unexpected_provider
  def failure_reason(_failure), do: :invalid_provider_failure

  @doc """
  Stores an authentication intent in the signed browser session.
  """
  def put_authenticate_intent(conn) do
    put_session(conn, @intent_session_key, %{
      "action" => "authenticate",
      "issued_at" => System.system_time(:second)
    })
  end

  @doc """
  Stores a link intent bound to the initiating D20 user.
  """
  def put_link_intent(conn, user) do
    put_user_intent(conn, "link", user)
  end

  @doc """
  Stores a reauthentication intent bound to the current D20 user.
  """
  def put_reauthenticate_intent(conn, user) do
    put_user_intent(conn, "reauthenticate", user)
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
  Creates a signed, session-bound registration completion proof.
  """
  def put_registration(conn, %{provider_uid: provider_uid, email: email}, opts \\ []) do
    nonce = 32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

    token =
      Phoenix.Token.sign(
        D20Web.Endpoint,
        @completion_salt,
        %{provider_uid: provider_uid, email: email, nonce: nonce},
        opts
      )

    conn
    |> put_session(@completion_token_session_key, token)
    |> put_session(@completion_nonce_session_key, nonce)
  end

  @doc """
  Verifies the completion proof, age, and binding to the current browser session.
  """
  def fetch_registration(conn) do
    token = get_session(conn, @completion_token_session_key)
    session_nonce = get_session(conn, @completion_nonce_session_key)

    with true <- is_binary(token) and is_binary(session_nonce),
         {:ok, %{provider_uid: provider_uid, email: email, nonce: token_nonce}} <-
           Phoenix.Token.verify(D20Web.Endpoint, @completion_salt, token,
             max_age: @completion_max_age
           ),
         true <-
           is_binary(token_nonce) and byte_size(token_nonce) == byte_size(session_nonce) and
             Plug.Crypto.secure_compare(token_nonce, session_nonce),
         :ok <- validate_provider_uid(provider_uid),
         true <- is_nil(email) or is_binary(email) do
      {:ok, %{provider_uid: provider_uid, email: email}}
    else
      _ -> {:error, :invalid_or_expired_completion}
    end
  end

  @doc """
  Clears all registration completion state.
  """
  def clear_registration(conn) do
    conn
    |> delete_session(@completion_token_session_key)
    |> delete_session(@completion_nonce_session_key)
  end

  defp email_candidate(email) when is_binary(email) do
    changeset = User.email_candidate_changeset(%{email: email})

    if changeset.valid?, do: Ecto.Changeset.get_change(changeset, :email)
  end

  defp email_candidate(_email), do: nil

  # Ueberauth strategies expose raw provider claim maps with either atom or string
  # keys depending on the HTTP client, so the variance is resolved in one lookup.
  defp raw_claim(raw_user, key) when is_atom(key),
    do: Map.get(raw_user, key) || Map.get(raw_user, Atom.to_string(key))

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

  defp configured_credential?(value) when is_binary(value), do: String.trim(value) != ""
  defp configured_credential?(_value), do: false

  defp put_user_intent(conn, action, user) do
    put_session(conn, @intent_session_key, %{
      "action" => action,
      "user_id" => to_string(user.id),
      "issued_at" => System.system_time(:second)
    })
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp validate_intent(%{"action" => action, "issued_at" => issued_at} = intent)
       when action in ["authenticate", "link", "reauthenticate"] and is_integer(issued_at) do
    age = System.system_time(:second) - issued_at

    cond do
      age < 0 or age > @intent_max_age ->
        {:error, :invalid_or_expired_intent}

      action == "authenticate" ->
        {:ok, :authenticate}

      action == "link" and is_binary(intent["user_id"]) ->
        {:ok, {:link, intent["user_id"]}}

      action == "reauthenticate" and is_binary(intent["user_id"]) ->
        {:ok, {:reauthenticate, intent["user_id"]}}

      true ->
        {:error, :invalid_or_expired_intent}
    end
  end

  defp validate_intent(_intent), do: {:error, :invalid_or_expired_intent}
end
