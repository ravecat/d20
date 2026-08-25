defmodule D20.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :role, :string, null: false, default: "user"
    end

    create constraint(:users, :users_role_domain, check: "role IN ('user', 'admin')")
  end

  def down do
    alter table(:users) do
      remove :role
    end
  end
end
