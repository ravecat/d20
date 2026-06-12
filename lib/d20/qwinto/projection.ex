defmodule D20.Qwinto.Projection do
  @moduledoc """
  Renders caller-specific Qwinto projection fields.
  """

  alias D20.Accounts.Scope
  alias D20.Qwinto.Game
  alias D20.Qwinto.Permission
  alias D20.Qwinto.Rules
  alias D20.Sessions.Session

  @spec render(Scope.t(), Session.t()) :: map()
  def render(%Scope{} = scope, %Session{game: %Game{} = game} = session) do
    permissions = Permission.permissions(scope, session)
    available_slots = Rules.available_slots(game, scope.actor.id)

    session
    |> Map.from_struct()
    |> Map.merge(%{permissions: permissions, available_slots: available_slots})
  end
end
