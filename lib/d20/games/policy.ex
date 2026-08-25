defmodule D20.Games.Policy do
  @moduledoc """
  Authorizes actions at the persisted game catalog boundary.
  """

  @behaviour Bodyguard.Policy

  alias D20.Accounts.User

  @impl Bodyguard.Policy
  def authorize(:manage_games, %User{role: :admin}, _params), do: true
  def authorize(_action, _user, _params), do: false
end
