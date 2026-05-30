defmodule D20.GamesTest do
  use ExUnit.Case, async: false

  alias D20.Games
  alias D20.Games.Game

  test "fetches mocked Qwinto metadata by slug" do
    assert {:ok, %Game{} = game} = Games.fetch_by_slug("qwinto")
    assert game.slug == "qwinto"
    assert game.external_id == 183_006
    assert game.name == "Qwinto"
  end

  test "lists game metadata" do
    assert [%Game{} = game] = Games.list()
    assert game.slug == "qwinto"
    assert game.name == "Qwinto"
  end

  test "returns not found for unknown games" do
    assert Games.fetch_by_slug("missing") == {:error, :not_found}
  end
end
