defmodule D20.Games.GameTest do
  use D20.DataCase, async: false

  alias D20.Games
  alias D20.Games.Game

  describe "persisted game schema" do
    test "loads permanent integer engine mappings as modules" do
      assert {:ok, %Game{} = qwinto} = Games.get(game_id(183_006))
      assert qwinto.slug == "qwinto"
      assert qwinto.bgg_id == 183_006
      assert qwinto.stage == :released
      assert qwinto.enabled
      assert qwinto.engine == D20.Qwinto.Game

      assert {:ok, D20.Qwinto.Game} = Games.engine(qwinto)
    end

    test "in-development game has no engine and is non-launchable" do
      assert {:ok, %Game{} = voyages} = Games.get(game_id(350_736))
      assert voyages.slug == "voyages"
      assert voyages.stage == :in_development
      assert is_nil(voyages.engine)
      refute Games.session_launch_available?(voyages)
    end

    test "new records default to in-development without an engine" do
      assert {:ok, %Game{stage: :in_development, engine: nil, enabled: true}} =
               %Game{}
               |> Game.create_changeset(%{slug: "new-game", bgg_id: 999_994})
               |> Repo.insert()
    end

    test "in-development records can omit or remove an engine" do
      assert {:ok, game} = Games.get(game_id(353_545))

      assert {:ok, %Game{stage: :in_development, engine: nil}} =
               Games.update(game, %{engine: nil})
    end

    test "planned is no longer a valid stage" do
      changeset = Game.changeset(%Game{}, %{bgg_id: 999_993, stage: :planned})
      refute changeset.valid?
      assert changeset.errors[:stage]
    end

    test "database defaults new records to in-development without an engine" do
      now = DateTime.truncate(DateTime.utc_now(), :second)

      row = %{
        id: TypeID.new("game") |> to_string(),
        slug: "new-game",
        bgg_id: 999_992,
        inserted_at: now,
        updated_at: now
      }

      assert {1, [%{stage: "in_development", engine: nil, enabled: true}]} =
               Repo.insert_all("games", [row], returning: [:stage, :engine, :enabled])
    end

    test "database rejects the removed planned stage" do
      error =
        assert_raise Postgrex.Error, fn -> Repo.update_all("games", set: [stage: "planned"]) end

      assert error.postgres.constraint == "games_stage_domain"
    end

    test "database requires an engine only for released games" do
      error =
        assert_raise Postgrex.Error, fn ->
          from(game in "games", where: game.bgg_id == 350_736)
          |> Repo.update_all(set: [stage: "released"])
        end

      assert error.postgres.constraint == "games_launch_stage_requires_engine"
    end

    test "released game is launchable when enabled" do
      assert {:ok, %Game{} = qwinto} = Games.get(game_id(183_006))
      assert Games.session_launch_available?(qwinto)
    end

    test "disabled game is non-launchable regardless of stage" do
      game = %Game{
        slug: "disabled",
        bgg_id: 999_998,
        stage: :released,
        enabled: false,
        engine: D20.Qwinto.Game
      }

      refute Games.session_launch_available?(game)
    end

    test "create changeset requires the operator-assigned slug and BGG binding" do
      changeset = Game.create_changeset(%Game{}, %{bgg_id: 999_997, stage: :in_development})
      assert changeset.errors[:slug]

      changeset = Game.create_changeset(%Game{}, %{slug: "new-game", stage: :in_development})
      assert changeset.errors[:bgg_id]
    end

    test "create changeset rejects malformed and overlong slugs" do
      for slug <- ["New-Game", "new_game", "-new-game", "new-game-", "new--game", "двадцать"] do
        changeset =
          Game.create_changeset(%Game{}, %{slug: slug, bgg_id: 999_997, stage: :in_development})

        assert changeset.errors[:slug], "expected slug #{inspect(slug)} to be rejected"
      end

      changeset =
        Game.create_changeset(%Game{}, %{
          slug: String.duplicate("a", 64),
          bgg_id: 999_997,
          stage: :in_development
        })

      assert changeset.errors[:slug]
    end

    test "create changeset accepts a canonical slug and duplicates a stored slug" do
      assert {:ok, %Game{slug: "new-game"} = created} =
               %Game{}
               |> Game.create_changeset(%{
                 slug: "new-game",
                 bgg_id: 999_997,
                 stage: :in_development,
                 enabled: true
               })
               |> Repo.insert()

      assert TypeID.prefix(created.id) == "game"

      assert {:error, %Ecto.Changeset{} = changeset} =
               %Game{}
               |> Game.create_changeset(%{
                 slug: "new-game",
                 bgg_id: 999_996,
                 stage: :in_development,
                 enabled: true
               })
               |> Repo.insert()

      assert changeset.errors[:slug]
    end

    test "launch-stage game without engine is rejected" do
      changeset =
        Game.create_changeset(%Game{}, %{
          slug: "new-game",
          bgg_id: 999_997,
          stage: :released,
          enabled: true,
          engine: nil
        })

      assert %{errors: errors} = changeset
      assert {"can't be blank", _} = errors[:engine]
    end

    test "ordinary update changeset cannot mutate the persisted slug" do
      assert {:ok, %Game{} = qwinto} = Games.get(game_id(183_006))

      changeset =
        Game.changeset(qwinto, %{slug: "renamed-qwinto", bgg_id: 999_995, stage: :released})

      refute Map.has_key?(changeset.changes, :slug)

      assert {:ok, %Game{slug: "qwinto", bgg_id: 999_995}} =
               Games.update(qwinto, %{slug: "renamed-qwinto", bgg_id: 999_995})
    end

    test "non-positive bgg id is rejected" do
      changeset =
        Game.create_changeset(%Game{}, %{slug: "new-game", bgg_id: -1, stage: :in_development})

      assert changeset.errors[:bgg_id]
    end

    test "engines derive deployed modules from the enum" do
      assert Game.engines() == [
               D20.Fliptown.Game,
               D20.KoalaRescueClub.Game,
               D20.NextStationLondon.Game,
               D20.Qwinto.Game
             ]
    end

    test "backfill produces canonical TypeIDs and former registry slugs in registry order" do
      expected_bgg_ids = [
        360_471,
        342_200,
        322_703,
        169_654,
        420_087,
        352_418,
        425_873,
        50,
        361_850,
        353_545,
        245_654,
        183_006,
        131_260,
        302_280,
        373_106,
        352_454,
        283_864,
        350_736,
        388_329
      ]

      expected_slugs = [
        "aquamarine",
        "confusing-lands",
        "death-valley",
        "deep-sea-adventure",
        "flip-7",
        "fliptown",
        "koala-rescue-club",
        "lost-cities",
        "nimalia",
        "next-station-london",
        "railroad-ink",
        "qwinto",
        "qwixx",
        "shifting-stones",
        "sky-team",
        "trailblazers",
        "trails-of-tucana",
        "voyages",
        "waypoints"
      ]

      games = Repo.all(from game in Game, order_by: game.id)
      ids = Enum.map(games, &TypeID.to_string(&1.id))

      assert Enum.map(games, & &1.bgg_id) == expected_bgg_ids
      assert Enum.map(games, & &1.slug) == expected_slugs
      assert Enum.count_until(Enum.uniq(ids), 20) == 19
      assert Enum.count_until(Enum.uniq(expected_slugs), 20) == 19
      assert ids == Enum.sort(ids)

      assert Enum.all?(
               ids,
               &Regex.match?(~r/^game_[0-7][0123456789abcdefghjkmnpqrstvwxyz]{25}$/, &1)
             )

      assert Enum.all?(expected_slugs, &Regex.match?(~r/^[a-z0-9]+(-[a-z0-9]+)*$/, &1))

      assert Enum.all?(games, & &1.enabled)

      assert Enum.map(games, & &1.engine) == [
               nil,
               nil,
               nil,
               nil,
               nil,
               D20.Fliptown.Game,
               D20.KoalaRescueClub.Game,
               nil,
               nil,
               D20.NextStationLondon.Game,
               nil,
               D20.Qwinto.Game,
               nil,
               nil,
               nil,
               nil,
               nil,
               nil,
               nil
             ]

      assert {:ok, %Game{} = later_game} =
               %Game{}
               |> Game.create_changeset(%{
                 slug: "later-game",
                 bgg_id: 999_996,
                 stage: :in_development,
                 enabled: true
               })
               |> Repo.insert()

      assert TypeID.prefix(later_game.id) == "game"
      assert TypeID.to_string(later_game.id) > List.last(ids)
      assert later_game.slug == "later-game"
    end

    test "database rejects a non-game TypeID primary key" do
      assert {:error, %Postgrex.Error{postgres: %{constraint: "games_id_typeid_format"}}} =
               Repo.query("""
               INSERT INTO games (id, slug, bgg_id, stage, enabled, inserted_at, updated_at)
               VALUES ('user_01h45y6thxeyg95gnpgqqefgpa', 'new-game', 999995, 'in_development', TRUE, NOW(), NOW())
               """)
    end

    test "database rejects malformed and overlong slugs" do
      assert {:error, %Postgrex.Error{postgres: %{constraint: "games_slug_format"}}} =
               Repo.query("""
               INSERT INTO games (id, slug, bgg_id, stage, enabled, inserted_at, updated_at)
               VALUES ('#{TypeID.to_string(TypeID.new("game"))}', 'New_Game', 999995, 'in_development', TRUE, NOW(), NOW())
               """)

      assert {:error, %Postgrex.Error{postgres: %{constraint: "games_slug_format"}}} =
               Repo.query("""
               INSERT INTO games (id, slug, bgg_id, stage, enabled, inserted_at, updated_at)
               VALUES ('#{TypeID.to_string(TypeID.new("game"))}', '#{String.duplicate("a", 64)}', 999994, 'in_development', TRUE, NOW(), NOW())
               """)
    end

    test "database rejects a duplicated slug" do
      assert {:error, %Postgrex.Error{postgres: %{constraint: "games_slug_index"}}} =
               Repo.query("""
               INSERT INTO games (id, slug, bgg_id, stage, enabled, inserted_at, updated_at)
               VALUES ('#{TypeID.to_string(TypeID.new("game"))}', 'qwinto', 999995, 'in_development', TRUE, NOW(), NOW())
               """)
    end
  end
end
