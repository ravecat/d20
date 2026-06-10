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
    |> Map.put(:permissions, permissions_for(scope, session))
  end

  defp permissions_for(%Scope{} = scope, %Session{game: %Qwinto.Game{}} = session) do
    Qwinto.Permission.permissions(scope, session)
  end

  defp permissions_for(%Scope{}, %Session{}), do: %{}
end
