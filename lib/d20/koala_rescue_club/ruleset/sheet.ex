defmodule D20.KoalaRescueClub.Ruleset.Sheet do
  @moduledoc """
  Koala Rescue Club sheet contract and geometry builder.
  """

  defstruct [
    :volunteers,
    :solo_ratings,
    :areas,
    :cells,
    :rows,
    :columns,
    :bonuses,
    :hospitals,
    :skybridges,
    :badges
  ]

  @type t :: %__MODULE__{
          volunteers: non_neg_integer(),
          solo_ratings: keyword(Range.t()),
          areas: map(),
          cells: map(),
          rows: map(),
          columns: map(),
          bonuses: map(),
          hospitals: map(),
          skybridges: map(),
          badges: %{optional(atom()) => map()}
        }
  @type bonus_kind :: :tree | :koala | :volunteer | :hospital | :skybridge
  @type area :: {atom(), map()}
  @type badge :: {atom(), map()}
  @type bonus_spec ::
          bonus_kind()
          | {bonus_kind(), String.t()}
          | {:skybridge, atom()}
          | {:skybridge, atom(), atom()}
          | nil
  @type hospital :: {atom(), map()}
  @type skybridge :: %{required(:from) => atom(), required(:to) => atom()}
  @type init :: %{
          required(:volunteers) => non_neg_integer(),
          required(:solo_ratings) => keyword(Range.t()),
          required(:areas) => [area()],
          required(:hospitals) => [hospital()],
          required(:skybridges) => [skybridge()],
          required(:badges) => [badge()]
        }

  @callback init() :: init()

  @spec from_module(module()) :: t()
  def from_module(module), do: build(module.init())

  @spec build(init()) :: t()
  def build(%{
        volunteers: volunteers,
        solo_ratings: solo_ratings,
        areas: areas,
        hospitals: hospitals,
        skybridges: skybridges,
        badges: badges
      }) do
    area_map = Map.new(areas, &area/1)
    cells = areas |> Enum.flat_map(&cells/1) |> Map.new(&{&1.id, &1})
    rows = areas |> Enum.flat_map(&lines(&1, :row)) |> Map.new(&{&1.id, &1})
    columns = areas |> Enum.flat_map(&lines(&1, :column)) |> Map.new(&{&1.id, &1})

    %__MODULE__{
      volunteers: volunteers,
      solo_ratings: solo_ratings,
      areas: area_map,
      cells: cells,
      rows: rows,
      columns: columns,
      bonuses: bonuses(rows, columns),
      hospitals: Map.new(hospitals, &hospital/1),
      skybridges: Map.new(skybridges, &skybridge/1),
      badges: Map.new(badges, &badge/1)
    }
  end

  @spec cell_id(atom(), integer(), integer()) :: String.t()
  def cell_id(area_id, q, r), do: "#{area_id}:#{q}:#{r}"

  defp area({area_id, spec}) do
    {area_id, %{id: area_id, initial_access: Map.get(spec, :initial_access, false)}}
  end

  defp cells({area_id, spec}) do
    for {qs, r} <- Enum.with_index(spec.rows), q <- qs do
      %{id: cell_id(area_id, q, r), area_id: area_id, q: q, r: r, contains_koala: true}
    end
  end

  defp lines({area_id, spec}, :row) do
    for {qs, r} <- Enum.with_index(spec.rows) do
      line(area_id, :row, r, Enum.map(qs, &cell_id(area_id, &1, r)), Enum.at(spec.row_bonuses, r))
    end
  end

  defp lines({area_id, spec}, :column) do
    columns = spec.rows |> Enum.flat_map(&Enum.to_list/1) |> Enum.uniq() |> Enum.sort()

    for q <- columns do
      cell_ids =
        spec.rows
        |> Enum.with_index()
        |> Enum.filter(fn {qs, _r} -> q in qs end)
        |> Enum.map(fn {_qs, r} -> cell_id(area_id, q, r) end)

      line(area_id, :column, q, cell_ids, Enum.at(spec.column_bonuses, q))
    end
  end

  defp line(area_id, kind, index, cell_ids, bonus_spec) do
    id = "#{area_id}:#{kind}:#{index}"

    %{
      id: id,
      area_id: area_id,
      kind: kind,
      index: index,
      cell_ids: cell_ids,
      bonus: normalize_bonus(area_id, kind, index, id, bonus_spec)
    }
  end

  defp normalize_bonus(_area_id, _axis, _index, _line_id, nil), do: nil

  defp normalize_bonus(area_id, axis, index, line_id, {:skybridge, to}) do
    %{
      ref: %{area: area_id, axis: axis, index: index},
      line_id: line_id,
      kind: :skybridge,
      target_area_id: to
    }
  end

  defp normalize_bonus(area_id, axis, index, line_id, {:skybridge, area_id, to}) do
    normalize_bonus(area_id, axis, index, line_id, {:skybridge, to})
  end

  defp normalize_bonus(area_id, axis, index, line_id, {kind, target_id}) do
    %{
      ref: %{area: area_id, axis: axis, index: index},
      line_id: line_id,
      kind: kind,
      target_id: target_id
    }
  end

  defp normalize_bonus(area_id, axis, index, line_id, kind) do
    %{ref: %{area: area_id, axis: axis, index: index}, line_id: line_id, kind: kind}
  end

  defp bonuses(rows, columns) do
    rows
    |> Map.values()
    |> Kernel.++(Map.values(columns))
    |> Enum.filter(& &1.bonus)
    |> Map.new(&{&1.bonus.line_id, &1.bonus})
  end

  @spec badge(badge()) :: {atom(), map()}
  defp badge({id, badge}) do
    {id, Map.put(badge, :id, id)}
  end

  @spec hospital(hospital()) :: {String.t(), map()}
  defp hospital({id, hospital}) do
    id = hospital_id(id)
    {id, Map.put(hospital, :id, id)}
  end

  @spec hospital_id(atom()) :: String.t()
  defp hospital_id(id), do: id |> Atom.to_string() |> String.replace("_", "-")

  @spec skybridge(skybridge()) :: {String.t(), map()}
  defp skybridge(%{from: from, to: to}) do
    id = skybridge_id(from, to)
    {id, %{id: id, from_area_id: from, to_area_id: to}}
  end

  @spec skybridge_id(atom(), atom()) :: String.t()
  defp skybridge_id(from, to), do: "#{from}-#{to}"
end
