defmodule D20.Games.RegistryTest do
  use ExUnit.Case, async: false

  alias D20.Games.Registry
  alias D20.Games.Registry.Entry

  setup do
    original_config = Application.fetch_env!(:d20, Registry)

    on_exit(fn -> Application.put_env(:d20, Registry, original_config) end)
  end

  test "lists registered games with available rules" do
    entries = Registry.list()

    assert Enum.map(entries, & &1.slug) == [
             "fliptown",
             "koala-rescue-club",
             "next-station-london",
             "qwinto"
           ]

    assert %Registry.Entry{bgg_id: 352_418, engine: D20.Fliptown.Game, sandbox: fliptown_sandbox} =
             entry_by_slug(entries, "fliptown")

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

    assert "allow-scripts" in fliptown_sandbox
    assert "allow-scripts" in koala_sandbox
    assert "allow-scripts" in next_station_sandbox
    assert "allow-scripts" in qwinto_sandbox
  end

  test "fetches registered games by internal slug" do
    assert {:ok, %Registry.Entry{} = entry} = Registry.fetch("fliptown")
    assert entry.slug == "fliptown"
    assert entry.bgg_id == 352_418

    assert {:ok, %Registry.Entry{} = entry} = Registry.fetch("qwinto")
    assert entry.slug == "qwinto"
    assert entry.bgg_id == 183_006

    assert {:ok, %Registry.Entry{} = entry} = Registry.fetch("next-station-london")
    assert entry.slug == "next-station-london"
    assert entry.bgg_id == 353_545

    assert Registry.fetch("missing") == {:error, :game_not_found}
  end

  test "exposes configured engines for workflow-specific validation" do
    assert {:ok, %Registry.Entry{engine: D20.Fliptown.Game}} = Registry.fetch("fliptown")
    assert {:ok, %Registry.Entry{engine: D20.Qwinto.Game}} = Registry.fetch("qwinto")

    assert {:ok, %Registry.Entry{engine: D20.KoalaRescueClub.Game}} =
             Registry.fetch("koala-rescue-club")

    assert D20.Game.ensure_engine(D20.Fliptown.Game) == {:ok, D20.Fliptown.Game}
    assert D20.Game.ensure_engine(D20.KoalaRescueClub.Game) == {:ok, D20.KoalaRescueClub.Game}

    put_games(qwinto: [engine: String, bgg_id: 183_006, sandbox: ["allow-scripts"]])

    assert {:ok, %Registry.Entry{engine: String} = entry} = Registry.fetch("qwinto")
    assert D20.Game.ensure_engine(entry.engine) == {:error, :invalid_engine}
  end

  test "exposes iframe sandbox on the fetched entry" do
    assert {:ok, %Registry.Entry{} = entry} = Registry.fetch("qwinto")
    assert entry.slug == "qwinto"
    assert "allow-scripts" in entry.sandbox
    refute Map.has_key?(entry, :attrs)
    refute Map.has_key?(entry, :embed_url)
    refute Map.has_key?(entry, :allowed_origins)
  end

  test "builds entries through their changeset" do
    attrs = %{
      slug: "qwinto",
      engine: D20.Qwinto.Game,
      bgg_id: 183_006,
      sandbox: ["allow-scripts"]
    }

    assert %Ecto.Changeset{valid?: true} = Entry.changeset(attrs)
    assert %Entry{slug: "qwinto", engine: D20.Qwinto.Game, bgg_id: 183_006} = Entry.new!(attrs)
  end

  test "validates registry entry attrs" do
    changeset = Entry.changeset(%{slug: "invalid_slug", engine: nil, bgg_id: 0, sandbox: []})

    refute changeset.valid?
    assert_error(changeset, :slug, "has invalid format")
    assert_error(changeset, :engine, "can't be blank")
    assert_error(changeset, :bgg_id, "must be a positive integer")
    assert_error(changeset, :sandbox, "must be a non-empty list of strings")
  end

  test "raises invalid changeset errors for invalid configured entries" do
    put_games(qwinto: [engine: D20.Qwinto.Game, bgg_id: nil, sandbox: ["allow-scripts"]])

    assert_raise Ecto.InvalidChangesetError, fn -> Registry.fetch("qwinto") end

    put_games(qwinto: [engine: D20.Qwinto.Game, bgg_id: 183_006, sandbox: []])

    assert_raise Ecto.InvalidChangesetError, fn -> Registry.fetch("qwinto") end
  end

  defp put_games(games) do
    Application.put_env(:d20, Registry, games: games)
  end

  defp entry_by_slug(entries, slug) do
    Enum.find(entries, &(&1.slug == slug))
  end

  defp assert_error(changeset, field, message) do
    assert Enum.any?(changeset.errors, fn
             {^field, {^message, _opts}} -> true
             _error -> false
           end)
  end
end
