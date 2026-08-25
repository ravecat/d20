defmodule D20Web.Auth do
  @moduledoc """
  Owns generic browser authentication and D20 session behavior.

  Provider-specific OAuth adapters and controllers live below this namespace.
  """

  use D20Web, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias D20.Accounts
  alias D20.Accounts.Anonymous
  alias D20.Accounts.Scope
  alias D20.Accounts.User
  alias D20.Actors.Actor
  alias D20Web.Auth.Apple
  alias D20Web.Auth.Discord
  alias D20Web.Auth.Google

  # Make the remember me cookie valid for 14 days. This should match
  # the session validity setting in UserToken.
  @max_cookie_age_in_days 14
  @remember_me_cookie "_d20_web_user_remember_me"
  @remember_me_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  # How old the session token should be before a new one is issued. When a request is made
  # with a session token older than this value, then a new session token will be created
  # and the session and remember-me cookies (if set) will be updated with the new token.
  # Lowering this value will result in more tokens being created by active users. Increasing
  # it will result in less time before a session token expires for a user to get issued a new
  # token. This can be set to a value greater than `@max_cookie_age_in_days` to disable
  # the reissuing of tokens completely.
  @session_reissue_age_in_days 7

  @type prompt_kind :: :info | :warning | :error

  @doc """
  Logs the user in.

  Redirects to the session's `:return_to` path
  or falls back to the `signed_in_path/1`.
  """
  def log_in_user(conn, user, params \\ %{}) do
    path = get_session(conn, :return_to) || signed_in_path(conn)

    conn
    |> create_or_extend_session(user, params)
    |> maybe_force_full_page_redirect()
    |> redirect(to: path)
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      D20Web.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session(nil)
    |> delete_resp_cookie(@remember_me_cookie, @remember_me_options)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session and remember me token.

  Will reissue the session token if it is older than the configured age.
  """
  def fetch_scope_for_actor(conn, _opts) do
    with {token, conn} <- ensure_user_token(conn),
         {user, token_inserted_at} <- Accounts.get_user_by_session_token(token) do
      conn
      |> assign(:current_user, user)
      |> assign(:scope, Scope.for_actor(user))
      |> maybe_reissue_user_session_token(user, token_inserted_at)
    else
      nil -> assign_anonymous_scope(conn)
    end
  end

  defp assign_anonymous_scope(conn) do
    anonymous = get_anonymous(conn)

    conn
    |> assign(:current_user, nil)
    |> put_session(:anonymous_user_id, anonymous.id)
    |> assign(:scope, Scope.for_actor(anonymous))
  end

  def put_actor_token(%{assigns: %{scope: %Scope{actor: %Actor{} = actor}}} = conn, _opts) do
    assign(conn, :actor_token, D20.Actors.Token.sign(D20Web.Endpoint, actor))
  end

  def put_actor_token(conn, _opts), do: conn

  @doc """
  Exposes authentication state and any stored prompt to the next Inertia page.
  """
  def put_auth_prop(%{assigns: %{current_user: current_user}} = conn, _opts) do
    prompt = get_session(conn, :auth_prompt)

    conn
    |> Inertia.Controller.assign_shared_prop(:auth, %{
      authenticated: not is_nil(current_user),
      local: local_mailbox_available?(),
      prompt: prompt,
      providers: %{
        apple: %{available: Apple.available?()},
        discord: %{available: Discord.available?()},
        google: %{available: Google.available?()}
      }
    })
    |> then(fn conn -> if prompt, do: delete_session(conn, :auth_prompt), else: conn end)
  end

  @doc """
  Stores the shared account dialog state for the next Inertia page.
  """
  def put_auth_prompt(conn, opts) do
    current_user = conn.assigns[:current_user]
    kind = Keyword.fetch!(opts, :kind)

    unless kind in [:info, :warning, :error] do
      raise ArgumentError, "unsupported authentication prompt kind: #{inspect(kind)}"
    end

    prompt = %{
      email: if(current_user, do: current_user.email, else: ""),
      kind: kind,
      message: Keyword.fetch!(opts, :message),
      reauthenticate: Keyword.get(opts, :reauthenticate, not is_nil(current_user)),
      return_to: safe_local_path(get_session(conn, :return_to), ~p"/")
    }

    put_session(conn, :auth_prompt, prompt)
  end

  @doc """
  Stores a local absolute path as the post-authentication destination.

  External, protocol-relative, malformed, and backslash-containing paths are ignored.
  """
  def store_return_to(conn, path) do
    case safe_local_path(path, nil) do
      nil -> conn
      local_path -> put_session(conn, :return_to, local_path)
    end
  end

  @doc """
  Returns a submitted local absolute path or the provided safe fallback.
  """
  def safe_local_path(path, fallback) when is_binary(path) do
    with {:ok, %URI{scheme: nil, host: nil, path: local_path}} <- URI.new(path),
         true <- is_binary(local_path) and String.starts_with?(local_path, "/"),
         false <- Regex.match?(~r/%(?![[:xdigit:]]{2})/, path),
         decoded_path = URI.decode(path),
         false <- String.starts_with?(decoded_path, "//"),
         false <- String.contains?(decoded_path, ["\\", "\r", "\n"]) do
      path
    else
      _ -> fallback
    end
  end

  def safe_local_path(_path, fallback), do: fallback

  defp get_anonymous(conn) do
    case get_session(conn, :anonymous_user_id) do
      nil -> Anonymous.new()
      anonymous_user_id -> Anonymous.from_id(anonymous_user_id)
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, conn |> put_token_in_session(token) |> put_session(:user_remember_me, true)}
      else
        nil
      end
    end
  end

  # Reissue the session token if it is older than the configured reissue age.
  defp maybe_reissue_user_session_token(conn, user, token_inserted_at) do
    token_age = DateTime.diff(DateTime.utc_now(:second), token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, user, %{})
    else
      conn
    end
  end

  # This function is the one responsible for creating session tokens
  # and storing them safely in the session and cookies. It may be called
  # either when logging in, during sudo mode, or to renew a session which
  # will soon expire.
  #
  # When the session is created, rather than extended, the renew_session
  # function will clear the session to avoid fixation attacks. See the
  # renew_session function to customize this behaviour.
  defp create_or_extend_session(conn, user, params) do
    token = Accounts.generate_user_session_token(user)
    remember_me = get_session(conn, :user_remember_me)

    conn
    |> renew_session(user)
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  # Do not renew session if the user is already logged in
  # to prevent CSRF errors or data being lost in tabs that are still open
  defp renew_session(%{assigns: %{current_user: %User{id: id}}} = conn, %User{id: id}) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn, _user) do
  #       delete_csrf_token()
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn, _user) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}, _),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, _params, true),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, _token, _params, _), do: conn

  defp write_remember_me_cookie(conn, token) do
    conn
    |> put_session(:user_remember_me, true)
    |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  end

  defp put_token_in_session(conn, token) do
    put_session(conn, :user_token, token)
  end

  @doc """
  Plug for routes that require sudo mode.
  """
  def require_sudo_mode(conn, _opts) do
    if Accounts.sudo_mode?(conn.assigns.current_user, -10) do
      conn
    else
      conn
      |> maybe_store_return_to()
      |> put_auth_prompt(
        kind: :warning,
        message: "You must re-authenticate to access this page.",
        reauthenticate: true
      )
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  @doc """
  Plug for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if authenticated?(conn.assigns.current_user) do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  defp signed_in_path(_conn), do: ~p"/"

  defp maybe_force_full_page_redirect(conn) do
    if get_req_header(conn, "x-inertia") == ["true"] do
      Inertia.Controller.force_inertia_redirect(conn)
    else
      conn
    end
  end

  @doc """
  Plug for routes that require the user to be authenticated.
  """
  def require_authenticated_user(conn, _opts) do
    if authenticated?(conn.assigns.current_user) do
      conn
    else
      conn
      |> maybe_store_return_to()
      |> put_auth_prompt(
        kind: :warning,
        message: "You must log in to access this page.",
        reauthenticate: false
      )
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  @doc """
  Plug for routes that require an administrator.
  """
  def require_administrator(%{assigns: %{current_user: %User{role: :admin}}} = conn, _opts),
    do: conn

  def require_administrator(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:forbidden, "Forbidden")
    |> halt()
  end

  @doc false
  def on_mount(:admin, _params, session, socket) do
    user = fetch_session_user(session)
    socket = Phoenix.Component.assign(socket, :current_user, user)

    if administrator?(user) do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/")}
    end
  end

  defp fetch_session_user(%{"user_token" => token}) when is_binary(token) do
    case Accounts.get_user_by_session_token(token) do
      {%User{} = user, _inserted_at} -> user
      nil -> nil
    end
  end

  defp fetch_session_user(_session), do: nil

  defp administrator?(%User{role: :admin}), do: true
  defp administrator?(_user), do: false

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    store_return_to(conn, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp authenticated?(%User{}), do: true
  defp authenticated?(_user), do: false

  defp local_mailbox_available? do
    Application.get_env(:d20, :dev_routes, false) and
      Application.get_env(:d20, D20.Mailer, [])[:adapter] == Swoosh.Adapters.Local
  end
end
