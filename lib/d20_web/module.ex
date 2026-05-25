defmodule D20Web.Module do
  @moduledoc """
  Builds runtime data for iframe modules.
  """

  alias D20.Actors.Actor
  alias D20.Module.Manifest
  alias D20Web.SessionChannel

  @socket_path "/module"

  @type bootstrap :: %{
          required(:topic) => String.t(),
          required(:endpoint) => String.t(),
          required(:token) => String.t()
        }

  @type bootstrap_opts :: [session_id: String.t()]

  @spec bootstrap(Plug.Conn.t(), Manifest.module_entry(), bootstrap_opts()) :: bootstrap()
  def bootstrap(conn, module, opts \\ []) do
    session_id = Keyword.fetch!(opts, :session_id)
    actor = conn.assigns.current_scope.actor

    %{
      topic: SessionChannel.topic(session_id),
      endpoint: module_endpoint(conn),
      token: module_token(module, session_id, actor)
    }
  end

  @spec module_endpoint(Plug.Conn.t()) :: String.t()
  defp module_endpoint(conn) do
    conn
    |> Plug.Conn.request_url()
    |> URI.parse()
    |> Map.put(:scheme, socket_scheme(conn))
    |> Map.put(:path, @socket_path)
    |> Map.put(:query, nil)
    |> URI.to_string()
  end

  @spec socket_scheme(Plug.Conn.t()) :: String.t()
  defp socket_scheme(%{scheme: :https}), do: "wss"
  defp socket_scheme(_conn), do: "ws"

  @spec module_token(Manifest.module_entry(), String.t(), Actor.t()) :: String.t()
  defp module_token(module, session_id, actor) do
    D20.Module.Token.sign(D20Web.Endpoint, %{
      actor_id: actor.id,
      actor_type: actor.type,
      module_id: module.id,
      session_id: session_id
    })
  end
end
