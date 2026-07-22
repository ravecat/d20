defmodule D20.Games.Sources.Local do
  @moduledoc """
  Minimal offline metadata for the games registered by D20.

  This source keeps local development and manual game testing independent from
  BoardGameGeek availability. Rich catalog metadata remains owned by the
  BoardGameGeek source.
  """

  @behaviour D20.Games.MetadataSource

  @games %{
    50 => "Lost Cities",
    131_260 => "Qwixx",
    169_654 => "Deep Sea Adventure",
    183_006 => "Qwinto",
    245_654 => "Railroad Ink: Deep Blue Edition",
    283_864 => "Trails of Tucana",
    302_280 => "Shifting Stones",
    322_703 => "Death Valley",
    342_200 => "Confusing Lands",
    350_736 => "Voyages",
    352_418 => "Fliptown",
    352_454 => "Trailblazers",
    353_545 => "Next Station: London",
    360_471 => "Aquamarine",
    361_850 => "Nimalia",
    373_106 => "Sky Team",
    388_329 => "Waypoints",
    420_087 => "Flip 7",
    425_873 => "Koala Rescue Club"
  }

  @impl true
  def fetch_game_details(bgg_id) when is_integer(bgg_id) and bgg_id > 0 do
    case Map.fetch(@games, bgg_id) do
      {:ok, name} -> {:ok, %{bgg_id: bgg_id, name: name}}
      :error -> {:error, :game_not_found}
    end
  end

  @impl true
  def fetch_games_details(bgg_ids) when is_list(bgg_ids) do
    if Enum.all?(bgg_ids, &(is_integer(&1) and &1 > 0)) do
      {:ok,
       Enum.flat_map(bgg_ids, fn bgg_id ->
         case Map.fetch(@games, bgg_id) do
           {:ok, name} -> [%{bgg_id: bgg_id, name: name}]
           :error -> []
         end
       end)}
    else
      {:error, :invalid_bgg_ids}
    end
  end
end
