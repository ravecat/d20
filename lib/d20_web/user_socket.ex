defmodule D20Web.UserSocket do
  use Phoenix.Socket

  alias D20.Accounts.Scope

  channel "cursors", D20Web.CursorsChannel
  channel "session:*", D20Web.SessionChannel

  @impl true
  def connect(_params, socket, %{auth_token: token}) when is_binary(token) do
    case D20.Actors.Token.verify(socket, token) do
      {:ok, actor} -> {:ok, assign(socket, :current_scope, Scope.for_actor(actor))}
      _ -> :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket) do
    actor = socket.assigns.current_scope.actor

    "user_socket:#{actor.type}:#{actor.id}"
  end
end
