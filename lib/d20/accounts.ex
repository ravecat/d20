defmodule D20.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias D20.Repo
  alias Ecto.Multi

  alias D20.Accounts.Anonymous
  alias D20.Accounts.User
  alias D20.Accounts.UserIdentity
  alias D20.Accounts.UserNotifier
  alias D20.Accounts.UserToken

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by username or email and password.

  ## Examples

      iex> get_user_by_identifier_and_password("player", "correct_password")
      %User{}

      iex> get_user_by_identifier_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_identifier_and_password(identifier, password) do
    user =
      Repo.one(
        from user in User, where: user.email == ^identifier or user.username == ^identifier
      )

    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by id.
  """
  @spec get_user(term()) :: User.t() | nil
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by an exact external provider identity.

  Returns `nil` when the identity has not been linked.
  """
  @spec get_user_by_identity(UserIdentity.provider(), String.t()) :: User.t() | nil
  def get_user_by_identity(provider, provider_uid) do
    Repo.one(
      from identity in UserIdentity,
        join: user in assoc(identity, :user),
        where: identity.provider == ^provider and identity.provider_uid == ^provider_uid,
        select: user
    )
  end

  @doc """
  Links an external provider identity to an existing user.

  The provider UID is treated as an opaque, case-sensitive identifier. Provider
  credentials and profile claims are intentionally not accepted by this API.
  """
  @spec link_user_identity(User.t(), UserIdentity.provider(), String.t()) ::
          {:ok, UserIdentity.t()} | {:error, Ecto.Changeset.t()}
  def link_user_identity(%User{} = user, provider, provider_uid) do
    %UserIdentity{user_id: user.id}
    |> UserIdentity.changeset(%{provider: provider, provider_uid: provider_uid})
    |> Repo.insert()
  end

  @doc """
  Lists the external identities owned by a user.
  """
  @spec list_user_identities(User.t()) :: [UserIdentity.t()]
  def list_user_identities(%User{id: user_id}) do
    Repo.all(
      from identity in UserIdentity,
        where: identity.user_id == ^user_id,
        order_by: [asc: identity.provider, asc: identity.id]
    )
  end

  @type profile :: %{
          required(:id) => String.t(),
          required(:display_name) => String.t(),
          required(:avatar) => String.t() | nil
        }

  @doc """
  Gets public user or anonymous profile data by actor id.

  Registered users are resolved from the database first. Unknown user ids fall
  back to deterministic anonymous profile data.
  """
  @spec get_user_or_anonymous(String.t()) :: profile()
  def get_user_or_anonymous(id) when is_binary(id) do
    # Actor ids are mixed user/anonymous strings; Repo.get/2 would cast every id
    # as a `user` TypeID and reject anonymous ids before the fallback can run.
    user = Repo.one(from user in User, where: fragment("? = ?", user.id, type(^id, :string)))

    case user do
      %User{} = user -> user_profile(user)
      nil -> anonymous_profile(id)
    end
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Atomically registers a completed user and links one external identity.

  The caller supplies only normalized identity fields. A provider-verified email
  is optional and is stored only when it is not already owned. Provider payloads
  and credentials are not accepted by this context boundary.
  """
  @spec register_user_with_identity(map(), UserIdentity.provider(), String.t()) ::
          {:ok, User.t()}
          | {:error, :user | :identity, Ecto.Changeset.t()}
  def register_user_with_identity(attrs, provider, provider_uid) when is_map(attrs) do
    email = provider_email(attrs)

    attrs =
      if is_binary(email) and get_user_by_email(email),
        do: put_provider_email(attrs, nil),
        else: attrs

    case transact_user_with_identity(attrs, provider, provider_uid) do
      {:error, :user, %Ecto.Changeset{} = changeset} = error ->
        if is_binary(email) and email_constraint_error?(changeset) do
          attrs |> put_provider_email(nil) |> transact_user_with_identity(provider, provider_uid)
        else
          error
        end

      result ->
        result
    end
  end

  defp transact_user_with_identity(%Ecto.Changeset{} = user_changeset, provider, provider_uid) do
    Multi.new()
    |> Multi.insert(:user, user_changeset)
    |> Multi.insert(:identity, fn %{user: user} ->
      UserIdentity.changeset(%UserIdentity{user_id: user.id}, %{
        provider: provider,
        provider_uid: provider_uid
      })
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{user: user}} ->
        {:ok, user}

      {:error, operation, %Ecto.Changeset{} = changeset, _changes} ->
        {:error, operation, changeset}
    end
  end

  defp transact_user_with_identity(attrs, provider, provider_uid) when is_map(attrs) do
    attrs
    |> then(&User.provider_registration_changeset(%User{}, &1))
    |> transact_user_with_identity(provider, provider_uid)
  end

  defp provider_email(attrs), do: Map.get(attrs, :email, Map.get(attrs, "email"))

  defp put_provider_email(attrs, email) do
    if Enum.all?(Map.keys(attrs), &is_binary/1) do
      Map.put(attrs, "email", email)
    else
      Map.put(attrs, :email, email)
    end
  end

  defp email_constraint_error?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:email, {_message, metadata}} ->
        metadata[:constraint] == :unique and
          metadata[:constraint_name] in ["users_email_index", :users_email_index]

      _error ->
        false
    end)
  end

  @doc """
  Registers a passwordless user and delivers their confirmation magic link.

  A delivery failure does not remove the user or token because a provider may
  have accepted the message before returning an ambiguous transport error.
  """
  def register_user_with_magic_link(attrs, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    with {:ok, user} <- register_user(attrs) do
      case deliver_login_instructions(user, magic_link_url_fun) do
        {:ok, _email} -> {:ok, user}
        {:error, _reason} -> {:error, :delivery_failed}
      end
    end
  end

  defp user_profile(%User{username: username} = user) when is_binary(username) do
    %{id: to_string(user.id), display_name: username, avatar: nil}
  end

  defp user_profile(%Anonymous{} = anonymous) do
    %{id: anonymous.id, display_name: anonymous.display_name, avatar: anonymous.avatar}
  end

  defp anonymous_profile(id) do
    id
    |> to_string()
    |> Anonymous.from_id()
    |> user_profile()
  end

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.add(DateTime.utc_now(), minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `D20.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = email_change_context(user.email)

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from UserToken, where: [user_id: ^user.id, context: ^context]) do
        {:ok, user}
      else
        {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
        _error -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `D20.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token, attrs \\ %{}) do
    case UserToken.verify_magic_link_token_query(token) do
      {:ok, query} ->
        Repo.transact(fn ->
          query |> lock("FOR UPDATE") |> Repo.one() |> complete_magic_link_auth(attrs)
        end)

      :error ->
        {:error, :not_found}
    end
  end

  defp complete_magic_link_auth({%User{confirmed_at: nil, hashed_password: hash}, _token}, _attrs)
       when not is_nil(hash) do
    raise """
    magic link log in is not allowed for unconfirmed users with a password set!

    This cannot happen with the default implementation, which indicates that you
    might have adapted the code to a different use case. Please make sure to read the
    "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
    """
  end

  defp complete_magic_link_auth({%User{confirmed_at: nil} = user, _token}, attrs) do
    user
    |> User.registration_completion_changeset(attrs)
    |> update_user_and_delete_all_tokens_in_transaction()
  end

  defp complete_magic_link_auth({%User{} = user, token}, _attrs) do
    with {:ok, _token} <- Repo.delete(token) do
      {:ok, {user, []}}
    end
  end

  defp complete_magic_link_auth(nil, _attrs), do: {:error, :not_found}

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(
        %User{email: email} = user,
        current_email,
        update_email_url_fun
      )
      when is_binary(email) and is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} =
      UserToken.build_email_token(user, email_change_context(current_email))

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def deliver_user_update_email_instructions(%User{}, _current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1),
      do: {:error, :email_not_available}

  @doc """
  Delivers the magic link login instructions to a user with verified email.
  """
  def deliver_login_instructions(%User{email: email} = user, magic_link_url_fun)
      when is_binary(email) and is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  def deliver_login_instructions(%User{}, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1),
      do: {:error, :email_not_available}

  defp email_change_context(nil), do: "change:none"
  defp email_change_context(email) when is_binary(email), do: "change:#{email}"

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from UserToken, where: [token: ^token, context: "session"])
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn -> update_user_and_delete_all_tokens_in_transaction(changeset) end)
  end

  defp update_user_and_delete_all_tokens_in_transaction(changeset) do
    with {:ok, user} <- Repo.update(changeset) do
      tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

      Repo.delete_all(
        from token in UserToken, where: token.id in ^Enum.map(tokens_to_expire, & &1.id)
      )

      {:ok, {user, tokens_to_expire}}
    end
  end
end
