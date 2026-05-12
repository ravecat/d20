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

  test "returns not found for unknown games" do
    assert Games.fetch_by_slug("missing") == {:error, :not_found}
    assert Games.fetch_playable_context_by_slug("missing") == {:error, :game_not_found}
  end

  test "resolves a game slug to metadata, iframe module entry, and engine" do
    assert {:ok, playable_context} = Games.fetch_playable_context_by_slug("qwinto")
    assert playable_context.game.slug == "qwinto"
    assert playable_context.module_entry.id == "qwinto"
    assert playable_context.engine == D20.Qwinto.Game
  end

  test "returns engine not found when a playable game has no configured engine" do
    manifest_config = Application.fetch_env!(:d20, D20.Module.Manifest)

    Application.put_env(
      :d20,
      D20.Module.Manifest,
      Keyword.put(manifest_config, :engines, [])
    )

    on_exit(fn ->
      Application.put_env(:d20, D20.Module.Manifest, manifest_config)
    end)

    assert Games.fetch_playable_context_by_slug("qwinto") == {:error, :engine_not_found}
  end
end
