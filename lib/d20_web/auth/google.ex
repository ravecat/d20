defmodule D20Web.Auth.Google do
  @moduledoc """
  Normalizes Google results and owns short-lived browser-session flow state.

  Provider credentials and raw claims must not leave this boundary.
  """

  import Plug.Conn

  alias D20.Accounts.User

  @completion_max_age 600
  @completion_salt "google registration completion"
  @intent_session_key :google_auth_intent
  @completion_token_session_key :google_registration_token
  @completion_nonce_session_key :google_registration_nonce

  @type normalized_identity :: %{
          provider: :google,
          provider_uid: String.t(),
          email: String.t() | nil,
          email_verified: boolean()
        }

  @doc """
  Reports whether both runtime credentials required by Google OAuth are configured.
  """
  @spec available?() :: boolean()
  def available? do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth, [])

    not is_nil(config[:client_id]) and not is_nil(config[:client_secret])
  end

  @doc """
  Reduces a Google callback to the stable subject and transient email policy data.
  """
  @spec normalize(Ueberauth.Auth.t()) :: {:ok, normalized_identity()} | {:error, atom()}
  def normalize(%Ueberauth.Auth{
        provider: provider,
        uid: provider_uid,
        info: %Ueberauth.Auth.Info{email: email},
        extra: %Ueberauth.Auth.Extra{raw_info: raw_info}
      })
      when provider in [:google, "google"] do
    {:ok,
     %{
       provider: :google,
       provider_uid: provider_uid,
       email: email,
       email_verified: get_in(raw_info, [:user, "email_verified"]) == true
     }}
  end

  def normalize(%Ueberauth.Auth{}), do: {:error, :unexpected_provider}
  def normalize(_auth), do: {:error, :invalid_provider_result}

  @doc """
  Validates the additional email data required only for a new registration.
  """
  @spec registration_data(normalized_identity()) ::
          {:ok, %{provider_uid: String.t(), email: String.t()}} | {:error, atom()}
  def registration_data(%{provider_uid: provider_uid, email: email, email_verified: true})
      when is_binary(email) do
    changeset = User.email_changeset(%User{}, %{email: email}, validate_unique: false)

    if changeset.valid? do
      {:ok, %{provider_uid: provider_uid, email: Ecto.Changeset.get_change(changeset, :email)}}
    else
      {:error, :invalid_email}
    end
  end

  def registration_data(_identity), do: {:error, :unverified_email}

  @doc false
  def failure_reason(%Ueberauth.Failure{provider: provider})
      when provider in [:google, "google"],
      do: :provider_failure

  def failure_reason(%Ueberauth.Failure{}), do: :unexpected_provider
  def failure_reason(_failure), do: :invalid_provider_failure

  @doc """
  Stores an authentication intent in the signed browser session.
  """
  def put_authenticate_intent(conn) do
    put_session(conn, @intent_session_key, :authenticate)
  end

  @doc """
  Stores a link intent bound to the initiating D20 user.
  """
  def put_link_intent(conn, user) do
    put_session(conn, @intent_session_key, {:link, to_string(user.id)})
  end

  @doc """
  Reads the current intent without consuming it.
  """
  def fetch_intent(conn) do
    case get_session(conn, @intent_session_key) do
      nil -> {:error, :missing_intent}
      intent -> {:ok, intent}
    end
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

    with {:ok, %{provider_uid: provider_uid, email: email, nonce: ^session_nonce}} <-
           Phoenix.Token.verify(D20Web.Endpoint, @completion_salt, token,
             max_age: @completion_max_age
           ) do
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
end
