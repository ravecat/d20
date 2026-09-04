defmodule D20.Repo.Migrations.AddSlugToGames do
  use Ecto.Migration

  # Exact former `D20.Games.Registry` slugs keyed by the unique former BGG
  # binding of each migrated row.
  @slug_by_bgg_id [
    {360_471, "aquamarine"},
    {342_200, "confusing-lands"},
    {322_703, "death-valley"},
    {169_654, "deep-sea-adventure"},
    {420_087, "flip-7"},
    {352_418, "fliptown"},
    {425_873, "koala-rescue-club"},
    {50, "lost-cities"},
    {361_850, "nimalia"},
    {353_545, "next-station-london"},
    {245_654, "railroad-ink"},
    {183_006, "qwinto"},
    {131_260, "qwixx"},
    {302_280, "shifting-stones"},
    {373_106, "sky-team"},
    {352_454, "trailblazers"},
    {283_864, "trails-of-tucana"},
    {350_736, "voyages"},
    {388_329, "waypoints"}
  ]

  def up do
    alter table(:games) do
      add :slug, :string
    end

    flush()

    execute(&backfill_slugs/0, fn -> :ok end)

    create unique_index(:games, [:slug], name: :games_slug_index)

    create constraint(
             :games,
             :games_slug_format,
             check: "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' AND char_length(slug) <= 63"
           )

    alter table(:games) do
      modify :slug, :string, null: false
    end
  end

  def down do
    drop constraint(:games, :games_slug_format)
    drop index(:games, [:slug], name: :games_slug_index)

    alter table(:games) do
      remove :slug
    end
  end

  defp backfill_slugs do
    expected_bgg_ids = @slug_by_bgg_id |> Enum.map(&elem(&1, 0)) |> MapSet.new()

    found_bgg_ids =
      repo()
      |> query_bgg_ids()
      |> MapSet.new()

    if found_bgg_ids != expected_bgg_ids do
      raise """
      games slug backfill expects the nineteen former registry BGG bindings \
      #{inspect(Enum.sort(MapSet.to_list(expected_bgg_ids)))}, \
      found #{inspect(Enum.sort(MapSet.to_list(found_bgg_ids)))}. \
      Reconcile manually created or edited rows before migrating: assign the \
      missing slugs, restore removed rows, or fix changed BGG bindings by hand.
      """
    end

    for {bgg_id, slug} <- @slug_by_bgg_id do
      repo().query!("UPDATE games SET slug = $1 WHERE bgg_id = $2", [slug, bgg_id])
    end

    :ok
  end

  defp query_bgg_ids(repo) do
    %{rows: rows} = repo.query!("SELECT bgg_id FROM games")
    Enum.map(rows, &Enum.at(&1, 0))
  end
end
