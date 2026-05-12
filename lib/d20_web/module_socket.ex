defmodule D20Web.ModuleSocket do
  use Phoenix.Socket

  alias D20.Module.Token

  @impl true
  @spec connect(map(), Phoenix.Socket.t(), map()) :: {:ok, Phoenix.Socket.t()} | :error
  def connect(_params, socket, %{auth_token: token}) when is_binary(token) do
    case Token.verify(socket, token) do
      {:ok, claims} ->
        {:ok, assign(socket, :module_claims, claims)}

      _ ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  @spec id(Phoenix.Socket.t()) :: String.t()
  def id(socket) do
    claims = socket.assigns.module_claims
    "module_socket:#{claims.module_id}:#{claims.session_id}:#{claims.actor_id}"
  end
end
