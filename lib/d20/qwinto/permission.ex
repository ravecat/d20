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
    can_select_dice
    can_roll
    can_keep
    can_reroll
    can_write_result
    can_pass_result
    can_take_penalty
  )a

  @type t :: %{
          required(:can_start_game) => boolean(),
          required(:can_select_dice) => boolean(),
          required(:can_roll) => boolean(),
          required(:can_keep) => boolean(),
          required(:can_reroll) => boolean(),
          required(:can_write_result) => boolean(),
          required(:can_pass_result) => boolean(),
          required(:can_take_penalty) => boolean()
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

  def authorize(:select_dice, %Scope{} = scope, %Session{} = session) do
    authorize(:roll, scope, session)
  end

  def authorize(:roll, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.validate(game, %Command{event: "roll", actor_id: actor_id}) == :ok
  end

  def authorize(:keep, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.validate(game, %Command{event: "keep", actor_id: actor_id}) == :ok
  end

  def authorize(:reroll, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.validate(game, %Command{event: "reroll", actor_id: actor_id}) == :ok
  end

  def authorize(:write_result, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{phase: :result} = game
      }) do
    Rules.write_allowed?(game, actor_id)
  end

  def authorize(:pass_result, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.validate(game, %Command{event: "skip", actor_id: actor_id}) == :ok
  end

  def authorize(:take_penalty, %Scope{actor: %{id: actor_id}}, %Session{
        phase: :in_progress,
        game: %Game{} = game
      }) do
    Rules.validate(game, %Command{event: "take_penalty", actor_id: actor_id}) == :ok
  end

  def authorize(_action, %Scope{}, %Session{}), do: {:error, :unauthorized}
  def authorize(_action, _scope, _session), do: {:error, :unauthorized}

  defp permit?(:can_start_game, %Scope{} = scope, %Session{} = session) do
    permit(:start_game, scope, session) == :ok
  end

  defp permit?(:can_select_dice, %Scope{} = scope, %Session{} = session) do
    permit(:select_dice, scope, session) == :ok
  end

  defp permit?(:can_roll, %Scope{} = scope, %Session{} = session) do
    permit(:roll, scope, session) == :ok
  end

  defp permit?(:can_keep, %Scope{} = scope, %Session{} = session) do
    permit(:keep, scope, session) == :ok
  end

  defp permit?(:can_reroll, %Scope{} = scope, %Session{} = session) do
    permit(:reroll, scope, session) == :ok
  end

  defp permit?(:can_write_result, %Scope{} = scope, %Session{} = session) do
    permit(:write_result, scope, session) == :ok
  end

  defp permit?(:can_pass_result, %Scope{} = scope, %Session{} = session) do
    permit(:pass_result, scope, session) == :ok
  end

  defp permit?(:can_take_penalty, %Scope{} = scope, %Session{} = session) do
    permit(:take_penalty, scope, session) == :ok
  end

  defp permit?(_permission, %Scope{}, %Session{}), do: false
end
