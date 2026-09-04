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

  test "builds an iframe entry from the persisted game slug", %{conn: conn} do
    Application.put_env(:d20, Module, sandbox: ["allow-scripts"])
    game = game_fixture(183_006)
    embed_url = "http://qwinto.example.com/"
    origin = "http://qwinto.example.com"

    assert %{embed_url: ^embed_url, allowed_origins: [^origin], sandbox: ["allow-scripts"]} =
             entry = Module.entry(conn, game)

    refute Map.has_key?(entry, :bootstrap)
    refute Map.has_key?(entry, :connection)
  end

  test "builds a module socket connection from the request and current actor", %{conn: conn} do
    actor = %Actor{id: "p1", type: :anonymous}
    session_id = Ecto.UUID.generate()
    topic = "session:#{session_id}"
    conn = assign(conn, :scope, %Scope{actor: actor})
    game_id = game_id(183_006)
    connection = Module.connection(conn, game_id, session_id)

    assert %{endpoint: "ws://example.com/module", topic: ^topic, token: token} = connection

    refute Map.has_key?(connection, :slug)
    refute Map.has_key?(connection, :actor)
    refute Map.has_key?(connection, :game_id)

    assert {:ok,
            %{
              endpoint: "ws://example.com/module",
              game_id: ^game_id,
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
    koala = game_fixture(425_873)
    qwinto_id = game_id(183_006)
    embed_url = "https://koala-rescue-club.shell.example.com/"
    origin = "https://koala-rescue-club.shell.example.com"

    assert %{embed_url: ^embed_url, allowed_origins: [^origin], sandbox: ["allow-forms"]} =
             Module.entry(socket, koala)

    assert %{endpoint: "wss://shell.example.com/module", topic: ^topic, token: token} =
             Module.connection(socket, qwinto_id, session_id)

    assert {:ok,
            %{
              endpoint: "wss://shell.example.com/module",
              game_id: ^qwinto_id,
              topic: ^topic,
              actor: ^actor
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end

  test "rejects missing and malformed sandbox configuration", %{conn: conn} do
    invalid_configs = [nil, [], [sandbox: []], [sandbox: "allow-scripts"], [sandbox: [:scripts]]]

    for config <- invalid_configs do
      if config do
        Application.put_env(:d20, Module, config)
      else
        Application.delete_env(:d20, Module)
      end

      assert_raise ArgumentError,
                   ~r/D20Web.Module :sandbox configuration to be a non-empty list of strings/,
                   fn -> Module.entry(conn, game_fixture(183_006)) end
    end
  end
end
