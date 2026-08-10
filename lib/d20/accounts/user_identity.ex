defmodule D20.Accounts.UserIdentity do
  @moduledoc """
  Persists the minimal external identity needed to resolve an existing D20 user.

  Provider credentials and profile claims belong to the authentication boundary
  and are intentionally not part of this schema.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @providers [:google, :facebook, :apple, :discord]
  @primary_key {:id, TypeID, autogenerate: true, prefix: "identity"}
  @foreign_key_type TypeID

  @type id :: TypeID.t()
  @type provider :: :google | :facebook | :apple | :discord

  schema "user_identities" do
    field :provider, Ecto.Enum, values: @providers
    field :provider_uid, :string

    belongs_to :user, D20.Accounts.User

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(user_identity, attrs) do
    user_identity
    |> cast(attrs, [:provider, :provider_uid])
    |> validate_required([:user_id, :provider, :provider_uid])
    |> validate_length(:provider_uid, max: 255)
    |> check_constraint(:provider, name: :user_identities_provider_check)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:provider_uid, name: :user_identities_provider_uid_index)
    |> unique_constraint(:provider, name: :user_identities_user_provider_index)
  end
end
