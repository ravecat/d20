defmodule D20.Games.Sources.BoardGameGeek do
  @moduledoc """
  BoardGameGeek source adapter for game metadata.

  This module owns runtime access to source-specific configuration, fetching
  game details from the BGG XML API, and XML translation into project game
  attributes.
  """

  @type game_attrs :: %{
          optional(:bgg_id) => integer(),
          optional(:name) => String.t(),
          optional(:alternate_names) => [String.t()],
          optional(:categories) => [String.t()],
          optional(:mechanics) => [String.t()],
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

  @spec fetch_game_details(integer()) :: {:ok, game_attrs()} | {:error, term()}
  def fetch_game_details(bgg_id) when is_integer(bgg_id) and bgg_id > 0 do
    with {:ok, body} <- request_game_details(bgg_id, config!(:api_key)),
         {:ok, [attrs | _attrs]} <- parse_game_details(body) do
      {:ok, attrs}
    else
      {:ok, []} -> {:error, :game_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec parse_game_details(binary()) :: {:ok, [game_attrs()]} | {:error, term()}
  def parse_game_details(xml) when is_binary(xml) do
    __MODULE__.Parser.parse_game_details(xml)
  end

  defp request_game_details(bgg_id, api_key) do
    case Req.get("https://boardgamegeek.com/xmlapi2/thing",
           headers: [{"authorization", "Bearer #{api_key}"}, {"accept", "application/xml"}],
           params: [id: bgg_id, type: "boardgame"],
           retry: false,
           receive_timeout: 10_000
         ) do
      {:ok, %{status: status, body: body}} when status in 200..299 and is_binary(body) ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
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
        bgg_id: xpath(item, ~x"./@id"Io),
        name: xpath(item, ~x"./name[@type='primary']/@value"so),
        alternate_names: xpath(item, ~x"./name[@type='alternate']/@value"sl),
        categories: xpath(item, ~x"./link[@type='boardgamecategory']/@value"sl),
        mechanics: xpath(item, ~x"./link[@type='boardgamemechanic']/@value"sl),
        description: item |> xpath(~x"./description/text()"so) |> decode_html_entities(),
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

    defp decode_html_entities(value) when is_binary(value) do
      Regex.replace(~r/&(#x[0-9a-fA-F]+|#\d+|[A-Za-z][A-Za-z0-9]+);/, value, fn entity,
                                                                                reference ->
        decode_html_entity(reference) || entity
      end)
    end

    defp decode_html_entities(value), do: value

    defp decode_html_entity("#x" <> hex) do
      with {codepoint, ""} <- Integer.parse(hex, 16),
           true <- valid_codepoint?(codepoint) do
        <<codepoint::utf8>>
      else
        _invalid -> nil
      end
    end

    defp decode_html_entity("#" <> decimal) do
      with {codepoint, ""} <- Integer.parse(decimal, 10),
           true <- valid_codepoint?(codepoint) do
        <<codepoint::utf8>>
      else
        _invalid -> nil
      end
    end

    defp decode_html_entity("amp"), do: "&"
    defp decode_html_entity("apos"), do: "'"
    defp decode_html_entity("copy"), do: "©"
    defp decode_html_entity("gt"), do: ">"
    defp decode_html_entity("hellip"), do: "…"
    defp decode_html_entity("laquo"), do: "«"
    defp decode_html_entity("ldquo"), do: "“"
    defp decode_html_entity("lsquo"), do: "‘"
    defp decode_html_entity("lt"), do: "<"
    defp decode_html_entity("mdash"), do: "—"
    defp decode_html_entity("nbsp"), do: " "
    defp decode_html_entity("ndash"), do: "–"
    defp decode_html_entity("quot"), do: "\""
    defp decode_html_entity("raquo"), do: "»"
    defp decode_html_entity("rdquo"), do: "”"
    defp decode_html_entity("reg"), do: "®"
    defp decode_html_entity("rsquo"), do: "’"
    defp decode_html_entity("trade"), do: "™"
    defp decode_html_entity(_entity), do: nil

    defp valid_codepoint?(codepoint) do
      codepoint in 0..0xD7FF or codepoint in 0xE000..0x10FFFF
    end
  end
end
