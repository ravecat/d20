defmodule D20Web.Projection do
  @moduledoc """
  Renders API payload projections sent to clients.
  """

  alias D20.Accounts.Scope
  alias D20.Qwinto
  alias D20.Sessions.Session

  @doc """
  Renders the session envelope for a caller.
  """
  @spec render(Scope.t(), Session.t()) :: map()
  def render(%Scope{} = scope, %Session{} = session) do
    session
    |> Map.from_struct()
    |> Map.merge(projection_for(scope, session))
  end

  defp projection_for(%Scope{} = scope, %Session{game: %Qwinto.Game{} = game} = session) do
    permissions = Qwinto.Permission.permissions(scope, session)

    available_slots =
      if permissions.can_see_result and game.phase == :decision and game.attempt == 1 do
        Qwinto.Rules.available_slots(game, scope.actor.id)
      else
        []
      end

    %{permissions: permissions, available_slots: available_slots}
  end

  defp projection_for(%Scope{}, %Session{}), do: %{permissions: %{}}
end
