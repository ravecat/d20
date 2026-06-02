defmodule D20Web.ModuleSocket do
  use Phoenix.Socket

  alias D20.Accounts.Scope
  alias D20.Module.Token
  alias D20Web.SessionChannel

  channel "session:*", SessionChannel

  @impl true
  @spec connect(map(), Phoenix.Socket.t(), map()) ::
          {:ok, Phoenix.Socket.t()} | {:error, term()} | :error
  def connect(_params, socket, %{auth_token: token}) when is_binary(token) do
    with {:ok, claims} <- Token.verify(socket, token),
         {:ok, session_id} <- SessionChannel.session_id(claims.topic) do
      scope =
        claims.actor
        |> Scope.for_actor()
        |> Scope.put_session(session_id)
        |> Scope.put_game(claims.slug)

      {:ok, assign(socket, :current_scope, scope)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  @spec id(Phoenix.Socket.t()) :: String.t()
  def id(%{assigns: %{current_scope: %{actor: actor, session: session, game: game}}}) do
    "module_socket:#{game.slug}:#{session.id}:#{actor.id}"
  end
end
