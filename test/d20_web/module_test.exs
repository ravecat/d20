defmodule D20Web.ModuleTest do
  use D20Web.ConnCase, async: true

  alias D20Web.Module

  test "requires a session id", %{conn: conn} do
    conn = assign(conn, :current_actor, %{id: Ecto.UUID.generate(), type: :anonymous})
    module = %{id: "qwinto"}

    assert_raise KeyError, fn ->
      Module.bootstrap(conn, module)
    end
  end

  test "builds scoped module token for a game session", %{conn: conn} do
    actor_id = Ecto.UUID.generate()
    session_id = Ecto.UUID.generate()

    conn = assign(conn, :current_actor, %{id: actor_id, type: :anonymous})
    module = %{id: "qwinto"}

    assert %{topic: "session:" <> ^session_id, token: token} =
             Module.bootstrap(conn, module, session_id: session_id)

    assert {:ok,
            %{
              actor_id: ^actor_id,
              actor_type: :anonymous,
              module_id: "qwinto",
              session_id: ^session_id
            }} = D20.Module.Token.verify(D20Web.Endpoint, token)
  end
end
