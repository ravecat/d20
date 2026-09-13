defmodule D20Web.GameFavoriteControllerTest do
  use D20Web.ConnCase, async: false

  import D20.AccountsFixtures

  alias D20.Games
  alias D20.Games.Favorite
  alias D20.Games.Favorites
  alias D20.Games.Game
  alias D20.Games.Sources.BoardGameGeek
  alias D20.Repo

  setup context do
    Req.Test.set_req_test_from_context(context)
    Req.Test.verify_on_exit!()
    original_config = Application.get_env(:d20, BoardGameGeek)
    original_options = Req.default_options()
    original_stages = Application.fetch_env!(:d20, :visible_game_stages)
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    Application.put_env(:d20, :visible_game_stages, [:released, :in_development])
    Req.default_options(plug: {Req.Test, __MODULE__})

    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.text(conn, ~s(<items><item type="boardgame" id="183006" /></items>))
    end)

    on_exit(fn ->
      Application.put_env(:d20, BoardGameGeek, original_config)
      Application.put_env(:d20, :visible_game_stages, original_stages)
      Req.default_options(original_options)
    end)

    version = get(context.conn, ~p"/about").private.inertia_version

    %{
      conn:
        context.conn
        |> put_req_header("accept", "text/html")
        |> put_req_header("x-inertia", "true")
        |> put_req_header("x-inertia-version", version)
    }
  end

  test "guests receive Inertia authentication errors on both writes", %{conn: conn} do
    for response <- [
          put(conn, ~p"/favorites/183006", %{slug: "qwinto"}),
          delete(conn, ~p"/favorites/183006")
        ] do
      assert_error(response, :authentication, "Sign in to save favorites.")
    end

    refute Repo.exists?(Favorite)
  end

  test "account writes set membership, ignore client owner and support retries", %{conn: conn} do
    user = provider_user_fixture()
    other = user_fixture()
    conn = log_in_user(conn, user)

    for id <- [183_006, "183006"] do
      response =
        put conn, ~p"/favorites/#{id}", %{slug: "qwinto", user_id: TypeID.to_string(other.id)}

      assert_success(response)
    end

    assert [%Favorite{bgg_id: 183_006}] = Favorites.list(user)
    assert Favorites.list(other) == []
    Repo.insert!(%D20.Games.Favorite{user_id: other.id, bgg_id: 183_006})
    Req.Test.stub(__MODULE__, fn _conn -> flunk("Removal must not consult the provider") end)

    for _ <- 1..2 do
      assert_success(delete(conn, ~p"/favorites/183006"))
    end

    assert [%Favorite{bgg_id: 183_006}] = Favorites.list(other)
  end

  test "the URL identity cannot be overridden by body or query parameters", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    assert_success(
      put conn, ~p"/favorites/183006?bgg_id=900001", %{slug: "qwinto", bgg_id: 900_002}
    )

    assert [%Favorite{bgg_id: 183_006}] = Favorites.list(user)
    Repo.insert!(%D20.Games.Favorite{user_id: user.id, bgg_id: 900_002})
    Req.Test.stub(__MODULE__, fn _request -> flunk("Removal must not resolve a source") end)
    Application.put_env(:d20, :visible_game_stages, [])

    assert_success(
      delete(conn, ~p"/favorites/183006?bgg_id=900001", %{
        bgg_id: 900_002,
        slug: %{},
        session: %{}
      })
    )

    assert [%Favorite{bgg_id: 900_002}] = Favorites.list(user)
  end

  test "the original provider route wins over a conflicting normalized local slug", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    Repo.insert!(%Game{slug: "183006", bgg_id: 900_001, stage: :in_development})

    Req.Test.expect(__MODULE__, fn request ->
      assert request.params["id"] == "00183006"
      Req.Test.text(request, ~s(<items><item type="boardgame" id="183006" /></items>))
    end)

    assert_success(put conn, ~p"/favorites/183006", %{slug: "00183006"})

    assert [%Favorite{bgg_id: 183_006}] = Favorites.list(user)
  end

  test "stale binding rejects the expected identity without saving another game", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())
    {:ok, _game} = Games.update(game_fixture(183_006), %{bgg_id: 900_001})

    assert_error(
      put(conn, ~p"/favorites/183006", %{slug: "qwinto"}),
      :favorite,
      "This game has changed. Refresh the page and try again."
    )

    refute Repo.exists?(Favorite)
  end

  test "hidden games can be saved without session context and ignore stray session fields", %{
    conn: conn
  } do
    user = user_fixture()
    conn = log_in_user(conn, user)
    Application.put_env(:d20, :visible_game_stages, [])

    for params <- [
          %{slug: "qwinto"},
          %{slug: "qwinto", session: "missing"},
          %{slug: "qwinto", session: %{}},
          %{slug: "00183006", session: "missing"}
        ] do
      assert_success(put conn, ~p"/favorites/183006", params)
      assert [%Favorite{bgg_id: 183_006}] = Favorites.list(user)
      assert :ok = Favorites.delete(user, 183_006)
    end
  end

  test "provider failure preserves resolution errors while local metadata fallback permits saving",
       %{conn: conn} do
    conn = log_in_user(conn, user_fixture())
    Req.Test.stub(__MODULE__, fn request -> send_resp(request, 503, "Unavailable") end)

    assert_error(
      put(conn, ~p"/favorites/183006", %{slug: "00183006"}),
      :favorite,
      "Game not found."
    )

    assert_success(put conn, ~p"/favorites/183006", %{slug: "qwinto"})
  end

  test "CSRF is enforced for Inertia cookie-authenticated writes", %{conn: conn} do
    conn = conn |> log_in_user(user_fixture()) |> put_private(:plug_skip_csrf_protection, false)

    for method <- [:put, :delete] do
      assert_raise Plug.CSRFProtection.InvalidCSRFTokenError, fn ->
        case method do
          :put -> put conn, ~p"/favorites/183006", %{slug: "qwinto"}
          :delete -> delete(conn, ~p"/favorites/183006")
        end
      end
    end

    refute Repo.exists?(Favorite)
  end

  test "the current page CSRF cookie authorizes both Inertia mutations", %{conn: conn} do
    page =
      conn
      |> log_in_user(user_fixture())
      |> delete_req_header("x-inertia")
      |> put_req_header("accept", "text/html")
      |> get(~p"/about")

    token = page.resp_cookies["XSRF-TOKEN"].value

    conn =
      page
      |> recycle()
      |> put_private(:plug_skip_csrf_protection, false)
      |> put_req_header("accept", "text/html")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-csrf-token", token)

    assert_success(put conn, ~p"/favorites/183006", Jason.encode!(%{slug: "qwinto"}))

    assert_success(delete(conn, ~p"/favorites/183006"))
  end

  test "storage cancellation follows the standard server error path", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())

    Repo.query!("""
    CREATE FUNCTION pg_temp.reject_favorite() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN RAISE EXCEPTION 'test storage cancellation' USING ERRCODE = '57014'; END $$
    """)

    Repo.query!("""
    CREATE TRIGGER reject_favorite BEFORE INSERT OR DELETE ON game_favorites
    FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_favorite()
    """)

    assert_error_sent 500, fn -> put conn, ~p"/favorites/183006", %{slug: "qwinto"} end

    assert_error_sent 500, fn -> delete(conn, ~p"/favorites/183006") end

    refute Repo.exists?(Favorite)
  end

  test "return targets preserve local routes and reject unsafe destinations", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())

    for path <- ["/", "/games/00183006", "/games/qwinto?session=existing"] do
      response = delete conn, ~p"/favorites/183006", %{response_to: path}
      assert redirected_to(response, 303) == path
    end

    for path <- [
          "https://evil.example",
          "//evil.example",
          "/%2Fevil.example",
          "/bad%0d%0aLocation:evil",
          nil
        ] do
      response = delete conn, ~p"/favorites/183006", %{response_to: path}
      assert redirected_to(response, 303) == "/"
    end
  end

  test "expired authentication redirects a partial detail refresh with errors and no replay", %{
    conn: conn
  } do
    response =
      conn
      |> put_req_header("x-inertia-partial-component", "game")
      |> put_req_header("x-inertia-partial-data", "favorites,auth,errors")
      |> put(~p"/favorites/183006", %{slug: "qwinto", response_to: "/games/qwinto"})

    assert redirected_to(response, 303) == "/games/qwinto"

    version = get_req_header(conn, "x-inertia-version") |> List.first()

    response =
      response
      |> recycle()
      |> put_req_header("x-inertia-version", version)
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-partial-component", "game")
      |> put_req_header("x-inertia-partial-data", "favorites,auth,errors")
      |> get(redirected_to(response, 303))

    assert inertia_props(response).favorites == []
    refute inertia_props(response).auth.authenticated
    assert inertia_errors(response) == %{authentication: "Sign in to save favorites."}
    refute Repo.exists?(Favorite)
  end

  test "form redirects refresh confirmed membership after adding and removing", %{conn: conn} do
    conn = log_in_user(conn, user_fixture())
    version = conn |> get_req_header("x-inertia-version") |> List.first()
    response = put conn, ~p"/favorites/183006", %{slug: "qwinto", response_to: "/"}
    assert redirected_to(response, 303) == "/"

    page =
      response
      |> recycle()
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-version", version)
      |> put_req_header("x-inertia-partial-component", "home")
      |> put_req_header("x-inertia-partial-data", "favorites,auth,errors")
      |> get(~p"/")

    assert inertia_props(page).favorites == [183_006]
    assert inertia_errors(page) == %{}

    response = page |> recycle() |> delete(~p"/favorites/183006", %{response_to: "/"})
    assert redirected_to(response, 303) == "/"

    page =
      response
      |> recycle()
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-version", version)
      |> put_req_header("x-inertia-partial-component", "home")
      |> put_req_header("x-inertia-partial-data", "favorites,auth,errors")
      |> get(~p"/")

    assert inertia_props(page).favorites == []
    assert inertia_errors(page) == %{}
  end

  test "partial headers cannot bypass the expected game identity", %{conn: conn} do
    conn =
      conn
      |> log_in_user(user_fixture())
      |> put_req_header("x-inertia-partial-component", "game")
      |> put_req_header("x-inertia-partial-data", "favorites,auth,errors")

    {:ok, _game} = Games.update(game_fixture(183_006), %{bgg_id: 900_001})

    assert_error(
      put(conn, ~p"/favorites/183006", %{slug: "qwinto"}),
      :favorite,
      "This game has changed. Refresh the page and try again."
    )

    refute Repo.exists?(Favorite)
  end

  defp assert_success(conn) do
    assert redirected_to(conn, 303) == "/"
    assert inertia_errors(conn) == %{}
  end

  defp assert_error(conn, key, message) do
    assert redirected_to(conn, 303) == "/"
    assert inertia_errors(conn) == %{key => message}
    version = get_req_header(conn, "x-inertia-version") |> List.first()

    response =
      conn
      |> recycle()
      |> put_req_header("x-inertia", "true")
      |> put_req_header("x-inertia-version", version)
      |> get(~p"/about")

    assert inertia_errors(response) == %{key => message}
  end
end
