defmodule D20.Games.Interests do
  @moduledoc """
  Records account interest in games and provides requester state and aggregate demand.
  """

  import Ecto.Query

  alias D20.Accounts.User
  alias D20.Games
  alias D20.Games.Interest
  alias D20.Repo

  @doc """
  Records account interest in a freshly resolved, visible, non-playable game.

  The current route determines the BGG identity. Repeated requests preserve
  the original interest ID and timestamp.
  """
  @spec request(User.t(), String.t()) :: :ok | {:error, term()}
  def request(%User{} = user, slug) do
    with {:ok, detail} <- Games.fetch_by_slug(slug),
         true <- is_nil(detail.entry) or Games.visible?(detail.entry) or {:error, :game_not_found},
         true <-
           is_nil(detail.entry) or not Games.session_launch_available?(detail.entry) or
             {:error, :game_available} do
      case Repo.insert(Interest.changeset(user.id, detail.bgg_id),
             on_conflict: :nothing,
             conflict_target: [:user_id, :bgg_id]
           ) do
        {:ok, _interest} -> :ok
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc "Returns whether the current account has requested this game."
  @spec requested?(User.t() | nil, pos_integer()) :: boolean()
  def requested?(nil, _bgg_id), do: false

  def requested?(%User{id: user_id}, bgg_id) do
    Repo.exists?(
      from interest in Interest,
        where: interest.user_id == ^user_id and interest.bgg_id == ^bgg_id
    )
  end

  @doc "Returns the number of accounts requesting the given BGG game."
  @spec count(pos_integer()) :: non_neg_integer()
  def count(bgg_id) do
    Interest
    |> where([interest], interest.bgg_id == ^bgg_id)
    |> Repo.aggregate(:count)
  end

  @doc "Returns aggregate demand without exposing requesting accounts."
  @spec counts() :: [%{bgg_id: pos_integer(), count: non_neg_integer()}]
  def counts do
    Repo.all(
      from interest in Interest,
        group_by: interest.bgg_id,
        select: %{bgg_id: interest.bgg_id, count: count()}
    )
  end
end
