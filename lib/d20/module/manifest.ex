defmodule D20.Module.Manifest do
  @moduledoc """
  Loads iframe module entries from project-scoped manifests.
  """

  @type module_entry :: %{
          required(:id) => String.t(),
          required(:title) => String.t(),
          required(:game) => String.t(),
          required(:embed_url) => String.t(),
          required(:allowed_origins) => [String.t()],
          required(:sandbox) => [String.t()]
        }

  @spec list() :: [module_entry()]
  def list do
    manifest_entries()
    |> Enum.map(&normalize!/1)
  end

  @spec fetch(String.t()) :: {:ok, module_entry()} | {:error, :module_not_found}
  def fetch(id) when is_binary(id) do
    list()
    |> Enum.find(&(&1.id == id))
    |> case do
      nil -> {:error, :module_not_found}
      module -> {:ok, module}
    end
  end

  @spec fetch_engine(String.t()) :: {:ok, module()} | {:error, :engine_not_found}
  def fetch_engine(module_id) when is_binary(module_id) do
    :engines
    |> config!()
    |> Enum.find_value({:error, :engine_not_found}, fn {configured_module_id, engine} ->
      if Atom.to_string(configured_module_id) == module_id, do: {:ok, engine}
    end)
  end

  @spec module_id_for_engine(module()) :: String.t() | nil
  def module_id_for_engine(engine) when is_atom(engine) do
    :engines
    |> config!()
    |> Enum.find_value(fn {module_id, configured_engine} ->
      if configured_engine == engine, do: Atom.to_string(module_id)
    end)
  end

  defp manifest_entries do
    path()
    |> File.read!()
    |> Jason.decode!()
    |> Map.fetch!("modules")
  end

  defp normalize!(%{
         "id" => id,
         "title" => title,
         "game" => game,
         "entry" => entry,
         "allowedOrigins" => allowed_origins,
         "sandbox" => sandbox
       })
       when is_binary(id) and is_binary(title) and is_binary(game) and is_binary(entry) and
              is_list(allowed_origins) and is_list(sandbox) do
    %{
      id: id,
      title: title,
      game: game,
      embed_url: entry,
      allowed_origins: allowed_origins,
      sandbox: sandbox
    }
  end

  defp path do
    Application.app_dir(:d20, config!(:path))
  end

  defp config!(key) do
    :d20
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
