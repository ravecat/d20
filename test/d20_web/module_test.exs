defmodule D20Web.ModuleTest do
  use D20Web.ConnCase, async: false

  import Phoenix.ChannelTest, only: [socket: 3]

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20Web.Module
  alias D20Web.UserSocket

  setup do
    original_config = Application.fetch_env!(:d20, Module)

    on_exit(fn -> Application.put_env(:d20, Module, original_config) end)
  end

  test "builds an iframe entry with the configured sandbox policy", %{conn: conn} do
    Application.put_env(:d20, Module, sandbox: ["allow-scripts"])

    registry_entry = %D20.Games.Registry.Entry{
      slug: "qwinto",
      engine: D20.Qwinto.Game,
      bgg_id: 183_006
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
    Application.put_env(:d20, Module, sandbox: ["allow-forms"])

    actor = %Actor{id: "p1", type: :anonymous}
    uri = URI.parse("wss://shell.example.com/socket/websocket?vsn=2.0.0")
    session_id = Ecto.UUID.generate()
    topic = "session:#{session_id}"

    socket = socket UserSocket, "socket-id", %{scope: Scope.for_actor(actor), request_uri: uri}

    registry_entry = %D20.Games.Registry.Entry{
      slug: "koala-rescue-club",
      engine: D20.KoalaRescueClub.Game,
      bgg_id: 425_873
    }

    assert %{
             embed_url: "https://koala-rescue-club.shell.example.com/",
             allowed_origins: ["https://koala-rescue-club.shell.example.com"],
             sandbox: ["allow-forms"]
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

  test "rejects missing and malformed sandbox configuration", %{conn: conn} do
    registry_entry = %D20.Games.Registry.Entry{
      slug: "qwinto",
      engine: D20.Qwinto.Game,
      bgg_id: 183_006
    }

    invalid_configs = [nil, [], [sandbox: []], [sandbox: "allow-scripts"], [sandbox: [:scripts]]]

    for config <- invalid_configs do
      if config do
        Application.put_env(:d20, Module, config)
      else
        Application.delete_env(:d20, Module)
      end

      assert_raise ArgumentError,
                   ~r/D20Web.Module :sandbox configuration to be a non-empty list of strings/,
                   fn -> Module.entry(conn, registry_entry) end
    end
  end
end
