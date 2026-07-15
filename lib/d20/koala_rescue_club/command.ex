defmodule D20.KoalaRescueClub.Command do
  @moduledoc """
  Koala Rescue Club command payload validation.
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @areas ~w(a b c d e f g)a
  @bonus_axes ~w(row column)a
  @hospital_ids ~w(hospital_1_left hospital_1_right hospital_2 hospital_3 hospital_4)a
  @shape_actions ~w(plant_trees rehome_koalas)

  @type reason :: Changeset.t() | :unknown_command

  @spec validate(D20.Command.t()) :: {:ok, D20.Command.t()} | {:error, reason()}
  def validate(%D20.Command{event: "join"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "roll"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "start"} = command), do: {:ok, command}

  def validate(%D20.Command{event: event, attrs: attrs} = command)
      when event in ["project_turn_selection", "submit_turn_selection"] do
    types = %{
      action: :string,
      die_value: :integer,
      volunteers_used: :integer,
      selected_cells: {:array, :map},
      bonus_actions: {:array, :map}
    }

    fields =
      if event == "submit_turn_selection",
        do: Map.keys(types),
        else: [:action, :die_value, :volunteers_used, :selected_cells]

    changeset =
      {%{}, types}
      |> cast(attrs || %{}, fields)
      |> validate_required([:action, :die_value, :volunteers_used, :selected_cells])
      |> require_submit_bonus_actions(event, attrs)
      |> validate_inclusion(:action, @shape_actions)
      |> validate_number(:die_value, greater_than_or_equal_to: 1, less_than_or_equal_to: 6)
      |> validate_number(:volunteers_used, greater_than_or_equal_to: 0)

    case apply_action(changeset, :turn_selection) do
      {:ok, attrs} -> normalize_shape_selection(command, attrs, changeset)
      {:error, changeset} -> {:error, changeset}
    end
  end

  def validate(%D20.Command{event: event, attrs: attrs} = command)
      when event in ["circle_tree", "circle_koala"] do
    changeset =
      {%{},
       %{
         die_value: :integer,
         volunteers_used: :integer,
         target_cell: :map,
         bonus_actions: {:array, :map}
       }}
      |> cast(attrs, [:die_value, :volunteers_used, :target_cell, :bonus_actions])
      |> validate_required([:die_value, :volunteers_used, :target_cell])
      |> validate_number(:die_value, greater_than_or_equal_to: 1, less_than_or_equal_to: 6)
      |> validate_number(:volunteers_used, greater_than_or_equal_to: 0)

    case apply_action(changeset, :turn_action) do
      {:ok, attrs} ->
        case normalize_turn_command(command, attrs) do
          {:ok, command} -> {:ok, command}
          :error -> changeset |> add_error(:attrs, "is invalid") |> apply_action(:turn_action)
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def validate(%D20.Command{}), do: {:error, :unknown_command}

  defp normalize_shape_selection(command, attrs, changeset) do
    with {:ok, selected_cells} <- normalize_cells(attrs.selected_cells),
         {:ok, bonus_actions} <- normalize_selection_bonus_actions(command.event, attrs) do
      normalized = %{
        action: attrs.action,
        die_value: attrs.die_value,
        volunteers_used: attrs.volunteers_used,
        selected_cells: selected_cells
      }

      normalized =
        if command.event == "submit_turn_selection",
          do: Map.put(normalized, :bonus_actions, bonus_actions),
          else: normalized

      {:ok, %{command | attrs: normalized}}
    else
      :error -> changeset |> add_error(:attrs, "is invalid") |> apply_action(:turn_selection)
    end
  end

  defp normalize_selection_bonus_actions("submit_turn_selection", attrs) do
    normalize_bonus_actions(Map.get(attrs, :bonus_actions, []))
  end

  defp normalize_selection_bonus_actions("project_turn_selection", _attrs), do: {:ok, []}

  defp require_submit_bonus_actions(changeset, "submit_turn_selection", attrs)
       when is_map(attrs) do
    if Map.has_key?(attrs, :bonus_actions) or Map.has_key?(attrs, "bonus_actions") do
      changeset
    else
      add_error(changeset, :bonus_actions, "can't be blank")
    end
  end

  defp require_submit_bonus_actions(changeset, "submit_turn_selection", _attrs) do
    add_error(changeset, :bonus_actions, "can't be blank")
  end

  defp require_submit_bonus_actions(changeset, "project_turn_selection", _attrs), do: changeset

  defp normalize_turn_command(command, attrs) do
    with {:ok, target_cells} <- normalize_target_cells(attrs),
         {:ok, bonus_actions} <- normalize_bonus_actions(Map.get(attrs, :bonus_actions, [])) do
      {:ok,
       %{
         command
         | attrs:
             Map.merge(
               %{
                 die_value: attrs.die_value,
                 volunteers_used: attrs.volunteers_used,
                 bonus_actions: bonus_actions
               },
               target_cells
             )
       }}
    end
  end

  defp normalize_target_cells(%{target_cell: cell}) do
    with {:ok, cell} <- normalize_cell(cell) do
      {:ok, %{target_cell: cell}}
    end
  end

  defp normalize_cells(cells) when is_list(cells) do
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

  defp normalize_cells(_cells), do: :error

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
    with {:ok, hospital_id} <- fetch_hospital_id(attrs, :hospital_id) do
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

  defp fetch_hospital_id(attrs, key) do
    case fetch_value(attrs, key) do
      hospital_id when is_atom(hospital_id) and hospital_id in @hospital_ids -> {:ok, hospital_id}
      hospital_id when is_binary(hospital_id) -> normalize_hospital_id(hospital_id)
      _value -> :error
    end
  end

  defp normalize_hospital_id(hospital_id) do
    Enum.find_value(@hospital_ids, :error, fn id ->
      if Atom.to_string(id) == hospital_id, do: {:ok, id}
    end)
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
