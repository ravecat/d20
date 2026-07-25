defmodule D20.NextStationLondon.Command do
  @moduledoc """
  Structural validation and finite normalization for Next Station: London commands.
  """

  alias D20.NextStationLondon.Ruleset

  @simple_events ["join", "left"]
  @prepare_keys [:deck, :pencil_cycle, :pencil_offsets, :objectives, :powers]
  @draw_keys [:sections, :power, :chosen_symbol, :power_target]
  @pass_keys [:power, :power_target]

  @type reason :: :invalid_command | :unknown_command

  @spec validate(D20.Command.t()) :: {:ok, D20.Command.t()} | {:error, reason()}
  def validate(%D20.Command{event: event} = command) when event in @simple_events do
    {:ok, %{command | attrs: %{}}}
  end

  def validate(%D20.Command{event: "start", attrs: attrs} = command) do
    with {:ok, attrs} <- normalize_map(attrs),
         :ok <- require_known_keys(attrs, []) do
      {:ok, %{command | attrs: %{}}}
    else
      _error -> {:error, :invalid_command}
    end
  end

  def validate(%D20.Command{event: "prepare_round", attrs: attrs} = command) do
    with {:ok, attrs} <- normalize_map(attrs),
         :ok <- require_known_keys(attrs, @prepare_keys),
         {:ok, deck} <- required_list(attrs, :deck, &normalize_card_id/1),
         {:ok, pencil_cycle} <- optional_list(attrs, :pencil_cycle, &normalize_color/1),
         {:ok, pencil_offsets} <- optional_map(attrs, :pencil_offsets, &normalize_offsets/1),
         {:ok, objectives} <- optional_list(attrs, :objectives, &normalize_objective/1),
         {:ok, powers} <- optional_map(attrs, :powers, &normalize_powers/1) do
      normalized = %{
        deck: deck,
        pencil_cycle: pencil_cycle,
        pencil_offsets: pencil_offsets,
        objectives: objectives,
        powers: powers
      }

      {:ok, %{command | attrs: normalized}}
    else
      _error -> {:error, :invalid_command}
    end
  end

  def validate(%D20.Command{event: "draw_sections", attrs: attrs} = command) do
    with {:ok, attrs} <- normalize_map(attrs),
         :ok <- require_known_keys(attrs, @draw_keys),
         {:ok, sections} <- required_list(attrs, :sections, &normalize_section/1),
         true <- length(sections) in 1..2,
         {:ok, power} <- optional_value(attrs, :power, &normalize_power/1),
         {:ok, chosen_symbol} <- optional_value(attrs, :chosen_symbol, &normalize_symbol/1),
         {:ok, power_target} <- optional_value(attrs, :power_target, &normalize_station_id/1) do
      normalized = %{
        sections: sections,
        power: power,
        chosen_symbol: chosen_symbol,
        power_target: power_target
      }

      {:ok, %{command | attrs: normalized}}
    else
      _error -> {:error, :invalid_command}
    end
  end

  def validate(%D20.Command{event: "pass", attrs: attrs} = command) do
    with {:ok, attrs} <- normalize_map(attrs),
         :ok <- require_known_keys(attrs, @pass_keys),
         {:ok, power} <- optional_value(attrs, :power, &normalize_power/1),
         {:ok, power_target} <- optional_value(attrs, :power_target, &normalize_station_id/1) do
      {:ok, %{command | attrs: %{power: power, power_target: power_target}}}
    else
      _error -> {:error, :invalid_command}
    end
  end

  def validate(%D20.Command{}), do: {:error, :unknown_command}

  defp normalize_map(nil), do: {:ok, %{}}
  defp normalize_map(attrs) when is_map(attrs), do: {:ok, attrs}
  defp normalize_map(_attrs), do: :error

  defp require_known_keys(attrs, keys) do
    allowed = keys |> Enum.flat_map(&[&1, Atom.to_string(&1)]) |> MapSet.new()

    if Enum.all?(Map.keys(attrs), &MapSet.member?(allowed, &1)), do: :ok, else: :error
  end

  defp required_list(attrs, key, normalize) do
    case fetch(attrs, key) do
      :missing -> :error
      {:ok, value} -> normalize_list(value, normalize)
    end
  end

  defp optional_list(attrs, key, normalize) do
    case fetch(attrs, key) do
      :missing -> {:ok, nil}
      {:ok, value} -> normalize_list(value, normalize)
    end
  end

  defp normalize_list(values, normalize) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, normalized} ->
      case normalize.(value) do
        {:ok, value} -> {:cont, {:ok, [value | normalized]}}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      :error -> :error
    end
  end

  defp normalize_list(_values, _normalize), do: :error

  defp optional_value(attrs, key, normalize) do
    case fetch(attrs, key) do
      :missing -> {:ok, nil}
      {:ok, nil} -> {:ok, nil}
      {:ok, value} -> normalize.(value)
    end
  end

  defp optional_map(attrs, key, normalize) do
    case fetch(attrs, key) do
      :missing -> {:ok, nil}
      {:ok, value} when is_map(value) -> normalize.(value)
      {:ok, _value} -> :error
    end
  end

  defp normalize_section(attrs) when is_map(attrs) do
    with :ok <- require_known_keys(attrs, [:from, :to]),
         {:ok, from} <- fetch_and_normalize(attrs, :from, &normalize_station_id/1),
         {:ok, to} <- fetch_and_normalize(attrs, :to, &normalize_station_id/1),
         true <- from != to do
      {:ok, %{from: from, to: to}}
    else
      _error -> :error
    end
  end

  defp normalize_section(_attrs), do: :error

  defp normalize_offsets(offsets) do
    Enum.reduce_while(offsets, {:ok, %{}}, fn
      {player_id, offset}, {:ok, normalized}
      when is_binary(player_id) and player_id != "" and is_integer(offset) and offset in 0..3 ->
        {:cont, {:ok, Map.put(normalized, player_id, offset)}}

      _entry, _acc ->
        {:halt, :error}
    end)
  end

  defp normalize_powers(powers) do
    Enum.reduce_while(powers, {:ok, %{}}, fn {color, power}, {:ok, normalized} ->
      with {:ok, color} <- normalize_color(color), {:ok, power} <- normalize_power(power) do
        {:cont, {:ok, Map.put(normalized, color, power)}}
      else
        _error -> {:halt, :error}
      end
    end)
  end

  defp normalize_station_id(id) when is_binary(id) do
    case Ruleset.fetch_station(id) do
      {:ok, _station} -> {:ok, id}
      :error -> :error
    end
  end

  defp normalize_station_id(_id), do: :error

  defp normalize_card_id(id) when is_binary(id) do
    case Ruleset.fetch_card(id) do
      {:ok, _card} -> {:ok, id}
      :error -> :error
    end
  end

  defp normalize_card_id(_id), do: :error

  defp normalize_color(value), do: normalize_enum(value, Ruleset.colors())
  defp normalize_symbol(value), do: normalize_enum(value, Ruleset.ordinary_symbols())
  defp normalize_objective(value), do: normalize_enum(value, Ruleset.objective_ids())
  defp normalize_power(value), do: normalize_enum(value, Ruleset.power_ids())

  defp normalize_enum(value, allowed) when is_atom(value) do
    if value in allowed, do: {:ok, value}, else: :error
  end

  defp normalize_enum(value, allowed) when is_binary(value) do
    Enum.find_value(allowed, :error, fn item ->
      if Atom.to_string(item) == value, do: {:ok, item}
    end)
  end

  defp normalize_enum(_value, _allowed), do: :error

  defp fetch_and_normalize(attrs, key, normalize) do
    case fetch(attrs, key) do
      {:ok, value} -> normalize.(value)
      :missing -> :error
    end
  end

  defp fetch(attrs, key) do
    cond do
      Map.has_key?(attrs, key) -> {:ok, Map.fetch!(attrs, key)}
      Map.has_key?(attrs, Atom.to_string(key)) -> {:ok, Map.fetch!(attrs, Atom.to_string(key))}
      true -> :missing
    end
  end
end
