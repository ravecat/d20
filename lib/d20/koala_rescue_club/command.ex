defmodule D20.KoalaRescueClub.Command do
  @moduledoc """
  Koala Rescue Club command payload validation.
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @areas ~w(a b c d e f g)a
  @bonus_axes ~w(row column)a
  @hospital_ids ~w(hospital_1_left hospital_1_right hospital_2 hospital_3 hospital_4)a

  @type reason :: Changeset.t() | :unknown_command | :invalid_command

  @spec validate(D20.Command.t()) :: {:ok, D20.Command.t()} | {:error, reason()}
  def validate(%D20.Command{event: "join"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "start", attrs: attrs} = command)
      when attrs == %{} or attrs == nil,
      do: {:ok, %{command | attrs: %{}}}

  def validate(%D20.Command{event: "start"}), do: {:error, :invalid_command}

  def validate(%D20.Command{event: "roll"} = command), do: {:ok, %{command | attrs: %{}}}

  def validate(%D20.Command{event: event, attrs: attrs} = command)
      when event in ["plant_trees", "rehome_koalas"] do
    case {%{},
          %{
            die_value: :integer,
            volunteers_used: :integer,
            target_cells: {:array, :map},
            bonus_actions: {:array, :map}
          }}
         |> cast(attrs, [:die_value, :volunteers_used, :target_cells, :bonus_actions])
         |> validate_required([:die_value, :volunteers_used, :target_cells])
         |> validate_number(:die_value, greater_than_or_equal_to: 1, less_than_or_equal_to: 6)
         |> validate_number(:volunteers_used, greater_than_or_equal_to: 0)
         |> validate_length(:target_cells, min: 1)
         |> apply_action(:turn_action) do
      {:ok, attrs} -> normalize_turn_command(command, attrs)
      {:error, changeset} -> {:error, changeset}
    end
  end

  def validate(%D20.Command{event: event, attrs: attrs} = command)
      when event in ["circle_tree", "circle_koala"] do
    case {%{},
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
         |> apply_action(:turn_action) do
      {:ok, attrs} -> normalize_turn_command(command, attrs)
      {:error, changeset} -> {:error, changeset}
    end
  end

  def validate(%D20.Command{}), do: {:error, :unknown_command}

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

  defp normalize_target_cells(%{target_cells: cells}) do
    cells
    |> normalize_cells()
    |> case do
      {:ok, cells} -> {:ok, %{target_cells: cells}}
      {:error, reason} -> {:error, reason}
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
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, cells} -> {:ok, Enum.reverse(cells)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_cells(_cells), do: {:error, :invalid_command}

  defp normalize_cell(attrs) when is_map(attrs) do
    with {:ok, area} <- fetch_area(attrs, :area),
         {:ok, row} <- fetch_non_neg_integer(attrs, :row),
         {:ok, column} <- fetch_non_neg_integer(attrs, :column) do
      {:ok, %{area: area, row: row, column: column}}
    end
  end

  defp normalize_cell(_attrs), do: {:error, :invalid_command}

  defp normalize_bonus_actions(actions) when is_list(actions) do
    Enum.reduce_while(actions, {:ok, []}, fn action, {:ok, actions} ->
      case normalize_bonus_action(action) do
        {:ok, action} -> {:cont, {:ok, [action | actions]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, actions} -> {:ok, Enum.reverse(actions)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_bonus_actions(_actions), do: {:error, :invalid_command}

  defp normalize_bonus_action(attrs) when is_map(attrs) do
    with {:ok, bonus} <- fetch_bonus_ref(attrs, :bonus),
         {:ok, action_attrs} <- fetch_map(attrs, :action),
         {:ok, kind} <- fetch_string(action_attrs, :kind),
         {:ok, action} <- normalize_bonus_action_kind(kind, action_attrs) do
      {:ok, %{bonus: bonus, action: action}}
    end
  end

  defp normalize_bonus_action(_attrs), do: {:error, :invalid_command}

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

  defp normalize_bonus_action_kind(_kind, _attrs), do: {:error, :invalid_command}

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
      _value -> {:error, :invalid_command}
    end
  end

  defp normalize_area(area) do
    Enum.find_value(@areas, {:error, :invalid_command}, fn id ->
      if Atom.to_string(id) == area, do: {:ok, id}
    end)
  end

  defp fetch_axis(attrs, key) do
    case fetch_value(attrs, key) do
      axis when is_atom(axis) and axis in @bonus_axes -> {:ok, axis}
      axis when is_binary(axis) -> normalize_axis(axis)
      _value -> {:error, :invalid_command}
    end
  end

  defp normalize_axis(axis) do
    Enum.find_value(@bonus_axes, {:error, :invalid_command}, fn id ->
      if Atom.to_string(id) == axis, do: {:ok, id}
    end)
  end

  defp fetch_hospital_id(attrs, key) do
    case fetch_value(attrs, key) do
      hospital_id when is_atom(hospital_id) and hospital_id in @hospital_ids -> {:ok, hospital_id}
      hospital_id when is_binary(hospital_id) -> normalize_hospital_id(hospital_id)
      _value -> {:error, :invalid_command}
    end
  end

  defp normalize_hospital_id(hospital_id) do
    Enum.find_value(@hospital_ids, {:error, :invalid_command}, fn id ->
      if Atom.to_string(id) == hospital_id, do: {:ok, id}
    end)
  end

  defp fetch_non_neg_integer(attrs, key) do
    case fetch_value(attrs, key) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _value -> {:error, :invalid_command}
    end
  end

  defp fetch_string(attrs, key) do
    case fetch_value(attrs, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _value -> {:error, :invalid_command}
    end
  end

  defp fetch_map(attrs, key) do
    case fetch_value(attrs, key) do
      value when is_map(value) -> {:ok, value}
      _value -> {:error, :invalid_command}
    end
  end

  defp fetch_value(attrs, key) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end
end
