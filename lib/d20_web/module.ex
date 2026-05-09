defmodule D20Web.Module do
  @moduledoc """
  Builds runtime data for iframe modules.
  """

  alias D20Web.SessionChannel

  @socket_path "/module"

  def bootstrap(conn, module, opts \\ []) do
    session_id = Keyword.fetch!(opts, :session_id)

    %{
      module_id: module.id,
      topic: SessionChannel.topic(session_id),
      socket_url: module_socket_url(conn),
      token: module_token(conn, module, session_id)
    }
  end

  defp module_socket_url(conn) do
    conn
    |> Plug.Conn.request_url()
    |> URI.parse()
    |> Map.put(:scheme, socket_scheme(conn))
    |> Map.put(:path, @socket_path)
    |> Map.put(:query, nil)
    |> URI.to_string()
  end

  defp socket_scheme(%{scheme: :https}), do: "wss"
  defp socket_scheme(_conn), do: "ws"

  defp module_token(conn, module, session_id) do
    actor = conn.assigns.current_scope.actor

    D20.Module.Token.sign(D20Web.Endpoint, %{
      actor_id: actor.id,
      actor_type: actor.type,
      module_id: module.id,
      session_id: session_id
    })
  end
end
