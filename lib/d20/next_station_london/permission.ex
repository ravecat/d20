defmodule D20.NextStationLondon.Permission do
  @moduledoc """
  Caller-specific Next Station: London permissions.
  """

  @behaviour D20.Permission
  @behaviour Bodyguard.Policy

  alias D20.Accounts.Scope
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Rules
  alias D20.Sessions.Session

  @permissions ~w(
    can_start_game
    can_draw
    can_pass
  )a

  @type t :: %{
          required(:can_start_game) => boolean(),
          required(:can_draw) => boolean(),
          required(:can_pass) => boolean()
        }

  @impl D20.Permission
  @spec permissions(Scope.t(), Session.t()) :: t()
  def permissions(%Scope{} = scope, %Session{} = session) do
    Map.new(@permissions, &{&1, permit?(&1, scope, session)})
  end

  @impl D20.Permission
  @spec permit(atom(), Scope.t(), Session.t()) :: :ok | {:error, term()}
  def permit(action, %Scope{} = scope, %Session{} = session),
    do: Bodyguard.permit(__MODULE__, action, scope, session)

  @impl Bodyguard.Policy
  def authorize(:start_game, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :waiting_for_players,
        owner_id: actor_id,
        game: %Game{} = game
      }) do
    Rules.ready_to_start?(game) and Rules.participant?(game, actor_id)
  end

  def authorize(:draw, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.draw_available?(game, actor_id)
  end

  def authorize(:pass, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.submit_allowed?(game, actor_id)
  end

  def authorize(_action, %Scope{}, %Session{}), do: {:error, :unauthorized}
  def authorize(_action, _scope, _session), do: {:error, :unauthorized}

  defp permit?(:can_start_game, scope, session), do: permit(:start_game, scope, session) == :ok

  defp permit?(:can_draw, scope, session), do: permit(:draw, scope, session) == :ok

  defp permit?(:can_pass, scope, session), do: permit(:pass, scope, session) == :ok
end
