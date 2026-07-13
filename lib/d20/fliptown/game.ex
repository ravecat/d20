defmodule D20.Fliptown.Game do
  @moduledoc """
  Fliptown game engine placeholder.
  """

  use D20.Game

  @impl D20.Game
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(_params), do: Ecto.Changeset.cast({%{}, %{}}, %{}, [])

  @impl D20.Game
  @spec init(D20.Game.attrs()) :: {:error, :not_implemented}
  def init(_attrs), do: {:error, :not_implemented}

  @impl D20.Game
  @spec dispatch(term(), D20.Command.t()) :: {:error, :not_implemented}
  def dispatch(_game, %D20.Command{}), do: {:error, :not_implemented}

  @impl D20.Game
  @spec finished?(term()) :: false
  def finished?(_game), do: false
end
