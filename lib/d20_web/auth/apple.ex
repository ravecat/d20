defmodule D20Web.Auth.Apple do
  @moduledoc """
  Normalizes trusted Apple strategy results and owns minimal callback state.

  Provider credentials and raw claims stop at this web boundary. Accounts only
  receives the stable provider subject and an optional verified email candidate.
  Short-lived D20 state stays in encrypted provider
  cookies because Apple's POST callback cannot read the Lax session.
  """

  import Plug.Conn

  alias D20.Accounts
  alias D20.Accounts.User
  alias Ueberauth.Auth
  alias Ueberauth.Auth.Info
  alias Ueberauth.Strategy.Apple, as: AppleStrategy

  @flow_cookie "_d20_apple_flow"
  @flow_max_age 600
  @flow_secret "d20 apple flow state"
  @cookie_path "/auth/apple"
  @link_result_cookie "_d20_apple_link_result"
  @link_result_max_age 600
  @link_result_secret "d20 apple link result"
  @link_result_cookie_path "/users/settings"
  @reauthentication_result_cookie "_d20_apple_reauthentication_result"
  @reauthentication_result_max_age 600
  @reauthentication_result_secret "d20 apple reauthentication result"
  @provider_uid_max_bytes 255
  @required_config_keys [:client_id, :team_id, :key_id, :private_key_base64, :callback_url]

  @type normalized_identity :: %{
          provider: :apple,
          provider_uid: String.t(),
          email: String.t() | nil
        }

  @type registration_data :: %{provider_uid: String.t(), email: String.t() | nil}
  @type attempt :: %{
          action: :authenticate | :link | :reauthenticate,
          return_to: String.t(),
          user_id: String.t() | nil
        }
  @type registration :: %{
          provider_uid: String.t(),
          email: String.t() | nil,
          return_to: String.t()
        }
  @type link_result :: :linked | :conflict | :failed

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, :link_result), do: consume_link_result(conn)
  def call(conn, :reauthentication), do: consume_reauthentication(conn)

  @doc """
  Reports whether every runtime value required by Apple authentication is configured.
  """
  @spec available?() :: boolean()
  def available? do
    case Application.get_env(:ueberauth, AppleStrategy, []) do
      config when is_list(config) -> Enum.all?(@required_config_keys, &(not is_nil(config[&1])))
      _config -> false
    end
  end

  @doc """
  Returns the explicit Apple strategy configuration used by the controller.

  Apple is intentionally not added to Ueberauth's global provider routes so its
  runtime callback URL cannot replace the existing Google configuration.
  """
  @spec provider_config() :: {module(), keyword()}
  def provider_config do
    config = Application.fetch_env!(:ueberauth, AppleStrategy)

    {AppleStrategy,
     callback_methods: ["POST"],
     default_scope: "email",
     callback_url: Keyword.fetch!(config, :callback_url),
     client_id: Keyword.fetch!(config, :client_id),
     client_secret: {__MODULE__, :client_secret}}
  end

  @doc """
  Generates the Apple OAuth client-secret JWT from the configured source credentials.
  """
  @spec client_secret(keyword()) :: String.t()
  def client_secret(_oauth_options) do
    config = Application.fetch_env!(:ueberauth, AppleStrategy)

    UeberauthApple.generate_client_secret(%{
      client_id: Keyword.fetch!(config, :client_id),
      team_id: Keyword.fetch!(config, :team_id),
      key_id: Keyword.fetch!(config, :key_id),
      private_key: config |> Keyword.fetch!(:private_key_base64) |> Base.decode64!()
    })
  end

  @doc """
  Reduces a validated Ueberauth Apple result to D20 primitives.
  """
  @spec normalize(Auth.t()) :: {:ok, normalized_identity()} | {:error, atom()}
  def normalize(%Auth{provider: provider, uid: uid, info: %Info{email: email}})
      when provider in [:apple, "apple"] do
    with {:ok, provider_uid} <- provider_uid(uid) do
      {:ok,
       %{
         provider: :apple,
         provider_uid: provider_uid,
         email: if(is_binary(email), do: email, else: nil)
       }}
    end
  end

  def normalize(%Auth{}), do: {:error, :unexpected_provider}
  def normalize(_auth), do: {:error, :invalid_auth_result}

  @doc """
  Retains a syntactically valid Apple email as an optional registration candidate.
  """
  @spec registration_data(normalized_identity()) :: {:ok, registration_data()}
  def registration_data(%{provider_uid: provider_uid, email: email}) do
    {:ok, %{provider_uid: provider_uid, email: email_candidate(email)}}
  end

  @doc """
  Stores the D20 intent needed by Apple's cross-site POST callback.
  """
  @spec put_attempt(Plug.Conn.t(), attempt(), keyword()) :: Plug.Conn.t()
  def put_attempt(conn, attempt, opts \\ []) do
    token =
      encrypt_flow(
        {:attempt, Map.fetch!(attempt, :action), Map.fetch!(attempt, :return_to),
         Map.get(attempt, :user_id)},
        opts
      )

    put_resp_cookie(conn, @flow_cookie, token, attempt_cookie_options())
  end

  @doc """
  Reads and consumes the current Apple attempt.
  """
  @spec consume_attempt(Plug.Conn.t()) ::
          {Plug.Conn.t(), {:ok, attempt()} | {:error, atom()}}
  def consume_attempt(conn) do
    conn = fetch_cookies(conn)
    result = conn.cookies[@flow_cookie] |> decrypt_flow() |> parse_attempt()

    {delete_resp_cookie(conn, @flow_cookie, attempt_cookie_options()), result}
  end

  @doc """
  Replaces the consumed attempt with same-site registration state.
  """
  @spec put_registration(Plug.Conn.t(), registration(), keyword()) :: Plug.Conn.t()
  def put_registration(conn, registration, opts \\ []) do
    token =
      encrypt_flow(
        {:registration, Map.fetch!(registration, :provider_uid), Map.fetch!(registration, :email),
         Map.fetch!(registration, :return_to)},
        opts
      )

    put_resp_cookie(conn, @flow_cookie, token, registration_cookie_options())
  end

  @doc """
  Reads unexpired Apple registration state without consuming retryable errors.
  """
  @spec fetch_registration(Plug.Conn.t()) :: {:ok, registration()} | {:error, atom()}
  def fetch_registration(conn) do
    conn = fetch_cookies(conn)
    conn.cookies[@flow_cookie] |> decrypt_flow() |> parse_registration()
  end

  @doc """
  Clears Apple registration state after a terminal result.
  """
  @spec clear_registration(Plug.Conn.t()) :: Plug.Conn.t()
  def clear_registration(conn) do
    delete_resp_cookie(conn, @flow_cookie, registration_cookie_options())
  end

  @doc """
  Stores a bounded Apple link result for the first same-site settings request.
  """
  @spec put_link_result(Plug.Conn.t(), link_result(), keyword()) :: Plug.Conn.t()
  def put_link_result(conn, result, opts \\ []) when result in [:linked, :conflict, :failed] do
    token =
      Phoenix.Token.encrypt(
        D20Web.Endpoint,
        @link_result_secret,
        result,
        [max_age: @link_result_max_age] ++ Keyword.take(opts, [:signed_at])
      )

    put_resp_cookie(conn, @link_result_cookie, token, link_result_cookie_options())
  end

  @doc false
  @spec flow_cookie() :: String.t()
  def flow_cookie, do: @flow_cookie

  @doc false
  @spec link_result_cookie() :: String.t()
  def link_result_cookie, do: @link_result_cookie

  @doc """
  Stores a failed cross-site reauthentication result for same-site consumption.
  """
  def put_reauthentication_result(conn, user_id, return_to, opts \\ []) do
    token =
      Phoenix.Token.encrypt(
        D20Web.Endpoint,
        @reauthentication_result_secret,
        {:failed, user_id, return_to},
        [max_age: @reauthentication_result_max_age] ++ Keyword.take(opts, [:signed_at])
      )

    put_resp_cookie(
      conn,
      @reauthentication_result_cookie,
      token,
      reauthentication_result_cookie_options()
    )
  end

  @doc false
  def reauthentication_result_cookie, do: @reauthentication_result_cookie

  @doc false
  @spec failure_reason(Ueberauth.Failure.t() | term()) :: atom()
  def failure_reason(%Ueberauth.Failure{provider: provider})
      when provider in [:apple, "apple"],
      do: :provider_failure

  def failure_reason(%Ueberauth.Failure{}), do: :unexpected_provider
  def failure_reason(_failure), do: :invalid_provider_failure

  defp consume_reauthentication(conn) do
    conn = fetch_cookies(conn)

    case conn.cookies[@reauthentication_result_cookie] do
      nil ->
        conn

      token ->
        conn =
          delete_resp_cookie(
            conn,
            @reauthentication_result_cookie,
            reauthentication_result_cookie_options()
          )

        case Phoenix.Token.decrypt(D20Web.Endpoint, @reauthentication_result_secret, token,
               max_age: @reauthentication_result_max_age
             ) do
          {:ok, {:failed, user_id, return_to}} ->
            put_reauthentication_failure(conn, user_id, return_to)

          _invalid ->
            conn
        end
    end
  end

  defp put_reauthentication_failure(
         %{assigns: %{current_user: %User{id: current_user_id}}} = conn,
         user_id,
         return_to
       ) do
    if to_string(current_user_id) == user_id do
      conn
      |> D20Web.Auth.store_return_to(return_to)
      |> D20Web.Auth.put_auth_prompt(
        kind: :error,
        message: "Apple could not confirm the current account. Try another linked method.",
        reauthenticate: true
      )
      |> Phoenix.Controller.redirect(to: "/")
      |> halt()
    else
      conn
    end
  end

  defp put_reauthentication_failure(conn, _user_id, _return_to), do: conn

  defp consume_link_result(conn) do
    conn = fetch_cookies(conn)

    case conn.cookies[@link_result_cookie] do
      nil ->
        conn

      token ->
        conn = delete_resp_cookie(conn, @link_result_cookie, link_result_cookie_options())

        case decrypt_link_result(token) do
          {:ok, :linked} -> put_verified_link_flash(conn)
          {:ok, result} -> put_link_flash(conn, result)
          {:error, _reason} -> conn
        end
    end
  end

  defp decrypt_link_result(token) do
    case Phoenix.Token.decrypt(D20Web.Endpoint, @link_result_secret, token,
           max_age: @link_result_max_age
         ) do
      {:ok, result} when result in [:linked, :conflict, :failed] -> {:ok, result}
      {:ok, _result} -> {:error, :invalid_link_result}
      {:error, reason} -> {:error, reason}
    end
  end

  defp put_verified_link_flash(%{assigns: %{current_user: %User{} = user}} = conn) do
    if user |> Accounts.list_user_identities() |> Enum.any?(&(&1.provider == :apple)) do
      put_link_flash(conn, :linked)
    else
      conn
    end
  end

  defp put_verified_link_flash(conn), do: conn

  defp put_link_flash(conn, :linked) do
    conn
    |> Phoenix.Controller.put_flash(:info, "Apple was linked to this account.")
    |> redirect_to_settings()
  end

  defp put_link_flash(conn, :conflict) do
    conn
    |> Phoenix.Controller.put_flash(
      :error,
      "Apple could not be linked because that identity is unavailable."
    )
    |> redirect_to_settings()
  end

  defp put_link_flash(conn, :failed) do
    conn
    |> Phoenix.Controller.put_flash(:error, "Apple could not be linked. Try again.")
    |> redirect_to_settings()
  end

  defp redirect_to_settings(conn) do
    conn
    |> Phoenix.Controller.redirect(to: @link_result_cookie_path)
    |> halt()
  end

  defp encrypt_flow(data, opts) do
    Phoenix.Token.encrypt(
      D20Web.Endpoint,
      @flow_secret,
      data,
      [max_age: @flow_max_age] ++ Keyword.take(opts, [:signed_at])
    )
  end

  defp decrypt_flow(token) do
    case Phoenix.Token.decrypt(D20Web.Endpoint, @flow_secret, token, max_age: @flow_max_age) do
      {:ok, flow} -> {:ok, flow}
      {:error, :missing} -> {:error, :missing_flow_state}
      {:error, :expired} -> {:error, :expired_flow_state}
      {:error, :invalid} -> {:error, :invalid_flow_state}
    end
  end

  defp parse_attempt({:ok, {:attempt, :authenticate, return_to, nil}})
       when is_binary(return_to),
       do: {:ok, %{action: :authenticate, return_to: return_to, user_id: nil}}

  defp parse_attempt({:ok, {:attempt, action, return_to, user_id}})
       when action in [:link, :reauthenticate] and is_binary(return_to) and is_binary(user_id) and
              user_id != "",
       do: {:ok, %{action: action, return_to: return_to, user_id: user_id}}

  defp parse_attempt({:ok, _flow}), do: {:error, :invalid_flow_state}
  defp parse_attempt({:error, _reason} = error), do: error

  defp parse_registration({:ok, {:registration, provider_uid, email, return_to}})
       when is_binary(provider_uid) and provider_uid != "" and (is_nil(email) or is_binary(email)) and
              is_binary(return_to),
       do: {:ok, %{provider_uid: provider_uid, email: email, return_to: return_to}}

  defp parse_registration({:ok, _flow}), do: {:error, :invalid_flow_state}
  defp parse_registration({:error, _reason} = error), do: error

  defp email_candidate(email) when is_binary(email) do
    changeset = User.email_candidate_changeset(%{email: email})

    if changeset.valid?, do: Ecto.Changeset.get_change(changeset, :email)
  end

  defp email_candidate(_email), do: nil

  defp provider_uid(uid)
       when is_binary(uid) and byte_size(uid) > 0 and byte_size(uid) <= @provider_uid_max_bytes do
    if String.valid?(uid) and String.trim(uid) != "" do
      {:ok, uid}
    else
      {:error, :invalid_provider_uid}
    end
  end

  defp provider_uid(_uid), do: {:error, :invalid_provider_uid}

  defp attempt_cookie_options do
    [http_only: true, secure: true, same_site: "None", max_age: @flow_max_age, path: @cookie_path]
  end

  defp registration_cookie_options do
    [http_only: true, secure: true, same_site: "Lax", max_age: @flow_max_age, path: @cookie_path]
  end

  defp reauthentication_result_cookie_options do
    [
      http_only: true,
      secure: true,
      same_site: "Lax",
      max_age: @reauthentication_result_max_age,
      path: "/"
    ]
  end

  defp link_result_cookie_options do
    [
      http_only: true,
      secure: true,
      same_site: "Lax",
      max_age: @link_result_max_age,
      path: @link_result_cookie_path
    ]
  end
end
