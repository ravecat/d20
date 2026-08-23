defmodule D20.Games.Registry do
  @moduledoc """
  Registry of catalog games and their optional runtime bindings.

  Registry entries are stable operational bindings. Display metadata is resolved
  separately from external providers such as BoardGameGeek.
  """

  defmodule Entry do
    @moduledoc false

    import Ecto.Changeset

    @slug_pattern ~r/\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/
    @statuses [:active, :in_progress]
    @fields [:slug, :engine, :bgg_id, :status]
    @types %{slug: :string, engine: :any, bgg_id: :integer, status: :any}

    @enforce_keys [:slug, :bgg_id]
    defstruct [:slug, :bgg_id, :status, engine: nil]

    @type t :: %__MODULE__{
            slug: String.t(),
            engine: D20.Game.engine() | nil,
            bgg_id: integer(),
            status: :active | :in_progress | nil
          }

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) when is_map(attrs) do
      {struct(__MODULE__), @types}
      |> cast(attrs, @fields)
      |> validate_required([:slug, :bgg_id])
      |> validate_slug()
      |> validate_number(:bgg_id, greater_than: 0)
      |> validate_inclusion(:status, @statuses, message: "must be active or in_progress")
      |> validate_operational_bindings()
    end

    @spec new!(map()) :: t()
    def new!(attrs) when is_map(attrs) do
      attrs
      |> changeset()
      |> apply_action!(:insert)
    end

    defp validate_slug(changeset) do
      validate_change(changeset, :slug, fn :slug, slug ->
        if is_binary(slug) and Regex.match?(@slug_pattern, slug) do
          []
        else
          [slug: "has invalid format"]
        end
      end)
    end

    defp validate_operational_bindings(changeset) do
      if get_field(changeset, :status) in @statuses do
        validate_required(changeset, [:engine])
      else
        changeset
      end
    end
  end

  @type entry :: Entry.t()

  @spec list() :: [entry()]
  def list do
    :games
    |> config!()
    |> Enum.sort_by(fn {slug, _attrs} -> Atom.to_string(slug) end)
    |> Enum.map(fn {key, attrs} ->
      attrs |> Map.new() |> Map.put(:slug, Atom.to_string(key)) |> Entry.new!()
    end)
  end

  @spec fetch(String.t()) :: {:ok, entry()} | {:error, :game_not_found}
  def fetch(slug) when is_binary(slug) do
    with {:ok, attrs} <- lookup(slug) do
      {:ok, Entry.new!(attrs)}
    else
      :error -> {:error, :game_not_found}
    end
  end

  defp lookup(slug) do
    :games
    |> config!()
    |> Enum.find_value(:error, fn {key, attrs} ->
      key_slug = Atom.to_string(key)

      if key_slug == slug do
        {:ok, attrs |> Map.new() |> Map.put(:slug, key_slug)}
      end
    end)
  end

  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
