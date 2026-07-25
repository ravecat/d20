defmodule D20Web.UserSocket do
  use Phoenix.Socket

  alias D20.Accounts.Scope

  channel "session:*", D20Web.SessionChannel
  channel "workspace", D20Web.WorkspaceChannel

  @impl true
  def connect(_params, socket, %{auth_token: token, uri: %URI{} = uri}) when is_binary(token) do
    case D20.Actors.Token.verify(socket, token) do
      {:ok, actor} ->
        socket = socket |> assign(:scope, Scope.for_actor(actor)) |> assign(:request_uri, uri)

        {:ok, socket}

      _ ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket) do
    actor = socket.assigns.scope.actor

    "user_socket:#{actor.type}:#{actor.id}"
  end
end
