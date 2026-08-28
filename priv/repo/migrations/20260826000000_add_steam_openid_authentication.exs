defmodule D20.Repo.Migrations.AddSteamOpenIDAuthentication do
  use Ecto.Migration

  @providers "provider IN ('google', 'facebook', 'apple', 'discord', 'steam')"

  def up do
    drop constraint(:user_identities, :user_identities_provider_check)

    create constraint(:user_identities, :user_identities_provider_check, check: @providers)

    create constraint(:user_identities, :user_identities_steam_uid_check,
             check: """
             provider <> 'steam' OR
             CASE
               WHEN provider_uid ~ '^[1-9][0-9]{0,19}$'
               THEN provider_uid::numeric <= 18446744073709551615
               ELSE false
             END
             """
           )
  end

  def down do
    drop_if_exists constraint(:user_identities, :user_identities_steam_uid_check)
    drop constraint(:user_identities, :user_identities_provider_check)

    create constraint(:user_identities, :user_identities_provider_check,
             check: "provider IN ('google', 'facebook', 'apple', 'discord')"
           )
  end
end
