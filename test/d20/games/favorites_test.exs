defmodule D20.Games.FavoritesTest do
  use D20.DataCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts.User
  alias D20.Games
  alias D20.Games.Favorite
  alias D20.Games.Favorites
  alias D20.Games.Sources.BoardGameGeek

  setup context do
    Req.Test.set_req_test_from_context(context)
    Req.Test.verify_on_exit!()
    original_config = Application.get_env(:d20, BoardGameGeek)
    original_options = Req.default_options()
    original_stages = Application.fetch_env!(:d20, :visible_game_stages)
    Application.put_env(:d20, BoardGameGeek, api_key: "test-token")
    Application.put_env(:d20, :visible_game_stages, [:released, :in_development])
    Req.default_options(plug: {Req.Test, __MODULE__})

    Req.Test.stub(__MODULE__, fn request ->
      id = if request.params["id"] == "900001", do: "900001", else: "183006"
      Req.Test.text(request, ~s(<items><item type="boardgame" id="#{id}" /></items>))
    end)

    on_exit(fn ->
      Application.put_env(:d20, BoardGameGeek, original_config)
      Application.put_env(:d20, :visible_game_stages, original_stages)
      Req.default_options(original_options)
    end)
  end

  test "missing authentication returns before resolving a source" do
    Req.Test.stub(__MODULE__, fn _request -> flunk("Guests must not resolve games") end)

    assert {:error, :authentication_required} = Favorites.create(nil, 183_006, "qwinto")
    assert {:error, :authentication_required} = Favorites.delete(nil, 183_006)

    refute Repo.exists?(Favorite)
  end

  test "saving checks the resolved identity and removal needs no source" do
    user = user_fixture()
    assert :ok = Favorites.create(user, 183_006, "qwinto")
    assert [%Favorite{bgg_id: 183_006}] = Favorites.list(user)
    assert :ok = Favorites.delete(user, 183_006)
    assert {:ok, _game} = Games.update(game_fixture(183_006), %{bgg_id: 900_001})
    assert {:error, :game_identity_changed} = Favorites.create(user, 183_006, "qwinto")
    assert Favorites.list(user) == []

    Repo.insert!(%Favorite{user_id: user.id, bgg_id: 183_006})
    Application.put_env(:d20, :visible_game_stages, [])
    Req.Test.stub(__MODULE__, fn _request -> flunk("Removal must not resolve games") end)
    assert :ok = Favorites.delete(user, 183_006)
    assert :ok = Favorites.delete(user, 183_006)
  end

  test "hidden game data can be saved without a runtime session" do
    user = user_fixture()
    Application.put_env(:d20, :visible_game_stages, [])

    for slug <- ["qwinto", "00183006"] do
      assert :ok = Favorites.create(user, 183_006, slug)
      assert [%Favorite{bgg_id: 183_006}] = Favorites.list(user)
      assert :ok = Favorites.delete(user, 183_006)
    end
  end

  test "membership is private, batched and independent of local catalog rows" do
    user = user_fixture()
    other = user_fixture()
    first = Repo.insert!(%Favorite{user_id: user.id, bgg_id: 900_001})
    second = Repo.insert!(%Favorite{user_id: user.id, bgg_id: 900_003})
    other_favorite = Repo.insert!(%Favorite{user_id: other.id, bgg_id: 900_002})
    assert MapSet.new(Favorites.list(user)) == MapSet.new([first, second])
    assert Favorites.list(other) == [other_favorite]
    assert Favorites.list(nil) == []
  end

  test "duplicate additions preserve the first-save timestamp and removal is idempotent" do
    user = user_fixture()
    other = user_fixture()
    assert :ok = Favorites.create(user, 183_006, "qwinto")
    original = ~U[2020-01-01 00:00:00Z]
    Repo.update_all(Favorite, set: [inserted_at: original])
    assert :ok = Favorites.create(user, 183_006, "qwinto")
    assert Repo.get_by!(Favorite, user_id: user.id).inserted_at == original
    assert :ok = Favorites.create(other, 183_006, "qwinto")
    assert :ok = Favorites.delete(user, 183_006)
    assert :ok = Favorites.delete(user, 183_006)
    assert [%Favorite{bgg_id: 183_006}] = Favorites.list(other)
    assert :ok = Favorites.create(user, 183_006, "qwinto")
    assert DateTime.compare(Repo.get_by!(Favorite, user_id: user.id).inserted_at, original) == :gt
  end

  test "invalid identities and missing accounts are errors rather than duplicate successes" do
    user = user_fixture()

    for id <- [nil, "invalid"] do
      changeset = Favorite.changeset(%Favorite{user_id: user.id}, %{bgg_id: id})
      refute changeset.valid?
      assert errors_on(changeset).bgg_id != []
    end

    for id <- [0, -1, 2_147_483_648] do
      assert Favorite.changeset(%Favorite{user_id: user.id}, %{bgg_id: id}).valid?
    end

    assert {:error, changeset} =
             Favorites.create(%User{id: TypeID.new("user")}, 183_006, "qwinto")

    assert errors_on(changeset).user_id == ["does not exist"]
  end

  test "the database accepts zero and negative IDs while enforcing composite uniqueness" do
    user = user_fixture()
    row = %{user_id: user.id, bgg_id: 0, inserted_at: DateTime.utc_now(:second)}
    assert {1, nil} = Repo.insert_all(Favorite, [row])
    row = %{row | bgg_id: -1}
    assert {1, nil} = Repo.insert_all(Favorite, [row])
    assert_raise Postgrex.Error, fn -> Repo.insert_all(Favorite, [row]) end
    assert Repo.aggregate(Favorite, :count) == 2
  end

  test "account deletion cascades favorites" do
    user = user_fixture()
    assert :ok = Favorites.create(user, 183_006, "qwinto")
    Repo.delete!(user)
    refute Repo.exists?(from favorite in Favorite, where: favorite.user_id == ^user.id)
  end

  test "catalog rebinding and deletion leave saved identity unchanged" do
    user = user_fixture()
    game = game_fixture(183_006)
    Repo.insert!(%Favorite{user_id: user.id, bgg_id: game.bgg_id})
    assert {:ok, game} = D20.Games.update(game, %{bgg_id: 900_001, enabled: false})
    Repo.delete!(game)
    assert [%Favorite{bgg_id: 183_006}] = Favorites.list(user)
  end

  test "concurrent creates persist exactly one membership" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      user = user_fixture()

      try do
        parent = self()

        tasks =
          for _ <- 1..2 do
            Task.async(fn ->
              Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
                send(parent, {:ready, self()})

                receive do
                  :create -> Favorites.create(user, 900_001, "900001")
                end
              end)
            end)
          end

        ready =
          for _ <- tasks do
            assert_receive {:ready, pid}
            pid
          end

        Enum.each(ready, fn pid ->
          Req.Test.allow(__MODULE__, self(), pid)
          send(pid, :create)
        end)

        assert Enum.map(tasks, &Task.await/1) == [:ok, :ok]

        assert Repo.aggregate(
                 from(favorite in Favorite, where: favorite.user_id == ^user.id),
                 :count
               ) == 1
      after
        Repo.delete!(user)
      end
    end)
  end
end
