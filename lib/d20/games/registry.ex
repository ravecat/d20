defmodule D20.Games.Registry do
  @moduledoc """
  Registry of implemented playable games.

  Registry entries are stable operational bindings. Display metadata is resolved
  separately from external providers such as BoardGameGeek.
  """

  @slug_pattern ~r/\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/

  defmodule Entry do
    @moduledoc false

    @enforce_keys [:slug, :engine, :bgg_id, :sandbox]
    defstruct [:slug, :engine, :bgg_id, :sandbox]

    @type t :: %__MODULE__{
            slug: String.t(),
            engine: D20.Game.engine(),
            bgg_id: integer(),
            sandbox: [String.t()]
          }
  end

  @type entry :: Entry.t()

  @spec list() :: [entry()]
  def list do
    :games
    |> config!()
    |> Enum.sort_by(fn {slug, _attrs} -> Atom.to_string(slug) end)
    |> Enum.map(fn {slug, attrs} -> normalize!(slug, attrs) end)
  end

  @spec fetch(String.t()) :: {:ok, entry()} | {:error, :game_not_found}
  def fetch(slug) when is_binary(slug) do
    with {:ok, config_slug} <- existing_atom(slug),
         {:ok, attrs} <- Keyword.fetch(config!(:games), config_slug) do
      {:ok, normalize!(config_slug, attrs)}
    else
      :error -> {:error, :game_not_found}
    end
  end

  defp normalize!(slug, attrs) when is_atom(slug) and is_list(attrs) do
    slug = Atom.to_string(slug)
    validate_slug!(slug)

    %Entry{
      slug: slug,
      engine: Keyword.fetch!(attrs, :engine),
      bgg_id: validate_bgg_id!(Keyword.fetch!(attrs, :bgg_id), slug),
      sandbox: validate_sandbox!(Keyword.fetch!(attrs, :sandbox), slug)
    }
  end

  defp validate_slug!(slug) do
    unless Regex.match?(@slug_pattern, slug) do
      raise ArgumentError, "invalid game registry slug #{inspect(slug)}"
    end
  end

  defp validate_bgg_id!(bgg_id, _slug) when is_integer(bgg_id) and bgg_id > 0, do: bgg_id

  defp validate_bgg_id!(bgg_id, slug) do
    raise ArgumentError, "invalid BGG id #{inspect(bgg_id)} for game #{inspect(slug)}"
  end

  defp validate_sandbox!(sandbox, slug) when is_list(sandbox) and sandbox != [] do
    if Enum.all?(sandbox, &is_binary/1) do
      sandbox
    else
      raise ArgumentError, "invalid iframe sandbox #{inspect(sandbox)} for game #{inspect(slug)}"
    end
  end

  defp validate_sandbox!(sandbox, slug) do
    raise ArgumentError, "invalid iframe sandbox #{inspect(sandbox)} for game #{inspect(slug)}"
  end

  defp existing_atom(slug) do
    {:ok, String.to_existing_atom(slug)}
  rescue
    ArgumentError -> :error
  end

  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
