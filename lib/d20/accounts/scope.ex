defmodule D20.Accounts.Scope do
  @moduledoc """
  Defines the scope of the caller to be used throughout the app.

  The `D20.Accounts.Scope` allows public interfaces to receive
  information about the caller and the runtime resource being addressed.
  Account-specific data such as the authenticated `%User{}` lives in web assigns.

  It is useful for logging as well as for scoping pubsub subscriptions and
  broadcasts when a caller subscribes to an interface or performs a particular
  action.

  Feel free to extend the fields on this struct to fit the needs of
  growing application requirements.
  """

  alias D20.Accounts.Anonymous
  alias D20.Accounts.User
  alias D20.Actors.Actor
  alias D20.Games.Game
  alias D20.Sessions.Session

  defstruct actor: nil, session: nil, game: nil

  @type session :: %{required(:id) => Session.id()}
  @type game :: %{required(:id) => Game.id()}
  @type t :: %__MODULE__{actor: Actor.t() | nil, session: session() | nil, game: game() | nil}

  @doc """
  Creates a scope for the given actor.
  """
  @spec for_actor(User.t() | Anonymous.t() | Actor.t()) :: t()
  def for_actor(%User{} = user), do: %__MODULE__{actor: Actor.new(user)}
  def for_actor(%Anonymous{} = anonymous), do: %__MODULE__{actor: Actor.new(anonymous)}
  def for_actor(%Actor{} = actor), do: %__MODULE__{actor: actor}

  @doc """
  Returns the caller actor id from the scope.
  """
  @spec actor_id(t()) :: Actor.id()
  def actor_id(%__MODULE__{actor: %Actor{id: id}}) when is_binary(id), do: id

  @doc """
  Adds the current transport session identity to the scope.
  """
  @spec put_session(t(), Session.id()) :: t()
  def put_session(%__MODULE__{} = scope, session_id) when is_binary(session_id) do
    %{scope | session: %{id: session_id}}
  end

  @doc """
  Adds the current game identity to the scope.
  """
  @spec put_game(t(), Game.id()) :: t()
  def put_game(%__MODULE__{} = scope, game_id) do
    %{scope | game: %{id: game_id}}
  end
end
