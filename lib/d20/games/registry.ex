defmodule D20.Games.Registry do
  @moduledoc """
  Registry of implemented playable games.

  Registry entries are stable operational bindings. Display metadata is resolved
  separately from external providers such as BoardGameGeek.
  """

  defmodule Entry do
    @moduledoc false

    import Ecto.Changeset

    @slug_pattern ~r/\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/
    @fields [:slug, :engine, :bgg_id, :sandbox]
    @types %{slug: :string, engine: :any, bgg_id: :integer, sandbox: {:array, :string}}

    @enforce_keys [:slug, :engine, :bgg_id, :sandbox]
    defstruct [:slug, :engine, :bgg_id, :sandbox]

    @type t :: %__MODULE__{
            slug: String.t(),
            engine: D20.Game.engine(),
            bgg_id: integer(),
            sandbox: [String.t()]
          }

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) when is_map(attrs) do
      {struct(__MODULE__), @types}
      |> change(Map.take(attrs, @fields))
      |> validate_required(@fields)
      |> validate_slug()
      |> validate_bgg_id()
      |> validate_sandbox()
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

    defp validate_bgg_id(changeset) do
      validate_change(changeset, :bgg_id, fn :bgg_id, bgg_id ->
        if is_integer(bgg_id) and bgg_id > 0 do
          []
        else
          [bgg_id: "must be a positive integer"]
        end
      end)
    end

    defp validate_sandbox(changeset) do
      validate_change(changeset, :sandbox, fn :sandbox, sandbox ->
        if is_list(sandbox) and sandbox != [] and Enum.all?(sandbox, &is_binary/1) do
          []
        else
          [sandbox: "must be a non-empty list of strings"]
        end
      end)
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
