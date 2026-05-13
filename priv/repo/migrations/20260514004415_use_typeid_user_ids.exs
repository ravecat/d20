defmodule D20.Repo.Migrations.UseTypeidUserIds do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :typeid, :string
    end

    alter table(:users_tokens) do
      add :typeid_user_id, :string
    end

    flush()

    migrate_user_ids()

    execute "ALTER TABLE users ALTER COLUMN typeid SET NOT NULL"
    execute "ALTER TABLE users_tokens ALTER COLUMN typeid_user_id SET NOT NULL"

    drop index(:users_tokens, [:user_id])

    execute "ALTER TABLE users_tokens DROP CONSTRAINT users_tokens_user_id_fkey"
    execute "ALTER TABLE users DROP CONSTRAINT users_pkey"

    alter table(:users_tokens) do
      remove :user_id
    end

    alter table(:users) do
      remove :id
    end

    rename table(:users), :typeid, to: :id
    rename table(:users_tokens), :typeid_user_id, to: :user_id

    execute "ALTER TABLE users ADD PRIMARY KEY (id)"

    execute """
    ALTER TABLE users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    """

    create index(:users_tokens, [:user_id])
  end

  def down do
    alter table(:users) do
      add :integer_id, :bigint
    end

    alter table(:users_tokens) do
      add :integer_user_id, :bigint
    end

    flush()

    execute "CREATE SEQUENCE IF NOT EXISTS users_id_seq"
    execute "ALTER SEQUENCE users_id_seq OWNED BY users.integer_id"
    execute "UPDATE users SET integer_id = nextval('users_id_seq')"

    execute """
    UPDATE users_tokens
    SET integer_user_id = users.integer_id
    FROM users
    WHERE users_tokens.user_id = users.id
    """

    execute "ALTER TABLE users ALTER COLUMN integer_id SET NOT NULL"
    execute "ALTER TABLE users ALTER COLUMN integer_id SET DEFAULT nextval('users_id_seq')"
    execute "ALTER TABLE users_tokens ALTER COLUMN integer_user_id SET NOT NULL"

    drop index(:users_tokens, [:user_id])

    execute "ALTER TABLE users_tokens DROP CONSTRAINT users_tokens_user_id_fkey"
    execute "ALTER TABLE users DROP CONSTRAINT users_pkey"

    alter table(:users_tokens) do
      remove :user_id
    end

    alter table(:users) do
      remove :id
    end

    rename table(:users), :integer_id, to: :id
    rename table(:users_tokens), :integer_user_id, to: :user_id

    execute "ALTER SEQUENCE users_id_seq OWNED BY users.id"
    execute "ALTER TABLE users ADD PRIMARY KEY (id)"

    execute """
    ALTER TABLE users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    """

    execute """
    SELECT setval(
      'users_id_seq',
      COALESCE((SELECT MAX(id) FROM users), 1),
      (SELECT COUNT(*) > 0 FROM users)
    )
    """

    create index(:users_tokens, [:user_id])
  end

  defp migrate_user_ids do
    %{rows: rows} = repo().query!("SELECT id FROM users")

    Enum.each(rows, fn [old_id] ->
      new_id =
        "user"
        |> TypeID.new()
        |> TypeID.to_string()

      repo().query!("UPDATE users SET typeid = $1 WHERE id = $2", [new_id, old_id])

      repo().query!("UPDATE users_tokens SET typeid_user_id = $1 WHERE user_id = $2", [
        new_id,
        old_id
      ])
    end)
  end
end
