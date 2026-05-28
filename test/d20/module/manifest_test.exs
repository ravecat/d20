defmodule D20.Module.ManifestTest do
  use ExUnit.Case, async: true

  test "fetches module entries by slug" do
    assert {:ok, qwinto} = D20.Module.Manifest.fetch("qwinto")
    assert qwinto.slug == "qwinto"
    assert qwinto.embed_url == "http://localhost:5173"
    assert qwinto.allowed_origins == ["http://localhost:5173"]
    assert "allow-scripts" in qwinto.sandbox
    refute Map.has_key?(qwinto, :id)
    refute Map.has_key?(qwinto, :title)
    refute Map.has_key?(qwinto, :game)
    refute Map.has_key?(qwinto, :transport)

    assert D20.Module.Manifest.fetch("missing") == {:error, :module_not_found}
  end

  test "fetches configured engines by slug" do
    assert D20.Module.Manifest.fetch_engine("qwinto") == {:ok, D20.Qwinto.Game}
    assert D20.Module.Manifest.fetch_engine("missing") == {:error, :engine_not_found}
  end
end
