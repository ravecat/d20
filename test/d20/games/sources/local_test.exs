defmodule D20.Games.Sources.LocalTest do
  use ExUnit.Case, async: true

  alias D20.Games.Sources.Local

  test "returns bundled metadata by BGG id" do
    assert {:ok, %{bgg_id: 425_873, name: "Koala Rescue Club"}} =
             Local.fetch_game_details(425_873)
  end

  test "preserves request order and omits unknown games in batches" do
    assert {:ok, games} = Local.fetch_games_details([425_873, 999_999, 183_006])

    assert Enum.map(games, &{&1.bgg_id, &1.name}) == [
             {425_873, "Koala Rescue Club"},
             {183_006, "Qwinto"}
           ]
  end

  test "returns not found for unknown games" do
    assert Local.fetch_game_details(999_999) == {:error, :game_not_found}
  end

  test "rejects invalid batch ids" do
    assert Local.fetch_games_details([425_873, 0]) == {:error, :invalid_bgg_ids}
  end
end
