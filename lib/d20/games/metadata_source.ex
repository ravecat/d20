defmodule D20.Games.MetadataSource do
  @moduledoc """
  Contract for providers that resolve catalog display metadata.
  """

  @type game_attrs :: map()

  @callback fetch_game_details(pos_integer()) :: {:ok, game_attrs()} | {:error, term()}
  @callback fetch_games_details([pos_integer()]) :: {:ok, [game_attrs()]} | {:error, term()}
end
