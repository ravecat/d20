defmodule D20.Form do
  @moduledoc """
  Serializes Ecto changesets into JSON-safe form data for Inertia clients.
  """

  @spec to_form(Ecto.Changeset.t()) :: map()
  def to_form(%Ecto.Changeset{} = changeset) do
    form = Phoenix.Component.to_form(changeset, as: :attrs)

    changeset.types
    |> Enum.map(fn {field, type} -> {field, field_form(form[field], changeset, field, type)} end)
    |> Map.new()
  end

  defp field_form(input, changeset, field, {:parameterized, {Ecto.Enum, %{mappings: mappings}}}) do
    %{
      id: input.id,
      name: Atom.to_string(field),
      type: "enum",
      value: serialize_enum_value(input.value, mappings),
      required: field in changeset.required,
      values: Enum.map(mappings, fn {_key, value} -> value end),
      errors: field_errors(input.errors)
    }
  end

  defp field_form(input, changeset, field, type) do
    %{
      id: input.id,
      name: Atom.to_string(field),
      type: field_type(type),
      value: serialize_value(input.value),
      required: field in changeset.required,
      errors: field_errors(input.errors)
    }
  end

  defp field_type(:boolean), do: "boolean"
  defp field_type(:integer), do: "integer"
  defp field_type(:float), do: "number"
  defp field_type(:decimal), do: "number"
  defp field_type({:array, _type}), do: "array"
  defp field_type(_type), do: "string"

  defp serialize_enum_value(value, mappings) when is_atom(value) do
    Keyword.get(mappings, value, Atom.to_string(value))
  end

  defp serialize_enum_value(value, _mappings), do: serialize_value(value)

  defp serialize_value(nil), do: nil
  defp serialize_value(value) when is_boolean(value), do: value
  defp serialize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp serialize_value(%Decimal{} = value), do: Decimal.to_string(value)
  defp serialize_value(value) when is_binary(value), do: value
  defp serialize_value(value) when is_integer(value), do: value
  defp serialize_value(value) when is_float(value), do: value
  defp serialize_value(value), do: to_string(value)

  defp field_errors(errors) do
    Enum.map(errors, fn
      {message, _opts} -> message
      message -> to_string(message)
    end)
  end
end
