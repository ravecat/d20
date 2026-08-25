defmodule D20.Games.GameTest do
  use D20.DataCase, async: false

  alias D20.Games
  alias D20.Games.Game

  describe "persisted game schema" do
    test "loads permanent integer engine mappings as modules" do
      assert {:ok, %Game{} = qwinto} = Games.get(game_id(183_006))
      assert qwinto.bgg_id == 183_006
      assert qwinto.stage == :released
      assert qwinto.enabled
      assert qwinto.engine == D20.Qwinto.Game

      assert {:ok, D20.Qwinto.Game} = Games.engine(qwinto)
    end

    test "planned game has no engine and is non-launchable" do
      assert {:ok, %Game{} = voyages} = Games.get(game_id(350_736))
      assert voyages.stage == :planned
      assert is_nil(voyages.engine)
      refute Games.session_launch_available?(voyages)
    end

    test "released game is launchable when enabled" do
      assert {:ok, %Game{} = qwinto} = Games.get(game_id(183_006))
      assert Games.session_launch_available?(qwinto)
    end

    test "disabled game is non-launchable regardless of stage" do
      game = %Game{bgg_id: 999_998, stage: :released, enabled: false, engine: D20.Qwinto.Game}

      refute Games.session_launch_available?(game)
    end

    test "launch-stage game without engine is rejected" do
      changeset =
        Game.changeset(%Game{}, %{bgg_id: 999_997, stage: :released, enabled: true, engine: nil})

      assert %{errors: errors} = changeset
      assert {"is required", _} = errors[:engine]
    end

    test "non-positive bgg id is rejected" do
      changeset = Game.changeset(%Game{}, %{bgg_id: -1, stage: :planned})
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

    test "backfill produces canonical TypeIDs in former registry order" do
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

      games = Repo.all(from game in Game, order_by: game.id)
      ids = Enum.map(games, &TypeID.to_string(&1.id))

      assert Enum.map(games, & &1.bgg_id) == expected_bgg_ids
      assert length(Enum.uniq(ids)) == 19
      assert ids == Enum.sort(ids)

      assert Enum.all?(
               ids,
               &Regex.match?(~r/^game_[0-7][0123456789abcdefghjkmnpqrstvwxyz]{25}$/, &1)
             )

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
               |> Game.changeset(%{bgg_id: 999_996, stage: :planned, enabled: true})
               |> Repo.insert()

      assert TypeID.prefix(later_game.id) == "game"
      assert TypeID.to_string(later_game.id) > List.last(ids)
    end

    test "database rejects a non-game TypeID primary key" do
      assert {:error, %Postgrex.Error{postgres: %{constraint: "games_id_typeid_format"}}} =
               Repo.query("""
               INSERT INTO games (id, bgg_id, stage, enabled, inserted_at, updated_at)
               VALUES ('user_01h45y6thxeyg95gnpgqqefgpa', 999995, 'planned', TRUE, NOW(), NOW())
               """)
    end
  end
end
