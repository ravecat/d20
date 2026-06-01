defmodule D20Web.ModuleSocket do
  use Phoenix.Socket

  alias D20.Module.Token

  channel "session:*", D20Web.SessionChannel

  @impl true
  @spec connect(map(), Phoenix.Socket.t(), map()) :: {:ok, Phoenix.Socket.t()} | :error
  def connect(_params, socket, %{auth_token: token}) when is_binary(token) do
    case Token.verify(socket, token) do
      {:ok, claims} ->
        socket = socket |> assign(:module, claims) |> assign(:actor, claims.actor)

        {:ok, socket}

      _ ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  @spec id(Phoenix.Socket.t()) :: String.t()
  def id(%{assigns: %{module: %{actor: actor, slug: slug, topic: topic}}}) do
    "module_socket:#{slug}:#{topic}:#{actor.id}"
  end
end
