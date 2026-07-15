defmodule D20Web.Projection do
  @moduledoc """
  Renders API payload projections sent to clients.
  """

  alias D20.Accounts.Scope
  alias D20.KoalaRescueClub
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

  def render(%Scope{}, %Session{} = session) do
    session
  end

  @doc "Renders a caller-specific interaction response without changing session state."
  @spec render_event(Scope.t(), Session.t(), String.t(), term()) ::
          {:ok, map()} | {:error, term()}
  def render_event(
        %Scope{} = scope,
        %Session{game: %KoalaRescueClub.Game{}} = session,
        "project_turn_selection",
        attrs
      ) do
    KoalaRescueClub.Projection.project_turn_selection(scope, session, attrs)
  end

  def render_event(%Scope{}, %Session{}, _event, _attrs), do: {:error, :unknown_projection}
end
