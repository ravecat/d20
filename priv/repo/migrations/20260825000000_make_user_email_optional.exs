defmodule D20.Repo.Migrations.MakeUserEmailOptional do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :email, :citext, null: true, from: {:citext, null: false}
    end
  end

  def down do
    execute """
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM users WHERE email IS NULL) THEN
        RAISE EXCEPTION 'cannot require users.email while provider-only accounts exist';
      END IF;
    END
    $$
    """

    alter table(:users) do
      modify :email, :citext, null: false, from: {:citext, null: true}
    end
  end
end
