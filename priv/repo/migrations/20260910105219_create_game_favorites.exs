defmodule D20.Repo.Migrations.CreateGameFavorites do
  use Ecto.Migration

  def change do
    create table(:game_favorites, primary_key: false) do
      add :user_id, references(:users, type: :string, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :bgg_id, :integer, null: false, primary_key: true
      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
