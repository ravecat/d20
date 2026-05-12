defmodule D20Web.UserSocket do
  use Phoenix.Socket

  channel "cursors", D20Web.CursorsChannel
  channel "session:*", D20Web.SessionChannel

  @impl true
  def connect(_params, socket, %{auth_token: token}) when is_binary(token) do
    case D20.Actors.ActorToken.verify(socket, token) do
      {:ok, %{id: actor_id, type: actor_type} = actor}
      when is_binary(actor_id) and actor_type in [:user, :anonymous] ->
        {:ok, assign(socket, :actor, actor)}

      _ ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.actor.type}:#{socket.assigns.actor.id}"
end
