defmodule D20.Repo.Migrations.CreateUserIdentities do
  use Ecto.Migration

  def change do
    create table(:user_identities, primary_key: false) do
      add :id, :string, primary_key: true
      add :user_id, references(:users, type: :string, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :provider_uid, :string, null: false

      timestamps type: :utc_datetime
    end

    create index(:user_identities, [:user_id])

    create unique_index(:user_identities, [:provider, :provider_uid],
             name: :user_identities_provider_uid_index
           )

    create unique_index(:user_identities, [:user_id, :provider],
             name: :user_identities_user_provider_index
           )

    create constraint(:user_identities, :user_identities_provider_check,
             check: "provider IN ('google', 'facebook', 'apple', 'discord')"
           )
  end
end
