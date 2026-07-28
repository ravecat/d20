defmodule D20.KoalaRescueClub.Command do
  @moduledoc """
  Koala Rescue Club command payload validation.
  """

  import Ecto.Changeset

  alias D20.KoalaRescueClub.Ruleset
  alias Ecto.Changeset

  @areas ~w(a b c d e f g)a
  @bonus_axes ~w(row column)a

  @type reason :: Changeset.t() | :unknown_command

  @spec validate(D20.Command.t()) :: {:ok, D20.Command.t()} | {:error, reason()}
  def validate(%D20.Command{event: "join"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "roll"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "start"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "draft"} = command) do
    validate_candidate(command, :draft, false)
  end

  def validate(%D20.Command{event: "submit"} = command) do
    validate_candidate(command, :submit, true)
  end

  def validate(%D20.Command{}), do: {:error, :unknown_command}

  defp validate_candidate(%D20.Command{attrs: attrs} = command, action, include_bonuses?) do
    types = %{
      mark: Ecto.ParameterizedType.init(Ecto.Enum, values: Ruleset.marks()),
      die_value: :integer,
      selected_cells: {:array, :map},
      bonus_actions: {:array, :map}
    }

    fields = if include_bonuses?, do: Map.keys(types), else: [:mark, :die_value, :selected_cells]
    required = if include_bonuses?, do: fields, else: [:mark, :die_value, :selected_cells]

    changeset =
      {%{}, types}
      |> cast(attrs || %{}, fields)
      |> validate_required(required)
      |> validate_number(:die_value, greater_than_or_equal_to: 1, less_than_or_equal_to: 6)
      |> validate_length(:selected_cells, min: 1)
      |> then(fn changeset ->
        if include_bonuses?, do: require_bonus_actions(changeset, attrs), else: changeset
      end)

    with {:ok, normalized} <- apply_action(changeset, action),
         {:ok, selected_cells} <- normalize_cells(normalized.selected_cells),
         {:ok, bonus_actions} <- normalize_candidate_bonus_actions(normalized, include_bonuses?) do
      attrs =
        normalized
        |> Map.take([:mark, :die_value])
        |> Map.put(:selected_cells, selected_cells)
        |> maybe_put_bonus_actions(bonus_actions, include_bonuses?)

      {:ok, %{command | attrs: attrs}}
    else
      {:error, %Changeset{} = changeset} -> {:error, changeset}
      :error -> invalid_payload(changeset, action)
    end
  end

  defp normalize_cells(cells) when is_list(cells) do
    with {:ok, cells} <- normalize_cell_list(cells),
         true <- Enum.uniq(cells) == cells do
      {:ok, cells}
    else
      _reason -> :error
    end
  end

  defp normalize_cells(_cells), do: :error

  defp normalize_cell_list(cells) do
    Enum.reduce_while(cells, {:ok, []}, fn cell, {:ok, cells} ->
      case normalize_cell(cell) do
        {:ok, cell} -> {:cont, {:ok, [cell | cells]}}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      {:ok, cells} -> {:ok, Enum.reverse(cells)}
      :error -> :error
    end
  end

  defp normalize_candidate_bonus_actions(_attrs, false), do: {:ok, []}

  defp normalize_candidate_bonus_actions(attrs, true) do
    normalize_bonus_actions(Map.get(attrs, :bonus_actions, []))
  end

  defp maybe_put_bonus_actions(attrs, _bonus_actions, false), do: attrs

  defp maybe_put_bonus_actions(attrs, bonus_actions, true),
    do: Map.put(attrs, :bonus_actions, bonus_actions)

  defp require_bonus_actions(changeset, attrs) when is_map(attrs) do
    if Map.has_key?(attrs, :bonus_actions) or Map.has_key?(attrs, "bonus_actions") do
      changeset
    else
      add_error(changeset, :bonus_actions, "can't be blank")
    end
  end

  defp require_bonus_actions(changeset, _attrs) do
    add_error(changeset, :bonus_actions, "can't be blank")
  end

  defp invalid_payload(changeset, action) do
    changeset |> add_error(:attrs, "is invalid") |> apply_action(action)
  end

  defp normalize_cell(attrs) when is_map(attrs) do
    with {:ok, area} <- fetch_area(attrs, :area),
         {:ok, row} <- fetch_non_neg_integer(attrs, :row),
         {:ok, column} <- fetch_non_neg_integer(attrs, :column) do
      {:ok, %{area: area, row: row, column: column}}
    end
  end

  defp normalize_cell(_attrs), do: :error

  defp normalize_bonus_actions(actions) when is_list(actions) do
    Enum.reduce_while(actions, {:ok, []}, fn action, {:ok, actions} ->
      case normalize_bonus_action(action) do
        {:ok, action} -> {:cont, {:ok, [action | actions]}}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      {:ok, actions} -> {:ok, Enum.reverse(actions)}
      :error -> :error
    end
  end

  defp normalize_bonus_actions(_actions), do: :error

  defp normalize_bonus_action(attrs) when is_map(attrs) do
    with {:ok, bonus} <- fetch_bonus_ref(attrs, :bonus),
         {:ok, action_attrs} <- fetch_map(attrs, :action),
         {:ok, kind} <- fetch_string(action_attrs, :kind),
         {:ok, action} <- normalize_bonus_action_kind(kind, action_attrs) do
      {:ok, %{bonus: bonus, action: action}}
    end
  end

  defp normalize_bonus_action(_attrs), do: :error

  defp normalize_bonus_action_kind("tree", attrs) do
    with {:ok, target_cell} <- fetch_cell(attrs, :target_cell) do
      {:ok, %{kind: :tree, target_cell: target_cell}}
    end
  end

  defp normalize_bonus_action_kind("koala", attrs) do
    with {:ok, target_cell} <- fetch_cell(attrs, :target_cell) do
      {:ok, %{kind: :koala, target_cell: target_cell}}
    end
  end

  defp normalize_bonus_action_kind("volunteer", _attrs), do: {:ok, %{kind: :volunteer}}

  defp normalize_bonus_action_kind("hospital", attrs) do
    with {:ok, hospital_id} <- fetch_string(attrs, :hospital_id) do
      {:ok, %{kind: :hospital, hospital_id: hospital_id}}
    end
  end

  defp normalize_bonus_action_kind("skybridge", attrs) do
    with {:ok, to} <- fetch_area(attrs, :to) do
      {:ok, %{kind: :skybridge, to: to}}
    end
  end

  defp normalize_bonus_action_kind("skip", _attrs), do: {:ok, %{kind: :skip}}

  defp normalize_bonus_action_kind(_kind, _attrs), do: :error

  defp fetch_bonus_ref(attrs, key) do
    with {:ok, attrs} <- fetch_map(attrs, key),
         {:ok, area} <- fetch_area(attrs, :area),
         {:ok, axis} <- fetch_axis(attrs, :axis),
         {:ok, index} <- fetch_non_neg_integer(attrs, :index) do
      {:ok, %{area: area, axis: axis, index: index}}
    end
  end

  defp fetch_cell(attrs, key) do
    with {:ok, attrs} <- fetch_map(attrs, key) do
      normalize_cell(attrs)
    end
  end

  defp fetch_area(attrs, key) do
    case fetch_value(attrs, key) do
      area when is_atom(area) and area in @areas -> {:ok, area}
      area when is_binary(area) -> normalize_area(area)
      _value -> :error
    end
  end

  defp normalize_area(area) do
    Enum.find_value(@areas, :error, fn id -> if Atom.to_string(id) == area, do: {:ok, id} end)
  end

  defp fetch_axis(attrs, key) do
    case fetch_value(attrs, key) do
      axis when is_atom(axis) and axis in @bonus_axes -> {:ok, axis}
      axis when is_binary(axis) -> normalize_axis(axis)
      _value -> :error
    end
  end

  defp normalize_axis(axis) do
    Enum.find_value(@bonus_axes, :error, fn id -> if Atom.to_string(id) == axis, do: {:ok, id} end)
  end

  defp fetch_non_neg_integer(attrs, key) do
    case fetch_value(attrs, key) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _value -> :error
    end
  end

  defp fetch_string(attrs, key) do
    case fetch_value(attrs, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _value -> :error
    end
  end

  defp fetch_map(attrs, key) do
    case fetch_value(attrs, key) do
      value when is_map(value) -> {:ok, value}
      _value -> :error
    end
  end

  defp fetch_value(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end
