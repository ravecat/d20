defmodule D20.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `D20.Accounts.Scope` allows public interfaces to receive
  information about the caller. It intentionally stores only the runtime actor
  identity; account-specific data such as the authenticated `%User{}` lives in
  web assigns.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias D20.Accounts.Anonymous
  alias D20.Accounts.User
  alias D20.Actors.Actor

  defstruct actor: nil

  @type t :: %__MODULE__{actor: Actor.t() | nil}

  @doc """
  Creates a scope for the given actor.
  """
  @spec for_actor(%User{} | Anonymous.t() | Actor.t()) :: t()
  def for_actor(%User{} = user), do: %__MODULE__{actor: Actor.new(user)}
  def for_actor(%Anonymous{} = anonymous), do: %__MODULE__{actor: Actor.new(anonymous)}
  def for_actor(%Actor{} = actor), do: %__MODULE__{actor: actor}
end
