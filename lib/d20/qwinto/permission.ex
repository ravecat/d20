defmodule D20.Qwinto.Permission do
  @moduledoc """
  Caller-specific Qwinto permissions for session projections.
  """

  @behaviour D20.Permission
  @behaviour Bodyguard.Policy

  alias D20.Accounts.Scope
  alias D20.Command
  alias D20.Qwinto.Game
  alias D20.Qwinto.Rules
  alias D20.Sessions.Session

  @permissions ~w(
    can_start_game
    can_roll
    can_reroll
    can_see_roll
    can_write
    can_pass
    can_penalize
  )a

  @type t :: %{
          required(:can_start_game) => boolean(),
          required(:can_roll) => boolean(),
          required(:can_reroll) => boolean(),
          required(:can_see_roll) => boolean(),
          required(:can_write) => boolean(),
          required(:can_pass) => boolean(),
          required(:can_penalize) => boolean()
        }

  @doc """
  Computes the complete permission set for a caller and session.
  """
  @impl D20.Permission
  @spec permissions(Scope.t(), Session.t()) :: t()
  def permissions(%Scope{} = scope, %Session{} = session) do
    Map.new(@permissions, &{&1, permit?(&1, scope, session)})
  end

  @doc """
  Checks a single permission action and returns Bodyguard's normalized result.
  """
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
    Rules.validate(game, %Command{event: "roll", actor_id: actor_id}) == :ok
  end

  def authorize(:reroll, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.validate(game, %Command{event: "reroll", actor_id: actor_id}) == :ok
  end

  def authorize(:see_roll, %Scope{}, %Session{phase: :in_progress, game: %Game{phase: phase}})
      when phase in [:write_or_pass, :result],
      do: true

  def authorize(:write, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.write_allowed?(game, actor_id)
  end

  def authorize(:pass, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.validate(game, %Command{event: "pass", actor_id: actor_id}) == :ok
  end

  def authorize(:penalize, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.validate(game, %Command{event: "penalize", actor_id: actor_id}) == :ok
  end

  def authorize(_action, %Scope{}, %Session{}), do: {:error, :unauthorized}
  def authorize(_action, _scope, _session), do: {:error, :unauthorized}

  defp permit?(:can_start_game, %Scope{} = scope, %Session{} = session) do
    permit(:start_game, scope, session) == :ok
  end

  defp permit?(:can_roll, %Scope{} = scope, %Session{} = session) do
    permit(:roll, scope, session) == :ok
  end

  defp permit?(:can_reroll, %Scope{} = scope, %Session{} = session) do
    permit(:reroll, scope, session) == :ok
  end

  defp permit?(:can_see_roll, %Scope{} = scope, %Session{} = session) do
    permit(:see_roll, scope, session) == :ok
  end

  defp permit?(:can_write, %Scope{} = scope, %Session{} = session) do
    permit(:write, scope, session) == :ok
  end

  defp permit?(:can_pass, %Scope{} = scope, %Session{} = session) do
    permit(:pass, scope, session) == :ok
  end

  defp permit?(:can_penalize, %Scope{} = scope, %Session{} = session) do
    permit(:penalize, scope, session) == :ok
  end

  defp permit?(_permission, %Scope{}, %Session{}), do: false
end
