defmodule D20.GameTest do
  use ExUnit.Case, async: true

  alias D20.KoalaRescueClub.Game, as: KoalaGame

  defmodule TestGame do
    @behaviour D20.Game

    @impl D20.Game
    def attrs(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    @impl D20.Game
    def init(_attrs), do: {:ok, %{phase: :setup}}

    @impl D20.Game
    def dispatch(state, %D20.Command{}), do: {:ok, state}

    @impl D20.Game
    def finished?(_state), do: false
  end

  defmodule InitZeroOnlyGame do
    def init, do: {:ok, %{}}
    def dispatch(state, %D20.Command{}), do: {:ok, state}
    def finished?(_state), do: false
  end

  defmodule MissingAttrsGame do
    def init(_attrs), do: {:ok, %{}}
    def dispatch(state, %D20.Command{}), do: {:ok, state}
    def finished?(_state), do: false
  end

  test "requires attrs/1 and init/1 as engine callbacks" do
    assert D20.Game.ensure_engine(TestGame) == {:ok, TestGame}
    assert D20.Game.ensure_engine(InitZeroOnlyGame) == {:error, :invalid_engine}
    assert D20.Game.ensure_engine(MissingAttrsGame) == {:error, :invalid_engine}
  end

  test "returns an empty attrs changeset for engines without creation fields" do
    assert {:ok, %Ecto.Changeset{valid?: true, types: %{}}} = D20.Game.attrs(TestGame)
  end

  test "uses empty attrs for engines without creation fields" do
    assert {:ok, %Ecto.Changeset{valid?: true, types: %{}}} =
             D20.Game.attrs(TestGame, %{"sheet" => "dharug"})

    assert {:ok, %{phase: :setup}} = D20.Game.init(TestGame, %{"sheet" => "dharug"})
  end

  test "rejects invalid creation params before initializing the engine" do
    assert D20.Game.init(TestGame, "bad") == {:error, :invalid_creation_attrs}
  end

  test "validates and normalizes creation params before initializing the engine" do
    assert {:ok, %KoalaGame{sheet: :yugambeh}} =
             D20.Game.init(KoalaGame, %{"sheet" => "yugambeh"})

    assert {:error, %Ecto.Changeset{valid?: false}} =
             D20.Game.init(KoalaGame, %{"sheet" => "missing"})
  end
end
