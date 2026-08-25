defmodule D20Web.AdminAuthorizationTest do
  use D20Web.ConnCase, async: true

  alias D20.Accounts
  alias D20Web.Auth

  import D20.AccountsFixtures

  describe "HTTP administrator requirement" do
    test "permits an administrator", %{conn: conn} do
      admin = %{user_fixture() | role: :admin}

      conn = conn |> assign(:current_user, admin) |> Auth.require_administrator([])

      refute conn.halted
    end

    test "forbids an ordinary user", %{conn: conn} do
      conn = conn |> assign(:current_user, user_fixture()) |> Auth.require_administrator([])

      assert conn.halted
      assert conn.status == 403
      assert conn.resp_body == "Forbidden"
    end

    test "forbids a missing current user", %{conn: conn} do
      conn = Auth.require_administrator(conn, [])

      assert conn.halted
      assert conn.status == 403
    end
  end

  describe "LiveView administrator requirement" do
    test "re-resolves and permits a persisted administrator" do
      admin = set_role(user_fixture(), :admin)
      token = Accounts.generate_user_session_token(admin)

      assert {:cont, socket} = Auth.on_mount(:admin, %{}, %{"user_token" => token}, live_socket())

      assert socket.assigns.current_user.id == admin.id
      assert socket.assigns.current_user.role == :admin
    end

    test "re-resolves a revoked role and denies the mount" do
      admin = set_role(user_fixture(), :admin)
      token = Accounts.generate_user_session_token(admin)
      set_role(admin, :user)

      assert {:halt, %Phoenix.LiveView.Socket{redirected: {:redirect, %{to: "/"}}} = socket} =
               Auth.on_mount(:admin, %{}, %{"user_token" => token}, live_socket())

      assert socket.assigns.current_user.role == :user
    end

    test "denies a mount without an authenticated session" do
      assert {:halt, %Phoenix.LiveView.Socket{redirected: {:redirect, %{to: "/"}}}} =
               Auth.on_mount(:admin, %{}, %{}, live_socket())
    end
  end

  defp set_role(user, role) do
    user
    |> Ecto.Changeset.change(role: role)
    |> D20.Repo.update!()
  end

  defp live_socket do
    %Phoenix.LiveView.Socket{endpoint: D20Web.Endpoint, assigns: %{__changed__: %{}, flash: %{}}}
  end
end
