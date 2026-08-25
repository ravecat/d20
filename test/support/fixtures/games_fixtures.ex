defmodule D20.GamesFixtures do
  @moduledoc false

  alias D20.Games.Game
  alias D20.Repo

  @spec game_fixture(pos_integer()) :: Game.t()
  def game_fixture(bgg_id), do: Repo.get_by!(Game, bgg_id: bgg_id)

  @spec game_id(pos_integer()) :: Game.id()
  def game_id(bgg_id), do: game_fixture(bgg_id).id
end
