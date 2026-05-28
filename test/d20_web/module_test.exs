defmodule D20Web.ModuleTest do
  use D20Web.ConnCase, async: true

  alias D20.Accounts.Anonymous
  alias D20.Accounts.Scope
  alias D20Web.Module

  test "requires a session id", %{conn: conn} do
    conn =
      assign(
        conn,
        :current_scope,
        Scope.for_user(nil)
        |> Scope.put_anonymous(Anonymous.new())
      )

    module = %{slug: "qwinto"}

    assert_raise KeyError, fn ->
      Module.bootstrap(conn, module)
    end
  end

  test "builds scoped module token for a game session", %{conn: conn} do
    actor_id = Ecto.UUID.generate()
    session_id = Ecto.UUID.generate()

    conn =
      assign(
        conn,
        :current_scope,
        Scope.for_user(nil)
        |> Scope.put_anonymous(Anonymous.from_id(actor_id))
      )

    module = %{slug: "qwinto"}

    assert %{
             endpoint: "ws://www.example.com/module",
             topic: "session:" <> ^session_id,
             token: token
           } =
             bootstrap =
             Module.bootstrap(conn, module, session_id: session_id)

    refute Map.has_key?(bootstrap, :module_id)
    refute Map.has_key?(bootstrap, :socket_url)

    assert {:ok,
            %{
              actor_id: ^actor_id,
              actor_type: :anonymous,
              module_id: "qwinto",
              session_id: ^session_id
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end
end
