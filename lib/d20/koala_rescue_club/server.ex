defmodule D20.KoalaRescueClub.Server do
  @moduledoc """
  Game server that schedules the automatic roll on entry to the roll phase.
  """

  use D20.Game.Server

  alias D20.Command
  alias D20.KoalaRescueClub.Game
  alias D20.Sessions.Session

  @roll_timeout :timer.seconds(1)

  @impl :gen_statem
  def callback_mode, do: [:handle_event_function, :state_enter]

  def handle_event(:enter, _old_state, :roll, {_slug, _engine, %Session{game: %Game{roll: nil}}}) do
    {:keep_state_and_data, [{:state_timeout, @roll_timeout, :roll}]}
  end

  def handle_event(:state_timeout, :roll, :roll, _data) do
    command = %Command{event: "roll"}

    {:keep_state_and_data, [{:next_event, :internal, {:dispatch, command}}]}
  end
end
