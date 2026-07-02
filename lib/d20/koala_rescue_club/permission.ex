defmodule D20.KoalaRescueClub.Permission do
  @moduledoc """
  Caller-specific Koala Rescue Club permissions for session projections.
  """

  @behaviour D20.Permission
  @behaviour Bodyguard.Policy

  alias D20.Accounts.Scope
  alias D20.Command
  alias D20.KoalaRescueClub.Game
  alias D20.KoalaRescueClub.Rules
  alias D20.Sessions.Session

  @permissions ~w(
    can_start_game
    can_roll
    can_submit_turn
  )a

  @type t :: %{
          required(:can_start_game) => boolean(),
          required(:can_roll) => boolean(),
          required(:can_submit_turn) => boolean()
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
    Rules.validate(game, %Command{event: "start", actor_id: actor_id}) == :ok
  end

  def authorize(:roll, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.roll_allowed?(game, actor_id)
  end

  def authorize(:submit_turn, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.submit_allowed?(game, actor_id)
  end

  def authorize(_action, %Scope{}, %Session{}), do: {:error, :unauthorized}
  def authorize(_action, _scope, _session), do: {:error, :unauthorized}

  defp permit?(:can_start_game, %Scope{} = scope, %Session{} = session) do
    permit(:start_game, scope, session) == :ok
  end

  defp permit?(:can_roll, %Scope{} = scope, %Session{} = session) do
    permit(:roll, scope, session) == :ok
  end

  defp permit?(:can_submit_turn, %Scope{} = scope, %Session{} = session) do
    permit(:submit_turn, scope, session) == :ok
  end
end
