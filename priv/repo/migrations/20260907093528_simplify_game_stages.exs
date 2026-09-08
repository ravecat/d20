defmodule D20.Repo.Migrations.SimplifyGameStages do
  use Ecto.Migration

  def up do
    drop constraint(:games, :games_stage_domain)
    drop constraint(:games, :games_launch_stage_requires_engine)

    execute("UPDATE games SET stage = 'in_development' WHERE stage = 'planned'")

    alter table(:games) do
      modify :stage, :string, null: false, default: "in_development"
    end

    create constraint(:games, :games_stage_domain,
             check: "stage IN ('in_development', 'released')"
           )

    create constraint(:games, :games_launch_stage_requires_engine,
             check: "stage = 'in_development' OR engine IS NOT NULL"
           )
  end

  def down do
    drop constraint(:games, :games_stage_domain)
    drop constraint(:games, :games_launch_stage_requires_engine)

    execute(
      "UPDATE games SET stage = 'planned' WHERE stage = 'in_development' AND engine IS NULL"
    )

    alter table(:games) do
      modify :stage, :string, null: false, default: "planned"
    end

    create constraint(:games, :games_stage_domain,
             check: "stage IN ('planned', 'in_development', 'released')"
           )

    create constraint(:games, :games_launch_stage_requires_engine,
             check: "stage = 'planned' OR engine IS NOT NULL"
           )
  end
end
