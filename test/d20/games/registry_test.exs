defmodule D20.Games.RegistryTest do
  use ExUnit.Case, async: false

  alias D20.Games.Registry
  alias D20.Games.Registry.Entry

  setup do
    original_config = Application.fetch_env!(:d20, Registry)

    on_exit(fn -> Application.put_env(:d20, Registry, original_config) end)
  end

  @catalog_slugs [
    "aquamarine",
    "confusing-lands",
    "death-valley",
    "deep-sea-adventure",
    "flip-7",
    "fliptown",
    "koala-rescue-club",
    "lost-cities",
    "next-station-london",
    "nimalia",
    "qwinto",
    "qwixx",
    "railroad-ink",
    "shifting-stones",
    "sky-team",
    "trailblazers",
    "trails-of-tucana",
    "voyages",
    "waypoints"
  ]

  test "lists all catalog games with their availability" do
    entries = Registry.list()

    assert Enum.map(entries, & &1.slug) == @catalog_slugs

    assert %Registry.Entry{
             bgg_id: 352_418,
             engine: D20.Fliptown.Game,
             sandbox: fliptown_sandbox,
             status: nil
           } = entry_by_slug(entries, "fliptown")

    assert %Registry.Entry{
             bgg_id: 425_873,
             engine: D20.KoalaRescueClub.Game,
             sandbox: koala_sandbox,
             status: :active
           } = entry_by_slug(entries, "koala-rescue-club")

    assert %Registry.Entry{
             bgg_id: 353_545,
             engine: D20.NextStationLondon.Game,
             sandbox: next_station_sandbox,
             status: :in_progress
           } = entry_by_slug(entries, "next-station-london")

    assert %Registry.Entry{
             bgg_id: 183_006,
             engine: D20.Qwinto.Game,
             sandbox: qwinto_sandbox,
             status: :active
           } = entry_by_slug(entries, "qwinto")

    assert %Registry.Entry{bgg_id: 420_087, engine: nil, sandbox: [], status: nil} =
             entry_by_slug(entries, "flip-7")

    assert %Registry.Entry{bgg_id: 245_654, engine: nil, sandbox: [], status: nil} =
             entry_by_slug(entries, "railroad-ink")

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
      sandbox: ["allow-scripts"],
      status: :active
    }

    assert %Ecto.Changeset{valid?: true} = Entry.changeset(attrs)

    assert %Entry{slug: "qwinto", engine: D20.Qwinto.Game, bgg_id: 183_006, status: :active} =
             Entry.new!(attrs)

    assert %Entry{slug: "voyages", bgg_id: 350_736, engine: nil, sandbox: [], status: nil} =
             Entry.new!(%{slug: "voyages", bgg_id: 350_736})
  end

  test "validates registry entry attrs" do
    changeset =
      Entry.changeset(%{
        slug: "invalid_slug",
        engine: nil,
        bgg_id: 0,
        sandbox: [],
        status: :active
      })

    refute changeset.valid?
    assert_error(changeset, :slug, "has invalid format")
    assert_error(changeset, :engine, "can't be blank")
    assert_error(changeset, :bgg_id, "must be greater than %{number}")
    assert_error(changeset, :sandbox, "must be a non-empty list of strings")
  end

  test "rejects unsupported statuses and incomplete launchable bindings" do
    unsupported = Entry.changeset(%{slug: "voyages", bgg_id: 350_736, status: :planned})

    refute unsupported.valid?
    assert_error(unsupported, :status, "must be active or in_progress")

    incomplete = Entry.changeset(%{slug: "voyages", bgg_id: 350_736, status: :in_progress})

    refute incomplete.valid?
    assert_error(incomplete, :engine, "can't be blank")
    assert_error(incomplete, :sandbox, "must be a non-empty list of strings")
  end

  test "raises invalid changeset errors for invalid configured entries" do
    put_games(qwinto: [engine: D20.Qwinto.Game, bgg_id: nil, sandbox: ["allow-scripts"]])

    assert_raise Ecto.InvalidChangesetError, fn -> Registry.fetch("qwinto") end

    put_games(qwinto: [engine: D20.Qwinto.Game, bgg_id: 183_006, sandbox: [], status: :active])

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
