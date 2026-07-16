defmodule D20Web.Projection do
  @moduledoc """
  Renders API payload projections sent to clients.
  """

  alias D20.Accounts.Scope
  alias D20.KoalaRescueClub
  alias D20.NextStationLondon
  alias D20.Qwinto
  alias D20.Sessions.Session

  @doc """
  Renders the session envelope for a caller.
  """
  @spec render(Scope.t(), Session.t()) :: map()
  def render(%Scope{} = scope, %Session{game: %Qwinto.Game{}} = session) do
    Qwinto.Projection.render(scope, session)
  end

  def render(%Scope{} = scope, %Session{game: %KoalaRescueClub.Game{}} = session) do
    KoalaRescueClub.Projection.render(scope, session)
  end

  def render(%Scope{} = scope, %Session{game: %NextStationLondon.Game{}} = session) do
    NextStationLondon.Projection.render(scope, session)
  end

  def render(%Scope{}, %Session{} = session) do
    session
  end
end
