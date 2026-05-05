defmodule D20.Dice do
  @moduledoc """
  Shared dice roller for game engines.
  """

  @sides %{
    d4: 4,
    d6: 6,
    d8: 8,
    d10: 10,
    d12: 12,
    d20: 20,
    d100: 100
  }

  defguardp is_die(die) when die in [:d4, :d6, :d8, :d10, :d12, :d20, :d100]
  defguardp is_count(count) when is_integer(count) and count > 0

  @type die :: :d4 | :d6 | :d8 | :d10 | :d12 | :d20 | :d100
  @type roll_set :: [{die(), pos_integer()}]
  @type result :: %{
          required(:sum) => non_neg_integer(),
          optional(die()) => [pos_integer()]
        }
  @type reason :: :invalid_count | :invalid_die | :invalid_set

  @spec roll(roll_set()) :: {:ok, result()} | {:error, reason()}
  def roll(roll_set) when is_list(roll_set), do: roll_set(roll_set)
  def roll(_roll_set), do: {:error, :invalid_set}

  @spec roll!(roll_set()) :: result()
  def roll!(roll_set) do
    case roll(roll_set) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, "invalid dice roll: #{inspect(reason)}"
    end
  end

  defp roll_set([]), do: {:error, :invalid_set}

  defp roll_set(roll_set) do
    Enum.reduce_while(roll_set, {:ok, %{sum: 0}}, fn
      {die, count}, {:ok, result} when is_die(die) and is_count(count) ->
        if Map.has_key?(result, die) do
          {:halt, {:error, :invalid_set}}
        else
          values = roll_values(die, count)

          result =
            result
            |> Map.put(die, values)
            |> Map.update!(:sum, &(&1 + Enum.sum(values)))

          {:cont, {:ok, result}}
        end

      {die, _count}, _acc when not is_die(die) ->
        {:halt, {:error, :invalid_die}}

      {_die, count}, _acc when not is_count(count) ->
        {:halt, {:error, :invalid_count}}

      _entry, _acc ->
        {:halt, {:error, :invalid_set}}
    end)
  end

  defp roll_values(die, count) do
    sides = Map.fetch!(@sides, die)

    Enum.map(1..count, fn _die -> :crypto.strong_rand_range(sides) + 1 end)
  end
end
