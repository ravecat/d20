defmodule D20.Games.Sources.BoardGameGeek do
  @moduledoc """
  BoardGameGeek source adapter for game metadata.

  This module owns runtime access to source-specific configuration, fetching
  game details from the BGG XML API, and XML translation into project game
  attributes.
  """

  @type game :: %{
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
          optional(:min_age) => integer(),
          optional(:complexity) => float(),
          optional(:rating) => float()
        }

  @spec fetch_hot_games() :: {:ok, [game()]} | {:error, term()}
  @spec fetch_hot_games(limit: term()) :: {:ok, [game()]} | {:error, term()}
  def fetch_hot_games(options \\ []) do
    limit =
      case Keyword.get(options, :limit, 32) do
        value when is_integer(value) and value > 0 -> min(value, 100)
        _value -> 32
      end

    with {:ok, api_key} <- fetch_api_key(),
         {:ok, body} <- request("hot", [type: "boardgame"], api_key),
         {:ok, ids} <- __MODULE__.Parser.parse_hot_games(body),
         ids = Enum.take_random(ids, limit),
         {:ok, games} <- fetch_games(ids) do
      games = Map.new(games, &{&1.bgg_id, &1})

      {:ok, Enum.map(ids, &Map.get(games, &1, %{bgg_id: &1}))}
    end
  end

  @doc """
  Fetches one game using the supplied value and requires exactly one parsed result.
  Values use the same Enum.join serialization as fetch_games/1.
  """
  @spec fetch_game(term()) :: {:ok, game()} | {:error, term()}
  def fetch_game(id) do
    case fetch_games([id]) do
      {:ok, [attrs]} -> {:ok, attrs}
      {:ok, _games} -> {:error, :game_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches supplied values without ID validation, serialized by Enum.join.
  Exact duplicate request values are removed. Parsed games retain provider
  response order within each batch and request order across batches.
  """
  @spec fetch_games(term()) :: {:ok, [game()]} | {:error, term()}
  def fetch_games([]), do: {:ok, []}

  def fetch_games(ids) when is_list(ids) do
    with {:ok, api_key} <- fetch_api_key() do
      fetch_batches(Enum.uniq(ids), api_key)
    end
  end

  def fetch_games(id), do: fetch_games([id])

  defp fetch_batches(ids, api_key) do
    ids
    |> Enum.chunk_every(20)
    |> Task.async_stream(
      fn ids ->
        with {:ok, body} <-
               request("thing", [id: Enum.join(ids, ","), type: "boardgame", stats: 1], api_key) do
          __MODULE__.Parser.parse_game_details(body)
        end
      end, max_concurrency: 2, ordered: true, timeout: 15_000, on_timeout: :kill_task)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, {:ok, games}}, {:ok, batches} -> {:cont, {:ok, batches ++ games}}
      {:ok, {:error, reason}}, _acc -> {:halt, {:error, reason}}
      {:exit, reason}, _acc -> {:halt, {:error, reason}}
    end)
  end

  defp request(endpoint, params, api_key) do
    case Req.get("https://boardgamegeek.com/xmlapi2/#{endpoint}",
           headers: [{"authorization", "Bearer #{api_key}"}, {"accept", "application/xml"}],
           params: params,
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

  defp fetch_api_key do
    api_key = :d20 |> Application.get_env(__MODULE__, []) |> Keyword.get(:api_key)

    case api_key do
      api_key when is_binary(api_key) ->
        case String.trim(api_key) do
          "" -> {:error, :api_key_not_configured}
          api_key -> {:ok, api_key}
        end

      _api_key ->
        {:error, :api_key_not_configured}
    end
  end

  defmodule Parser do
    @moduledoc false

    import SweetXml

    @spec parse_game_details(binary()) ::
            {:ok, [D20.Games.Sources.BoardGameGeek.game()]} | {:error, term()}
    def parse_game_details(xml) when is_binary(xml) do
      attrs =
        xml
        |> SweetXml.parse(dtd: :none)
        |> xpath(~x"/items/item"el)
        |> Enum.filter(fn item -> is_integer(parse_positive_id(xpath(item, ~x"./@id"s))) end)
        |> Enum.map(&parse_item_attrs/1)

      {:ok, attrs}
    rescue
      exception -> {:error, exception}
    catch
      :exit, reason -> {:error, reason}
    end

    @spec parse_hot_games(binary()) :: {:ok, [pos_integer()]} | {:error, term()}
    def parse_hot_games(xml) when is_binary(xml) do
      case xml |> SweetXml.parse(dtd: :none) |> xpath(~x"/items"el) do
        [items] ->
          ids =
            items
            |> xpath(~x"./item/@id"sl)
            |> Enum.map(&parse_positive_id/1)
            |> Enum.filter(&is_integer/1)
            |> Enum.uniq()

          {:ok, ids}

        _invalid ->
          {:error, :invalid_hot_response}
      end
    rescue
      exception -> {:error, exception}
    catch
      :exit, reason -> {:error, reason}
    end

    defp parse_positive_id(value) do
      case Integer.parse(value) do
        {id, ""} when id > 0 -> id
        _invalid -> nil
      end
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
        min_age: xpath(item, ~x"./minage/@value"Io),
        complexity: xpath(item, ~x"./statistics/ratings/averageweight/@value"Fo),
        rating: xpath(item, ~x"./statistics/ratings/average/@value"Fo)
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
