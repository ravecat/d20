defmodule D20Web.ModuleTest do
  use D20Web.ConnCase, async: true

  import Phoenix.ChannelTest, only: [socket: 3]

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20Web.Module
  alias D20Web.UserSocket

  test "builds an iframe entry from the request host", %{conn: conn} do
    registry_entry = %D20.Games.Registry.Entry{
      slug: "qwinto",
      engine: D20.Qwinto.Game,
      bgg_id: 183_006,
      sandbox: ["allow-scripts"]
    }

    assert %{
             embed_url: "http://qwinto.example.com/",
             allowed_origins: ["http://qwinto.example.com"],
             sandbox: ["allow-scripts"]
           } = entry = Module.entry(conn, registry_entry)

    refute Map.has_key?(entry, :bootstrap)
    refute Map.has_key?(entry, :connection)
  end

  test "builds a module socket connection from the request and current actor", %{conn: conn} do
    actor = %Actor{id: "p1", type: :anonymous}
    session_id = Ecto.UUID.generate()
    topic = "session:#{session_id}"
    conn = assign(conn, :scope, %Scope{actor: actor})
    connection = Module.connection(conn, "qwinto", session_id)

    assert %{endpoint: "ws://example.com/module", topic: ^topic, token: token} = connection

    refute Map.has_key?(connection, :slug)
    refute Map.has_key?(connection, :actor)

    assert {:ok,
            %{
              endpoint: "ws://example.com/module",
              slug: "qwinto",
              topic: ^topic,
              actor: %Actor{id: "p1", type: :anonymous}
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end

  test "builds equivalent module data from an authenticated user socket" do
    actor = %Actor{id: "p1", type: :anonymous}
    uri = URI.parse("wss://shell.example.com/socket/websocket?vsn=2.0.0")
    session_id = Ecto.UUID.generate()
    topic = "session:#{session_id}"

    socket = socket UserSocket, "socket-id", %{scope: Scope.for_actor(actor), request_uri: uri}

    registry_entry = %D20.Games.Registry.Entry{
      slug: "qwinto",
      engine: D20.Qwinto.Game,
      bgg_id: 183_006,
      sandbox: ["allow-scripts"]
    }

    assert %{
             embed_url: "https://qwinto.shell.example.com/",
             allowed_origins: ["https://qwinto.shell.example.com"],
             sandbox: ["allow-scripts"]
           } = Module.entry(socket, registry_entry)

    assert %{endpoint: "wss://shell.example.com/module", topic: ^topic, token: token} =
             Module.connection(socket, "qwinto", session_id)

    assert {:ok,
            %{
              endpoint: "wss://shell.example.com/module",
              slug: "qwinto",
              topic: ^topic,
              actor: ^actor
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end
end
