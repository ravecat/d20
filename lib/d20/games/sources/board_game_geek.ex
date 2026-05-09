defmodule D20.Games.Sources.BoardGameGeek do
  @moduledoc """
  BoardGameGeek source adapter for game metadata.

  Live HTTP fetching, authorization, retry behavior, and throttling are
  intentionally out of scope for this step. The nested parser owns translation
  from BGG XML into project game attributes.
  """

  @type game_attrs :: %{
          optional(:external_id) => integer(),
          optional(:slug) => String.t() | nil,
          optional(:name) => String.t(),
          optional(:alternate_names) => [String.t()],
          optional(:description) => String.t(),
          optional(:thumbnail_url) => String.t(),
          optional(:image_url) => String.t(),
          optional(:year_published) => integer(),
          optional(:min_players) => integer(),
          optional(:max_players) => integer(),
          optional(:playing_time) => integer(),
          optional(:min_play_time) => integer(),
          optional(:max_play_time) => integer(),
          optional(:min_age) => integer()
        }

  @spec parse_game_details(binary()) :: {:ok, [game_attrs()]} | {:error, term()}
  def parse_game_details(xml) when is_binary(xml) do
    __MODULE__.Parser.parse_game_details(xml)
  end

  defmodule Parser do
    @moduledoc false

    import SweetXml

    @spec parse_game_details(binary()) ::
            {:ok, [D20.Games.Sources.BoardGameGeek.game_attrs()]} | {:error, term()}
    def parse_game_details(xml) when is_binary(xml) do
      attrs =
        xml
        |> SweetXml.parse(dtd: :none)
        |> xpath(~x"/items/item"el)
        |> Enum.map(&parse_item_attrs/1)

      {:ok, attrs}
    rescue
      exception -> {:error, exception}
    catch
      :exit, reason -> {:error, reason}
    end

    defp parse_item_attrs(item) do
      %{
        external_id: xpath(item, ~x"./@id"Io),
        slug: nil,
        name: xpath(item, ~x"./name[@type='primary']/@value"so),
        alternate_names: xpath(item, ~x"./name[@type='alternate']/@value"sl),
        description: xpath(item, ~x"./description/text()"so),
        thumbnail_url: xpath(item, ~x"./thumbnail/text()"so),
        image_url: xpath(item, ~x"./image/text()"so),
        year_published: xpath(item, ~x"./yearpublished/@value"Io),
        min_players: xpath(item, ~x"./minplayers/@value"Io),
        max_players: xpath(item, ~x"./maxplayers/@value"Io),
        playing_time: xpath(item, ~x"./playingtime/@value"Io),
        min_play_time: xpath(item, ~x"./minplaytime/@value"Io),
        max_play_time: xpath(item, ~x"./maxplaytime/@value"Io),
        min_age: xpath(item, ~x"./minage/@value"Io)
      }
    end
  end
end
