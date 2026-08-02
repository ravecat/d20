defmodule D20.Sessions.Registry do
  @moduledoc """
  Process-owned index of actor attachments to live Session runtimes.

  The calling Session process owns every entry it registers. Registry removes
  those entries automatically when that process terminates.
  """

  import D20.Guards, only: [is_player_id: 1]

  alias D20.Sessions.Session

  @type entry :: {pid(), Session.id()}
  @type attach_result :: :attached | :unchanged
  @type detach_result :: :detached | :unchanged

  @spec attach(Session.player_id(), Session.id()) :: attach_result()
  def attach(actor_id, session_id) when is_player_id(actor_id) and is_binary(session_id) do
    if session_id in Registry.values(__MODULE__, actor_id, self()) do
      :unchanged
    else
      {:ok, _owner} = Registry.register(__MODULE__, actor_id, session_id)
      :attached
    end
  end

  @spec detach(Session.player_id()) :: detach_result()
  def detach(actor_id) when is_player_id(actor_id) do
    case Registry.values(__MODULE__, actor_id, self()) do
      [] ->
        :unchanged

      _values ->
        Registry.unregister(__MODULE__, actor_id)
        :detached
    end
  end

  @spec list(Session.player_id()) :: [entry()]
  def list(actor_id) when is_player_id(actor_id) do
    Registry.lookup(__MODULE__, actor_id)
  end
end
