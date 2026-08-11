defmodule D20.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :username, :citext
    end

    create unique_index(:users, [:username], name: :users_username_index)
  end

  def down do
    drop index(:users, [:username], name: :users_username_index)

    alter table(:users) do
      remove :username
    end
  end
end
