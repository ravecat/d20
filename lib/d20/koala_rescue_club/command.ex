defmodule D20.KoalaRescueClub.Command do
  @moduledoc """
  Koala Rescue Club command payload validation.
  """

  import Ecto.Changeset

  alias D20.KoalaRescueClub.Ruleset
  alias Ecto.Changeset

  @areas ~w(a b c d e f g)a
  @bonus_axes ~w(row column)a
  @hospital_ids ~w(hospital_1_left hospital_1_right hospital_2 hospital_3 hospital_4)a

  @type reason :: Changeset.t() | :unknown_command

  @spec validate(D20.Command.t()) :: {:ok, D20.Command.t()} | {:error, reason()}
  def validate(%D20.Command{event: "join"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "roll"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "start"} = command), do: {:ok, command}

  def validate(%D20.Command{event: "select", attrs: attrs} = command) do
    types = %{
      mark: Ecto.ParameterizedType.init(Ecto.Enum, values: Ruleset.marks()),
      die_value: :integer,
      target_cell: :map
    }

    changeset =
      {%{}, types}
      |> cast(attrs || %{}, Map.keys(types))
      |> validate_required([:target_cell])
      |> validate_selection_context()
      |> validate_number(:die_value, greater_than_or_equal_to: 1, less_than_or_equal_to: 6)
      |> reject_selection_field(attrs, :action)
      |> reject_selection_field(attrs, :volunteers_used)

    case apply_action(changeset, :turn_selection) do
      {:ok, %{target_cell: cell} = attrs} ->
        case normalize_cell(cell) do
          {:ok, cell} -> {:ok, %{command | attrs: Map.put(attrs, :target_cell, cell)}}
          :error -> invalid_selection(changeset)
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def validate(%D20.Command{event: "deselect", attrs: attrs} = command) do
    changeset =
      {%{}, %{target_cell: :map}}
      |> cast(attrs || %{}, [:target_cell])
      |> validate_required([:target_cell])

    case apply_action(changeset, :turn_selection) do
      {:ok, %{target_cell: cell}} ->
        case normalize_cell(cell) do
          {:ok, cell} -> {:ok, %{command | attrs: %{target_cell: cell}}}
          :error -> invalid_selection(changeset)
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def validate(%D20.Command{event: "reset", attrs: attrs} = command)
      when attrs == %{} or is_nil(attrs),
      do: {:ok, %{command | attrs: %{}}}

  def validate(%D20.Command{event: "reset"} = command) do
    {%{}, %{event: :string, attrs: :map}}
    |> cast(Map.from_struct(command), [:event, :attrs])
    |> add_error(:attrs, "must be empty")
    |> apply_action(:turn_selection)
  end

  def validate(%D20.Command{event: "submit", attrs: attrs} = command) do
    changeset =
      {%{}, %{bonus_actions: {:array, :map}}}
      |> cast(attrs || %{}, [:bonus_actions])
      |> require_bonus_actions(attrs)

    case apply_action(changeset, :turn_selection) do
      {:ok, attrs} ->
        case normalize_bonus_actions(Map.get(attrs, :bonus_actions, [])) do
          {:ok, bonus_actions} -> {:ok, %{command | attrs: %{bonus_actions: bonus_actions}}}
          :error -> invalid_selection(changeset)
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def validate(%D20.Command{}), do: {:error, :unknown_command}

  defp validate_selection_context(changeset) do
    fields = [:mark, :die_value]

    if Enum.any?(fields, &field_present?(changeset, &1)) do
      validate_required(changeset, fields)
    else
      changeset
    end
  end

  defp field_present?(changeset, field) do
    not is_nil(get_field(changeset, field))
  end

  defp reject_selection_field(changeset, attrs, field) when is_map(attrs) do
    if Map.has_key?(attrs, field) or Map.has_key?(attrs, Atom.to_string(field)) do
      add_error(changeset, field, "is not accepted")
    else
      changeset
    end
  end

  defp reject_selection_field(changeset, _attrs, _field), do: changeset

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

  defp invalid_selection(changeset) do
    changeset |> add_error(:attrs, "is invalid") |> apply_action(:turn_selection)
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
