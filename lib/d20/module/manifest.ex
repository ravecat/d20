defmodule D20.Module.Manifest do
  @moduledoc """
  Loads iframe module entries from project-scoped manifests.
  """

  @type entry :: %{required(:slug) => String.t(), required(:sandbox) => [String.t()]}

  @slug_pattern ~r/\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/

  @spec fetch(String.t()) :: {:ok, entry()} | {:error, :module_not_found}
  def fetch(slug) when is_binary(slug) do
    case Map.fetch(manifest_entries(), slug) do
      {:ok, attrs} -> {:ok, normalize!(slug, attrs)}
      :error -> {:error, :module_not_found}
    end
  end

  @spec fetch_engine(String.t()) :: {:ok, module()} | {:error, :engine_not_found}
  def fetch_engine(slug) when is_binary(slug) do
    :engines
    |> config!()
    |> Enum.find_value({:error, :engine_not_found}, fn {configured_slug, engine} ->
      if Atom.to_string(configured_slug) == slug, do: {:ok, engine}
    end)
  end

  defp manifest_entries do
    path()
    |> File.read!()
    |> Jason.decode!()
  end

  defp normalize!(slug, %{"sandbox" => sandbox}) when is_binary(slug) and is_list(sandbox) do
    validate_slug!(slug)
    %{slug: slug, sandbox: sandbox}
  end

  defp validate_slug!(slug) do
    unless Regex.match?(@slug_pattern, slug) do
      raise ArgumentError, "invalid iframe module slug #{inspect(slug)}"
    end
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
