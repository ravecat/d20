defmodule D20.GameTest do
  use ExUnit.Case, async: true

  alias D20.KoalaRescueClub.Game, as: KoalaGame

  defmodule CustomServer do
  end

  defmodule TestGame do
    use D20.Game

    def view_phase(state), do: Pathex.view!(state, lens(:phase))

    def ready_players(state) do
      Pathex.set!(state, lens(:players) ~> all() ~> path(:status), :ready)
    end

    @impl D20.Game
    def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    @impl D20.Game
    def init(_attrs), do: {:ok, %{phase: :setup}}

    @impl D20.Game
    def dispatch(state, %D20.Command{}), do: {:ok, state}

    @impl D20.Game
    def finished?(_state), do: false
  end

  defmodule CustomServerGame do
    use D20.Game, server: CustomServer

    @impl D20.Game
    def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

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

  defmodule MissingChangesetGame do
    def init(_attrs), do: {:ok, %{}}
    def dispatch(state, %D20.Command{}), do: {:ok, state}
    def finished?(_state), do: false
  end

  defmodule MissingServerGame do
    def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])
    def init(_attrs), do: {:ok, %{}}
    def dispatch(state, %D20.Command{}), do: {:ok, state}
    def finished?(_state), do: false
  end

  test "requires changeset/1 and init/1 as engine callbacks" do
    assert D20.Game.ensure_engine(TestGame) == {:ok, TestGame}
    assert D20.Game.ensure_engine(InitZeroOnlyGame) == {:error, :invalid_engine}
    assert D20.Game.ensure_engine(MissingChangesetGame) == {:error, :invalid_engine}
    assert D20.Game.ensure_engine(MissingServerGame) == {:error, :invalid_engine}
  end

  test "configures the default session server unless an engine provides one" do
    assert function_exported?(TestGame, :server, 0)
    assert TestGame.server() == D20.Sessions.Server
    assert D20.Game.server(TestGame) == D20.Sessions.Server
    assert function_exported?(CustomServerGame, :server, 0)
    assert D20.Game.server(CustomServerGame) == CustomServer
  end

  test "provides an unsupported default preview callback" do
    assert {:error, :unknown_command} =
             TestGame.preview(%{phase: :setup}, %D20.Command{event: "draft"})
  end

  test "provides private field and collection lenses to game engines" do
    assert TestGame.view_phase(%{phase: :setup}) == :setup

    assert %{
             players: %{
               "player-1" => %{status: :ready, score: 1},
               "player-2" => %{status: :ready, score: 2}
             }
           } =
             TestGame.ready_players(%{
               players: %{
                 "player-1" => %{status: :pending, score: 1},
                 "player-2" => %{status: :submitted, score: 2}
               }
             })

    refute function_exported?(TestGame, :lens, 1)
  end

  test "returns an empty attrs changeset for engines without creation fields" do
    assert %Ecto.Changeset{valid?: true, types: %{}} = D20.Game.changeset(TestGame)
  end

  test "uses empty attrs for engines without creation fields" do
    assert %Ecto.Changeset{valid?: true, types: %{}} =
             D20.Game.changeset(TestGame, %{"sheet" => "dharug"})

    assert {:ok, %{phase: :setup}} = D20.Game.init(TestGame, %{"sheet" => "dharug"})
  end

  test "validates and normalizes creation params before initializing the engine" do
    assert {:ok, %KoalaGame{sheet: :yugambeh}} =
             D20.Game.init(KoalaGame, %{"sheet" => "yugambeh"})

    assert {:error, %Ecto.Changeset{valid?: false}} =
             D20.Game.init(KoalaGame, %{"sheet" => "missing"})
  end
end
