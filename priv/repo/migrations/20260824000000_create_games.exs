defmodule D20.Repo.Migrations.CreateGames do
  use Ecto.Migration

  @games [
    {360_471, :planned, nil},
    {342_200, :planned, nil},
    {322_703, :planned, nil},
    {169_654, :planned, nil},
    {420_087, :planned, nil},
    {352_418, :planned, 1},
    {425_873, :released, 2},
    {50, :planned, nil},
    {361_850, :planned, nil},
    {353_545, :in_development, 3},
    {245_654, :planned, nil},
    {183_006, :released, 4},
    {131_260, :planned, nil},
    {302_280, :planned, nil},
    {373_106, :planned, nil},
    {352_454, :planned, nil},
    {283_864, :planned, nil},
    {350_736, :planned, nil},
    {388_329, :planned, nil}
  ]

  def up do
    create table(:games, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :bgg_id, :integer, null: false
      add :stage, :string, null: false, default: "planned"
      add :enabled, :boolean, null: false, default: true
      add :engine, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:games, [:bgg_id], name: :games_bgg_id_index)

    create constraint(
             :games,
             :games_id_typeid_format,
             check: "id ~ '^game_[0-7][0123456789abcdefghjkmnpqrstvwxyz]{25}$'"
           )

    create constraint(
             :games,
             :games_bgg_id_positive,
             check: "bgg_id > 0"
           )

    create constraint(
             :games,
             :games_stage_domain,
             check: "stage IN ('planned', 'in_development', 'released')"
           )

    create constraint(
             :games,
             :games_engine_domain,
             check: "engine IS NULL OR engine IN (1, 2, 3, 4)"
           )

    create constraint(
             :games,
             :games_launch_stage_requires_engine,
             check: "stage = 'planned' OR engine IS NOT NULL"
           )

    flush()

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    first_timestamp = System.system_time(:millisecond) - length(@games)

    rows =
      @games
      |> Enum.with_index()
      |> Enum.map(fn {{bgg_id, stage, engine}, index} ->
        id = TypeID.new("game", time: first_timestamp + index) |> TypeID.to_string()

        %{
          id: id,
          bgg_id: bgg_id,
          stage: Atom.to_string(stage),
          enabled: true,
          engine: engine,
          inserted_at: now,
          updated_at: now
        }
      end)

    execute(fn -> repo().insert_all("games", rows) end)
  end

  def down do
    drop constraint(:games, :games_launch_stage_requires_engine)
    drop constraint(:games, :games_engine_domain)
    drop constraint(:games, :games_stage_domain)
    drop constraint(:games, :games_bgg_id_positive)
    drop constraint(:games, :games_id_typeid_format)
    drop index(:games, [:bgg_id], name: :games_bgg_id_index)
    drop table(:games)
  end
end
