defmodule D20.KoalaRescueClub.Game do
  @moduledoc """
  Koala Rescue Club game engine placeholder.
  """

  @behaviour D20.Game

  @impl D20.Game
  @spec init() :: {:error, :not_implemented}
  def init, do: {:error, :not_implemented}

  @impl D20.Game
  @spec dispatch(term(), D20.Command.t()) :: {:error, :not_implemented}
  def dispatch(_game, %D20.Command{}), do: {:error, :not_implemented}

  @impl D20.Game
  @spec finished?(term()) :: false
  def finished?(_game), do: false
end
