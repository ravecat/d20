defmodule D20.Module.ManifestTest do
  use ExUnit.Case, async: true

  test "loads normalized module entries" do
    assert [qwinto] = D20.Module.Manifest.list()
    assert qwinto.id == "qwinto"
    assert qwinto.title == "Qwinto"
    assert qwinto.game == "qwinto"
    assert qwinto.embed_url == "http://localhost:5173"
    assert qwinto.allowed_origins == ["http://localhost:5173"]
    assert "allow-scripts" in qwinto.sandbox
    refute Map.has_key?(qwinto, :transport)
  end

  test "resolves module ids for configured game engines" do
    assert D20.Module.Manifest.module_id_for_engine(D20.Qwinto.Game) == "qwinto"
  end
end
