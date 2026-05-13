defmodule D20.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `D20.Accounts.Scope` allows public interfaces to receive
  information about the caller, such as if the call is initiated from an
  end-user, and if so, which user. Additionally, such a scope can carry fields
  such as "super user" or other privileges for use as authorization, or to
  ensure specific code paths can only be access for a given scope.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias D20.Accounts.Anonymous
  alias D20.Accounts.User
  alias D20.Actors.Actor

  defstruct actor: nil, anonymous: nil, user: nil

  @type t :: %__MODULE__{
          actor: Actor.t() | nil,
          anonymous: Anonymous.t() | nil,
          user: %User{} | nil
        }

  @doc """
  Creates a scope for the given user.

  Returns an anonymous-capable scope if no user is given.
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: %__MODULE__{user: nil}

  @spec put_actor(t(), Actor.t()) :: t()
  def put_actor(%__MODULE__{} = scope, %Actor{} = actor) do
    %{scope | actor: actor}
  end

  @spec put_anonymous(t(), Anonymous.t()) :: t()
  def put_anonymous(%__MODULE__{} = scope, %Anonymous{} = anonymous) do
    %{
      scope
      | anonymous: anonymous,
        user: nil,
        actor: Actor.new(anonymous)
    }
  end
end
