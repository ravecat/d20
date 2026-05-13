defmodule Ecto.KsuidTest do
  use ExUnit.Case, async: true

  test "uses string as storage type" do
    assert Ecto.Ksuid.type() == :string
  end

  test "autogenerates valid ksuid strings" do
    ksuid = Ecto.Ksuid.autogenerate()

    assert is_binary(ksuid)
    assert {:ok, ^ksuid} = Ecto.Ksuid.cast(ksuid)
  end

  test "casts valid ksuid strings" do
    ksuid = Ksuid.generate()

    assert Ecto.Ksuid.cast(ksuid) == {:ok, ksuid}
  end

  test "rejects invalid values" do
    assert Ecto.Ksuid.cast("not-a-ksuid") == :error
    assert Ecto.Ksuid.cast(123) == :error
  end

  test "loads and dumps valid ksuid strings" do
    ksuid = Ksuid.generate()

    assert Ecto.Ksuid.load(ksuid) == {:ok, ksuid}
    assert Ecto.Ksuid.dump(ksuid) == {:ok, ksuid}
  end

  test "rejects invalid load and dump values" do
    assert Ecto.Ksuid.load("not-a-ksuid") == :error
    assert Ecto.Ksuid.dump("not-a-ksuid") == :error
    assert Ecto.Ksuid.load(123) == :error
    assert Ecto.Ksuid.dump(123) == :error
  end
end
