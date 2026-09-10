defmodule D20.Games.InterestTest do
  use D20.DataCase, async: false

  import D20.AccountsFixtures

  alias D20.Accounts.User
  alias D20.Games
  alias D20.Games.Game
  alias D20.Games.Interest
  alias D20.Games.Interests
  alias D20.Games.Sources.BoardGameGeek
  alias Ecto.Adapters.SQL.Sandbox

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

  test "one request per account and game preserves its generated TypeID and first timestamp" do
    user = provider_user_fixture()
    refute Interests.requested?(user, 900_001)
    refute Interests.requested?(nil, 900_001)
    assert Interests.count(900_001) == 0
    assert :ok = Interests.request(user, "900001")

    original = Repo.get_by!(Interest, user_id: user.id, bgg_id: 900_001)
    assert TypeID.prefix(original.id) == "interest"
    assert Repo.get!(Interest, original.id) == original

    original =
      original |> Ecto.Changeset.change(inserted_at: ~U[2026-01-01 00:00:00Z]) |> Repo.update!()

    assert :ok = Interests.request(user, "900001")
    assert Repo.get_by!(Interest, user_id: user.id, bgg_id: 900_001) == original
    assert Interests.requested?(user, 900_001)
    assert Interests.counts() == [%{bgg_id: 900_001, count: 1}]
    assert Interests.count(900_001) == 1
  end

  test "distinct accounts contribute independently and account deletion removes contributions" do
    user = provider_user_fixture()
    other = provider_user_fixture()
    assert :ok = Interests.request(user, "900001")
    assert :ok = Interests.request(other, "900001")
    assert :ok = Interests.request(user, "900002")

    assert Enum.sort_by(Interests.counts(), & &1.bgg_id) == [
             %{bgg_id: 900_001, count: 2},
             %{bgg_id: 900_002, count: 1}
           ]

    assert Interests.count(900_001) == 2
    assert Interests.count(900_002) == 1
    assert Interests.count(900_003) == 0

    Repo.delete!(user)
    assert Interests.count(900_002) == 0
    assert Interests.counts() == [%{bgg_id: 900_001, count: 1}]
    assert Interests.count(900_001) == 1
  end

  test "invalid subjects and missing accounts are failures rather than duplicate success" do
    user = provider_user_fixture()
    invalid = Interest.changeset(user.id, 0)
    refute invalid.valid?
    assert errors_on(invalid).bgg_id == ["must be greater than 0"]
    Repo.delete!(user)
    assert {:error, missing} = Interests.request(user, "900001")
    assert errors_on(missing).user_id == ["does not exist"]
  end

  test "missing and provider-failed details preserve errors without recording interest" do
    user = provider_user_fixture()
    Req.Test.stub(__MODULE__, &Req.Test.text(&1, "<items />"))
    assert {:error, :game_not_found} = Interests.request(user, "900001")

    Req.Test.stub(__MODULE__, &Plug.Conn.send_resp(&1, 503, "Unavailable"))
    assert {:error, {:http_error, 503}} = Interests.request(user, "900001")
    assert Interests.counts() == []
  end

  test "hidden local games are rejected before checking playability" do
    user = provider_user_fixture()
    Application.put_env(:d20, :visible_game_stages, [])
    assert {:error, :game_not_found} = Interests.request(user, "qwinto")
    assert Interests.counts() == []
  end

  test "interest uses the current local BGG binding without moving earlier requests" do
    user = provider_user_fixture()
    assert :ok = Interests.request(user, "voyages")
    {:ok, _game} = Games.update(game_fixture(350_736), %{bgg_id: 900_002})
    assert :ok = Interests.request(user, "voyages")
    assert Interests.requested?(user, 350_736)
    assert Interests.requested?(user, 900_002)
  end

  test "implemented games accept demand when disabled and preserve it across availability changes" do
    user = provider_user_fixture()
    game = game_fixture(183_006)
    assert {:error, :game_available} = Interests.request(user, game.slug)
    assert Interests.counts() == []

    {:ok, game} = Games.update(game, %{enabled: false})
    assert :ok = Interests.request(user, game.slug)
    original = Repo.get_by!(Interest, user_id: user.id, bgg_id: game.bgg_id)
    {:ok, game} = Games.update(game, %{enabled: true})
    assert {:error, :game_available} = Interests.request(user, game.slug)
    {:ok, game} = Games.update(game, %{enabled: false})
    assert :ok = Interests.request(user, game.slug)
    assert Repo.get_by!(Interest, user_id: user.id, bgg_id: game.bgg_id) == original
    assert Interests.counts() == [%{bgg_id: game.bgg_id, count: 1}]
  end

  test "local metadata fallback and provider routes retain one authoritative subject" do
    user = provider_user_fixture()
    Req.Test.stub(__MODULE__, &Req.Test.text(&1, "<items />"))
    assert :ok = Interests.request(user, "voyages")
    Req.Test.stub(__MODULE__, &Req.Test.text(&1, ~s(<items><item id="350736" /></items>)))
    assert :ok = Interests.request(user, "350736")
    assert Interests.counts() == [%{bgg_id: 350_736, count: 1}]
    assert Interests.count(350_736) == 1
  end

  test "original numeric route avoids a normalized local-slug collision without creating games" do
    user = provider_user_fixture()
    Repo.insert!(%Game{slug: "900001", bgg_id: 900_002, stage: :in_development})
    count = Repo.aggregate(Game, :count)
    assert :ok = Interests.request(user, "00900001")
    assert Interests.requested?(user, 900_001)
    refute Interests.requested?(user, 900_002)
    assert Repo.aggregate(Game, :count) == count
  end

  test "database constraints reject invalid records independently of the changeset" do
    user = provider_user_fixture()

    for {user_id, bgg_id, code} <- [
          {user.id, 0, :check_violation},
          {nil, 1, :not_null_violation},
          {user.id, nil, :not_null_violation},
          {"missing", 1, :foreign_key_violation}
        ] do
      assert {:error, %Postgrex.Error{postgres: %{code: ^code}}} =
               Repo.query(
                 "INSERT INTO game_interests (id, user_id, bgg_id, inserted_at) VALUES ($1, $2, $3, now())",
                 [to_string(TypeID.new("interest")), if(user_id, do: to_string(user_id)), bgg_id],
                 mode: :savepoint
               )
    end
  end

  test "concurrent commits on independent connections record a single request" do
    user = Sandbox.unboxed_run(Repo, fn -> provider_user_fixture() end)
    on_exit(fn -> Sandbox.unboxed_run(Repo, fn -> Repo.delete!(Repo.get!(User, user.id)) end) end)
    parent = self()

    tasks =
      for _ <- 1..2 do
        Task.async(fn ->
          Sandbox.unboxed_run(Repo, fn ->
            send(parent, {:ready, self()})

            receive do
              :submit -> Interests.request(user, "900003")
            end
          end)
        end)
      end

    for task <- tasks, do: assert_receive({:ready, pid} when pid == task.pid, 1_000)
    Enum.each(tasks, &send(&1.pid, :submit))
    assert Task.await_many(tasks) == [:ok, :ok]

    assert Sandbox.unboxed_run(Repo, fn ->
             Repo.aggregate(
               from(interest in Interest, where: interest.user_id == ^user.id),
               :count
             )
           end) == 1
  end
end
