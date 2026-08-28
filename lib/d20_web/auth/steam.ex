defmodule D20Web.Auth.Steam do
  @moduledoc """
  Normalizes Steam results and owns short-lived browser-session flow state.

  Provider protocol values, raw claims, and assertion data must not leave this
  boundary. Steam never supplies an email, so an unknown verified identity
  completes provider-only registration with a D20 username.
  """

  import Plug.Conn

  @intent_max_age 600
  @completion_max_age 600
  @completion_salt "steam registration completion"
  @intent_session_key :steam_auth_intent
  @completion_token_session_key :steam_registration_token
  @completion_nonce_session_key :steam_registration_nonce

  @type normalized_identity :: %{provider: :steam, provider_uid: String.t()}

  @doc """
  Reports whether the community Steam strategy and its required API key are configured.
  """
  @spec available?() :: boolean()
  def available? do
    strategy_configured?() and configured_api_key?()
  end

  @doc """
  Reduces a verified Steam result to the canonical provider identity.

  Steam supplies no email, so the normalized identity carries only the canonical
  unsigned 64-bit SteamID. Malformed UIDs are rejected before identity lookup.
  """
  @spec normalize(Ueberauth.Auth.t()) :: {:ok, normalized_identity()} | {:error, atom()}
  def normalize(%Ueberauth.Auth{provider: provider, uid: uid})
      when provider in [:steam, "steam"] do
    case canonical_steam_id(uid) do
      {:ok, steam_id} -> {:ok, %{provider: :steam, provider_uid: steam_id}}
      {:error, _reason} -> {:error, :invalid_provider_uid}
    end
  end

  def normalize(%Ueberauth.Auth{}), do: {:error, :unexpected_provider}
  def normalize(_auth), do: {:error, :invalid_provider_result}

  @doc """
  Reduces a verified Steam identity to the provider-only registration data.

  Steam supplies no email, so the registration candidate carries only the
  canonical SteamID and a nil email.
  """
  @spec registration_data(normalized_identity()) ::
          {:ok, %{provider_uid: String.t(), email: nil}}
  def registration_data(%{provider_uid: provider_uid}) do
    {:ok, %{provider_uid: provider_uid, email: nil}}
  end

  @doc false
  def failure_reason(%Ueberauth.Failure{provider: provider})
      when provider in [:steam, "steam"],
      do: :provider_failure

  def failure_reason(%Ueberauth.Failure{}), do: :unexpected_provider
  def failure_reason(_failure), do: :invalid_provider_failure

  @doc """
  Stores an authentication intent in the signed browser session.

  Records the accepted safe local return path at initiation so terminal
  outcomes never depend on a later session value.
  """
  def put_authenticate_intent(conn) do
    put_session(conn, @intent_session_key, %{
      "action" => "authenticate",
      "issued_at" => System.system_time(:second),
      "return_to" => get_session(conn, :return_to)
    })
  end

  @doc """
  Stores a link intent bound to the initiating D20 user.
  """
  def put_link_intent(conn, user) do
    put_session(conn, @intent_session_key, %{
      "action" => "link",
      "user_id" => to_string(user.id),
      "issued_at" => System.system_time(:second),
      "return_to" => get_session(conn, :return_to)
    })
  end

  @doc """
  Stores a reauthentication intent bound to the current D20 user.
  """
  def put_reauthenticate_intent(conn, user) do
    put_session(conn, @intent_session_key, %{
      "action" => "reauthenticate",
      "user_id" => to_string(user.id),
      "issued_at" => System.system_time(:second),
      "return_to" => get_session(conn, :return_to)
    })
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
  def put_registration(conn, %{provider_uid: provider_uid}, opts \\ []) do
    nonce = 32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

    token =
      Phoenix.Token.sign(
        D20Web.Endpoint,
        @completion_salt,
        %{provider_uid: provider_uid, nonce: nonce},
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

    with {:ok, %{provider_uid: provider_uid, nonce: ^session_nonce}} <-
           Phoenix.Token.verify(D20Web.Endpoint, @completion_salt, token,
             max_age: @completion_max_age
           ) do
      {:ok, %{provider_uid: provider_uid}}
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

  defp strategy_configured? do
    case Application.get_env(:ueberauth, Ueberauth, []) do
      config when is_list(config) ->
        match?(
          {Ueberauth.Strategy.Steam, options} when is_list(options),
          config |> Keyword.get(:providers, []) |> Keyword.get(:steam)
        )

      _config ->
        false
    end
  end

  defp configured_api_key? do
    case Application.get_env(:ueberauth, Ueberauth.Strategy.Steam, []) do
      config when is_list(config) ->
        case config[:api_key] do
          value when is_binary(value) -> String.trim(value) != ""
          _value -> false
        end

      _config ->
        false
    end
  end

  defp canonical_steam_id(value) when is_integer(value), do: canonical_steam_id(to_string(value))

  defp canonical_steam_id(value) when is_binary(value) do
    with true <- Regex.match?(~r/\A[1-9][0-9]{0,19}\z/, value),
         true <- String.to_integer(value) <= 18_446_744_073_709_551_615 do
      {:ok, value}
    else
      _other -> {:error, :invalid_provider_uid}
    end
  end

  defp canonical_steam_id(_value), do: {:error, :invalid_provider_uid}

  defp validate_intent(%{"action" => action, "issued_at" => issued_at} = intent)
       when action in ["authenticate", "link", "reauthenticate"] and is_integer(issued_at) do
    age = System.system_time(:second) - issued_at

    cond do
      age < 0 or age > @intent_max_age -> {:error, :invalid_or_expired_intent}
      action == "authenticate" -> {:ok, :authenticate}
      is_binary(intent["user_id"]) -> {:ok, {intent_action(action), intent["user_id"]}}
      true -> {:error, :invalid_or_expired_intent}
    end
  end

  defp validate_intent(_intent), do: {:error, :invalid_or_expired_intent}

  defp intent_action("link"), do: :link
  defp intent_action("reauthenticate"), do: :reauthenticate
end
