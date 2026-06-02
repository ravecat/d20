defmodule D20Web.ModuleTest do
  use D20Web.ConnCase, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20Web.Module

  test "builds an iframe entry from the request host", %{conn: conn} do
    manifest = %{slug: "qwinto", sandbox: ["allow-scripts"]}

    assert %{
             embed_url: "http://qwinto.example.com/",
             allowed_origins: ["http://qwinto.example.com"],
             sandbox: ["allow-scripts"]
           } = entry = Module.entry(conn, manifest)

    refute Map.has_key?(entry, :bootstrap)
    refute Map.has_key?(entry, :connection)
  end

  test "builds a module socket connection from the request and current actor", %{conn: conn} do
    actor = %Actor{id: "p1", type: :anonymous}
    session_id = Ecto.UUID.generate()
    topic = "session:#{session_id}"
    conn = assign(conn, :current_scope, %Scope{actor: actor})
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
end
