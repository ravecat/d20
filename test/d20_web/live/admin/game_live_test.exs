defmodule D20Web.Admin.GameLiveTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures
  import Phoenix.LiveViewTest

  alias D20.Accounts.User
  alias D20.Games.Game
  alias D20Web.Admin.GameLive

  setup %{conn: conn} do
    user = user_fixture()
    admin = set_role(user_fixture(), :admin)

    %{
      admin: admin,
      admin_conn: log_in_user(conn, admin),
      game: game_fixture(183_006),
      user: user,
      user_conn: log_in_user(conn, user)
    }
  end

  describe "authorization" do
    test "redirects an anonymous request through the existing login flow", %{conn: conn} do
      conn = get(conn, ~p"/dashboard")

      assert conn.halted
      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, :auth_prompt).message == "You must log in to access this page."
    end

    test "forbids an ordinary user from the admin area and preferences", %{
      user_conn: conn,
      user: user
    } do
      assert conn |> get(~p"/dashboard") |> response(403) == "Forbidden"

      preference_conn = log_in_user(build_conn(), user)

      assert preference_conn |> post(~p"/dashboard/backpex_preferences", %{}) |> response(403) ==
               "Forbidden"
    end

    test "mounts the game resource directly for an authorized operator", %{admin_conn: conn} do
      assert {:ok, _view, html} = live(conn, ~p"/dashboard")
      assert html =~ "Games"
    end

    test "allows an authorized operator to persist Backpex preferences", %{admin_conn: conn} do
      conn =
        post(conn, ~p"/dashboard/backpex_preferences", %{
          "key" => "global.sidebar_open",
          "value" => false
        })

      assert json_response(conn, 200) == %{"ok" => true}
    end
  end

  describe "game resource" do
    test "lists games in the protected Backpex shell", %{
      admin_conn: conn,
      admin: admin,
      game: game
    } do
      assert {:ok, view, html} = live(conn, ~p"/dashboard")

      assert html =~ "D20 Admin"
      assert html =~ admin.username
      assert html =~ "Games"
      assert html =~ "BGG ID"
      refute html =~ "New Game"
      refute html =~ "Delete"
      rendered = render(view)
      assert rendered =~ "183006"
      assert rendered =~ TypeID.to_string(game.id)
    end

    test "shows one persisted game", %{admin_conn: conn, game: game} do
      assert {:ok, _view, html} = live(conn, ~p"/dashboard/#{game.id}/show")

      assert html =~ "Game"
      assert html =~ "183006"
      assert html =~ "Released"
      assert html =~ "Elixir.D20.Qwinto.Game"
    end

    test "exposes only index, show, and edit actions to the catalog capability", %{
      admin: admin,
      user: user
    } do
      for action <- [:index, :show, :edit] do
        assert GameLive.can?(%{current_user: admin}, action, nil)
        refute GameLive.can?(%{current_user: user}, action, nil)
      end

      refute GameLive.can?(%{current_user: admin}, :new, nil)
      refute GameLive.can?(%{current_user: admin}, :delete, nil)
      refute Keyword.has_key?(GameLive.item_actions(delete: %{module: :delete}), :delete)
    end

    test "builds stage and engine options from schema-owned enums" do
      fields = GameLive.fields()

      assert fields[:stage].options == [
               {"Planned", :planned},
               {"In development", :in_development},
               {"Released", :released}
             ]

      assert fields[:engine].options == Game.engines()
      assert fields[:engine].prompt == "None"
      assert Enum.all?([:bgg_id, :stage, :enabled, :engine], &fields[&1].index_editable)
      assert fields[:id].readonly
      refute fields[:id][:index_editable]
      assert fields[:id].module == Backpex.Fields.Text
    end

    test "persists catalog edits inline from the index table", %{admin_conn: conn, game: game} do
      assert {:ok, view, _html} = live(conn, ~p"/dashboard")

      view
      |> form("#index-form-bgg_id-#{game.id}", %{"index_form" => %{"value" => "999999"}})
      |> render_change()

      assert %Game{bgg_id: 999_999} = D20.Repo.get!(Game, game.id)
    end

    test "persists valid catalog edits", %{admin_conn: conn, game: game} do
      assert {:ok, view, _html} = live(conn, ~p"/dashboard/#{game.id}/edit")

      view
      |> form("#resource-form", %{
        "change" => %{
          "bgg_id" => "999999",
          "stage" => "released",
          "enabled" => "false",
          "engine" => Atom.to_string(D20.KoalaRescueClub.Game)
        }
      })
      |> render_submit(%{"save-type" => "save"})

      assert_redirect view, ~p"/dashboard"

      assert %Game{
               bgg_id: 999_999,
               stage: :released,
               enabled: false,
               engine: D20.KoalaRescueClub.Game
             } = D20.Repo.get!(Game, game.id)
    end

    test "renders changeset errors and preserves the record", %{admin_conn: conn, game: game} do
      original = D20.Repo.get!(Game, game.id)
      assert {:ok, view, _html} = live(conn, ~p"/dashboard/#{game.id}/edit")

      html =
        view
        |> form("#resource-form", %{
          "change" => %{
            "bgg_id" => "0",
            "stage" => "released",
            "enabled" => "true",
            "engine" => ""
          }
        })
        |> render_submit(%{"save-type" => "save"})

      assert html =~ "must be greater than 0"
      assert html =~ "is required"
      assert D20.Repo.get!(Game, game.id) == original
    end

    test "renders unique constraint errors and preserves the record", %{
      admin_conn: conn,
      game: game
    } do
      original = D20.Repo.get!(Game, game.id)
      assert {:ok, view, _html} = live(conn, ~p"/dashboard/#{game.id}/edit")

      html =
        view
        |> form("#resource-form", %{
          "change" => %{
            "bgg_id" => "360471",
            "stage" => "released",
            "enabled" => "true",
            "engine" => Atom.to_string(D20.Qwinto.Game)
          }
        })
        |> render_submit(%{"save-type" => "save"})

      assert html =~ "has already been taken"
      assert D20.Repo.get!(Game, game.id) == original
    end

    test "does not route game creation or deletion", %{admin_conn: conn, game: game} do
      assert conn |> get("/dashboard/games") |> response(404)
      assert conn |> recycle() |> get("/dashboard/new") |> response(404)
      assert conn |> recycle() |> delete("/dashboard/#{game.id}") |> response(404)
    end
  end

  defp set_role(%User{} = user, role) do
    user
    |> Ecto.Changeset.change(role: role)
    |> D20.Repo.update!()
  end
end
