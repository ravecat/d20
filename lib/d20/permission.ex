defmodule D20.Permission do
  @moduledoc """
  Behaviour for game-specific permission projections.
  """

  alias D20.Accounts.Scope
  alias D20.Sessions.Session

  @type permissions :: map()

  @callback permissions(Scope.t(), Session.t()) :: permissions()
  @callback permit(atom(), Scope.t(), Session.t()) :: :ok | {:error, term()}
end
