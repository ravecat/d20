defmodule D20Web.GameInterestControllerTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures
  alias D20.Games
  alias D20.Games.Game
  alias D20.Games.Interests
  alias D20.Games.Sources.BoardGameGeek
  alias D20.Repo

  setup do
    original = Application.get_env(:d20, BoardGameGeek)
    stages = Application.fetch_env!(:d20, :visible_game_stages)
    req_options = Req.default_options()
    Application.put_env(:d20, BoardGameGeek, api_key: "test-key")
    Application.put_env(:d20, :visible_game_stages, [:released, :in_development])
    Req.default_options(plug: {Req.Test, __MODULE__})

    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.text(
        conn,
        ~s(<items><item id="#{String.to_integer(conn.params["id"])}" type="boardgame"><name type="primary" value="Game" /></item></items>)
      )
    end)

    on_exit(fn ->
      Application.put_env(:d20, BoardGameGeek, original)
      Application.put_env(:d20, :visible_game_stages, stages)
      Req.default_options(req_options)
    end)

    :ok
  end

  test "guest submission requires authentication without retaining a POST replay", %{conn: conn} do
    response = post(conn, ~p"/games/900001/interest")
    assert redirected_to(response) == "/"
    assert get_session(response, :user_return_to) == nil
    assert Interests.counts() == []
  end

  test "guest details expose current per-game demand shared by local and provider routes", %{
    conn: conn
  } do
    user = provider_user_fixture()
    other = provider_user_fixture()

    assert inertia_props(get(conn, ~p"/games/voyages")).interest == %{
             action: "/games/voyages/interest",
             requested: false,
             count: 0
           }

    assert :ok = Interests.request(user, "voyages")
    assert :ok = Interests.request(other, "350736")
    assert :ok = Interests.request(user, "350736")
    assert :ok = Interests.request(user, "900001")

    for slug <- ["voyages", "350736"] do
      assert inertia_props(get(conn, ~p"/games/#{slug}")).interest == %{
               action: "/games/#{slug}/interest",
               requested: false,
               count: 2
             }
    end

    assert inertia_props(get(conn, ~p"/games/900001")).interest.count == 1
    Repo.delete!(user)
    assert inertia_props(get(conn, ~p"/games/voyages")).interest.count == 1
    assert inertia_props(get(conn, ~p"/games/900001")).interest.count == 0
  end

  describe "authenticated requests" do
    setup %{conn: conn} do
      user = provider_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "provider-only request is idempotent, persists after reload, and ignores forged account",
         %{conn: conn, user: user} do
      other = provider_user_fixture()
      count = Repo.aggregate(Game, :count)
      response = post conn, ~p"/games/900001/interest", %{user_id: other.id}
      assert redirected_to(response, 303) == "/games/900001"
      assert Interests.requested?(user, 900_001)
      refute Interests.requested?(other, 900_001)
      repeat = post(conn, ~p"/games/900001/interest")
      assert redirected_to(repeat, 303) == "/games/900001"
      page = get(conn, ~p"/games/900001")

      assert %{
               id: nil,
               playable: false,
               interest: %{requested: true, action: "/games/900001/interest", count: 1}
             } = inertia_props(page)

      assert inertia_props(page).interest == %{
               requested: true,
               action: "/games/900001/interest",
               count: 1
             }

      refute Map.has_key?(inertia_props(page), :canLaunchGame)
      assert Interests.counts() == [%{bgg_id: 900_001, count: 1}]
      assert Repo.aggregate(Game, :count) == count
    end

    test "original numeric route avoids a normalized local-slug collision", %{
      conn: conn,
      user: user
    } do
      Repo.insert!(%Game{slug: "900001", bgg_id: 900_002, stage: :in_development})
      page = get(conn, ~p"/games/00900001")

      assert %{slug: "900001", interest: %{action: "/games/00900001/interest"}} =
               inertia_props(page)

      response = post(conn, ~p"/games/00900001/interest")
      assert redirected_to(response, 303) == "/games/00900001"
      assert Interests.requested?(user, 900_001)
      refute Interests.requested?(user, 900_002)
    end

    test "local and provider routes share counts even during local metadata fallback", %{
      conn: conn,
      user: user
    } do
      Req.Test.stub(__MODULE__, &Req.Test.text(&1, "<items />"))
      response = post conn, ~p"/games/voyages/interest", %{bgg_id: 350_736}
      assert redirected_to(response, 303) == "/games/voyages"
      assert Interests.requested?(user, 350_736)
      Req.Test.stub(__MODULE__, &Req.Test.text(&1, ~s(<items><item id="350736" /></items>)))
      response = post conn, ~p"/games/350736/interest", %{bgg_id: 350_736}
      assert redirected_to(response, 303) == "/games/350736"
      assert Interests.counts() == [%{bgg_id: 350_736, count: 1}]
    end

    test "submission needs no payload and ignores supplied BGG identities", %{
      conn: conn,
      user: user
    } do
      response = post(conn, ~p"/games/900001/interest")
      assert redirected_to(response, 303) == "/games/900001"

      for supplied <- [nil, "bad", 0, 900_002] do
        response = post conn, ~p"/games/900001/interest", %{bgg_id: supplied}
        assert redirected_to(response, 303) == "/games/900001"
      end

      assert Interests.requested?(user, 900_001)
      refute Interests.requested?(user, 900_002)
      assert Interests.counts() == [%{bgg_id: 900_001, count: 1}]
    end

    test "submission uses the current local BGG binding after render", %{conn: conn, user: user} do
      page = get(conn, ~p"/games/voyages")

      assert inertia_props(page).interest == %{
               action: "/games/voyages/interest",
               requested: false,
               count: 0
             }

      {:ok, _game} = Games.update(game_fixture(350_736), %{bgg_id: 900_002})
      response = post conn, ~p"/games/voyages/interest", %{bgg_id: 350_736}
      assert redirected_to(response, 303) == "/games/voyages"
      assert Interests.requested?(user, 900_002)
      refute Interests.requested?(user, 350_736)
    end

    test "persistence errors stay in their Inertia error bag", %{conn: conn, user: user} do
      Req.Test.stub(__MODULE__, fn conn ->
        Repo.delete!(user)
        Req.Test.text(conn, ~s(<items><item id="900001" /></items>))
      end)

      response =
        conn
        |> put_req_header("x-inertia-error-bag", "interest")
        |> post(~p"/games/900001/interest")

      assert redirected_to(response, 303) == "/games/900001"

      assert inertia_errors(response) == %{
               "interest" => %{message: "Could not save your request. Please try again."}
             }

      assert Interests.counts() == []
    end

    test "authenticated writes retain CSRF protection", %{conn: conn} do
      assert_error_sent 403, fn ->
        conn |> put_private(:plug_skip_csrf_protection, false) |> post(~p"/games/900001/interest")
      end

      assert Interests.counts() == []
    end

    test "playable submissions silently redirect and disabled engines still accept interest", %{
      conn: conn
    } do
      response = post(conn, ~p"/games/qwinto/interest")
      assert redirected_to(response, 303) == "/games/qwinto"
      assert inertia_errors(response) == %{}
      assert Interests.counts() == []
      {:ok, _game} = Games.update(game_fixture(183_006), %{enabled: false})
      response = post(conn, ~p"/games/qwinto/interest")
      assert redirected_to(response, 303) == "/games/qwinto"
      assert Interests.counts() == [%{bgg_id: 183_006, count: 1}]
    end

    test "hidden local details cannot use a Session parameter to bypass visibility", %{conn: conn} do
      Application.put_env(:d20, :visible_game_stages, [])

      assert conn
             |> post(~p"/games/voyages/interest", %{session: "anything"})
             |> html_response(404) == "Not Found"

      assert Interests.counts() == []
    end

    test "provider failures are not counted", %{conn: conn} do
      Req.Test.stub(__MODULE__, fn conn -> Plug.Conn.send_resp(conn, 503, "Unavailable") end)

      assert conn |> post(~p"/games/900001/interest") |> html_response(404) == "Not Found"

      assert Interests.counts() == []
    end
  end
end
