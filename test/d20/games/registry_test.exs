defmodule D20.Games.RegistryTest do
  use ExUnit.Case, async: false

  alias D20.Games.Registry

  setup do
    original_config = Application.fetch_env!(:d20, Registry)

    on_exit(fn -> Application.put_env(:d20, Registry, original_config) end)
  end

  test "lists registered games with available rules" do
    entries = Registry.list()

    assert Enum.map(entries, & &1.slug) == ["koala-rescue-club", "next-station-london", "qwinto"]

    assert %Registry.Entry{
             bgg_id: 425_873,
             engine: D20.KoalaRescueClub.Game,
             sandbox: koala_sandbox
           } = entry_by_slug(entries, "koala-rescue-club")

    assert %Registry.Entry{
             bgg_id: 353_545,
             engine: D20.NextStationLondon.Game,
             sandbox: next_station_sandbox
           } = entry_by_slug(entries, "next-station-london")

    assert %Registry.Entry{bgg_id: 183_006, engine: D20.Qwinto.Game, sandbox: qwinto_sandbox} =
             entry_by_slug(entries, "qwinto")

    assert "allow-scripts" in koala_sandbox
    assert "allow-scripts" in next_station_sandbox
    assert "allow-scripts" in qwinto_sandbox
  end

  test "fetches registered games by internal slug" do
    assert {:ok, %Registry.Entry{} = entry} = Registry.fetch("qwinto")
    assert entry.slug == "qwinto"
    assert entry.bgg_id == 183_006

    assert {:ok, %Registry.Entry{} = entry} = Registry.fetch("next-station-london")
    assert entry.slug == "next-station-london"
    assert entry.bgg_id == 353_545

    assert Registry.fetch("missing") == {:error, :game_not_found}
  end

  test "exposes configured engines for workflow-specific validation" do
    assert {:ok, %Registry.Entry{engine: D20.Qwinto.Game}} = Registry.fetch("qwinto")

    assert {:ok, %Registry.Entry{engine: D20.KoalaRescueClub.Game}} =
             Registry.fetch("koala-rescue-club")

    assert D20.Game.ensure_engine(D20.KoalaRescueClub.Game) == {:ok, D20.KoalaRescueClub.Game}

    put_games(qwinto: [engine: String, bgg_id: 183_006, sandbox: ["allow-scripts"]])

    assert {:ok, %Registry.Entry{engine: String} = entry} = Registry.fetch("qwinto")
    assert D20.Game.ensure_engine(entry.engine) == {:error, :invalid_engine}
  end

  test "exposes iframe sandbox on the fetched entry" do
    assert {:ok, %Registry.Entry{} = entry} = Registry.fetch("qwinto")
    assert entry.slug == "qwinto"
    assert "allow-scripts" in entry.sandbox
    refute Map.has_key?(entry, :embed_url)
    refute Map.has_key?(entry, :allowed_origins)
  end

  test "validates BGG id and sandbox policy" do
    put_games(qwinto: [engine: D20.Qwinto.Game, bgg_id: nil, sandbox: ["allow-scripts"]])

    assert_raise ArgumentError, ~r/invalid BGG id/, fn -> Registry.fetch("qwinto") end

    put_games(qwinto: [engine: D20.Qwinto.Game, bgg_id: 183_006, sandbox: []])

    assert_raise ArgumentError, ~r/invalid iframe sandbox/, fn -> Registry.fetch("qwinto") end
  end

  defp put_games(games) do
    Application.put_env(:d20, Registry, games: games)
  end

  defp entry_by_slug(entries, slug) do
    Enum.find(entries, &(&1.slug == slug))
  end
end
