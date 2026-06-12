defmodule D20.Qwinto.Command do
  @moduledoc """
  Qwinto command payload validation.
  """

  import Ecto.Changeset

  alias D20.Qwinto.Ruleset
  alias Ecto.Changeset

  @colors Ruleset.colors()
  @dice_count_range Ruleset.dice_count_range()
  @slot_range Ruleset.slot_range()

  @type reason :: Changeset.t() | :unknown_command

  @spec validate(D20.Command.t()) :: {:ok, D20.Command.t()} | {:error, reason()}
  def validate(%D20.Command{event: "join"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "start"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "roll", attrs: attrs} = command) do
    color_type = Ecto.ParameterizedType.init(Ecto.Enum, values: @colors)

    case {%{}, %{colors: {:array, color_type}}}
         |> cast(attrs, [:colors])
         |> validate_required([:colors])
         |> validate_length(:colors,
           min: Enum.min(@dice_count_range),
           max: Enum.max(@dice_count_range)
         )
         |> validate_change(:colors, fn :colors, colors ->
           if Enum.uniq(colors) == colors, do: [], else: [colors: "has duplicate colors"]
         end)
         |> apply_action(:roll) do
      {:ok, attrs} -> {:ok, %{command | attrs: attrs}}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def validate(%D20.Command{event: "write", attrs: attrs} = command) do
    color_type = Ecto.ParameterizedType.init(Ecto.Enum, values: @colors)

    case {%{}, %{row: color_type, slot: :integer}}
         |> cast(attrs, [:row, :slot])
         |> validate_required([:row, :slot])
         |> validate_number(:slot,
           greater_than_or_equal_to: Enum.min(@slot_range),
           less_than_or_equal_to: Enum.max(@slot_range)
         )
         |> apply_action(:write) do
      {:ok, attrs} -> {:ok, %{command | attrs: attrs}}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def validate(%D20.Command{event: event} = command)
      when event in ["reroll", "pass", "penalize"],
      do: {:ok, command}

  def validate(%D20.Command{}), do: {:error, :unknown_command}
end
