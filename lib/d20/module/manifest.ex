defmodule D20.Module.Manifest do
  @moduledoc """
  Loads iframe module entries from project-scoped manifests.
  """

  @type entry :: %{
          required(:slug) => String.t(),
          required(:embed_url) => String.t(),
          required(:allowed_origins) => [String.t()],
          required(:sandbox) => [String.t()]
        }

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

  defp normalize!(slug, %{"entry" => entry, "sandbox" => sandbox})
       when is_binary(slug) and is_binary(entry) and is_list(sandbox) do
    %{slug: slug, embed_url: entry, allowed_origins: [origin!(entry)], sandbox: sandbox}
  end

  defp origin!(entry) do
    case URI.parse(entry) do
      %URI{scheme: scheme, host: host} = uri when is_binary(scheme) and is_binary(host) ->
        uri
        |> Map.put(:path, nil)
        |> Map.put(:query, nil)
        |> Map.put(:fragment, nil)
        |> Map.put(:userinfo, nil)
        |> URI.to_string()

      _uri ->
        raise ArgumentError, "invalid iframe entry URL #{inspect(entry)}"
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
