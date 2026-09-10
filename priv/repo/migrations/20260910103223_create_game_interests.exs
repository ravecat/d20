defmodule D20.Repo.Migrations.CreateGameInterests do
  use Ecto.Migration

  def change do
    create table(:game_interests, primary_key: false) do
      add :id, :string, primary_key: true, null: false
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false

      add :bgg_id, :integer, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    create constraint(:game_interests, :game_interests_bgg_id_positive, check: "bgg_id > 0")
    create unique_index(:game_interests, [:user_id, :bgg_id])
    create index(:game_interests, [:bgg_id])
  end
end
