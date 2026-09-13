defmodule D20.Games.Favorites do
  @moduledoc "Persists private, idempotent account favorites independently of catalog availability."

  import Ecto.Query

  alias D20.Accounts.User
  alias D20.Games
  alias D20.Games.Favorite
  alias D20.Repo

  @doc "Returns all favorites saved by this account without resolving catalog data."
  @spec list(User.t() | nil) :: [Favorite.t()]
  def list(nil), do: []

  def list(%User{id: user_id}) do
    Favorite
    |> where([favorite], favorite.user_id == ^user_id)
    |> Repo.all()
  end

  @doc "Creates a favorite after resolving its game data and verifying its expected identity."
  @spec create(User.t() | nil, pos_integer(), String.t()) :: :ok | {:error, term()}
  def create(nil, _bgg_id, _slug), do: {:error, :authentication_required}

  def create(%User{id: user_id}, bgg_id, slug) do
    case Games.fetch_by_slug(slug) do
      {:ok, %{bgg_id: ^bgg_id}} ->
        result =
          %Favorite{user_id: user_id}
          |> Favorite.changeset(%{bgg_id: bgg_id})
          |> Repo.insert(on_conflict: :nothing, conflict_target: [:user_id, :bgg_id])

        case result do
          {:ok, _favorite} -> :ok
          {:error, reason} -> {:error, reason}
        end

      {:ok, _detail} ->
        {:error, :game_identity_changed}

      {:error, _reason} ->
        {:error, :game_not_found}
    end
  end

  @doc "Deletes only this account's membership; an absent membership is already deleted."
  @spec delete(User.t() | nil, pos_integer()) ::
          :ok | {:error, :authentication_required}
  def delete(nil, _bgg_id), do: {:error, :authentication_required}

  def delete(%User{id: user_id}, bgg_id) do
    Favorite
    |> where(user_id: ^user_id, bgg_id: ^bgg_id)
    |> Repo.delete_all()

    :ok
  end
end
