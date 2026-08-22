defmodule D20.NextStationLondon.Server do
  @moduledoc """
  Session server that reveals each Next Station: London instruction on state entry.
  """

  use D20.Sessions.Server

  alias D20.Command
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Ruleset
  alias D20.Sessions.Session

  @impl :gen_statem
  def callback_mode, do: [:handle_event_function, :state_enter]

  def handle_event(:enter, _old_state, :reveal, {_slug, Game, session}) do
    command = reveal_command(session.game)

    {:keep_state_and_data, [{:state_timeout, 0, {:reveal, command}}]}
  end

  def handle_event(
        :state_timeout,
        {:reveal, %Command{} = command},
        :reveal,
        {slug, Game, session} = data
      ) do
    case Session.dispatch(session, Game, command) do
      {:ok, %Session{} = updated_session} ->
        broadcast(session, updated_session)

        {:next_state, updated_session.game.phase, {slug, Game, updated_session}, [idle_action()]}

      {:error, reason} ->
        {:stop, {:invalid_random_setup, reason}, data}
    end
  end

  @doc false
  @spec reveal_command(Game.t()) :: Command.t()
  def reveal_command(%Game{draws: [], remaining_deck: []} = game) do
    %Command{event: "reveal", attrs: round_setup_attrs(game)}
  end

  def reveal_command(%Game{}), do: %Command{event: "reveal", attrs: %{}}

  defp round_setup_attrs(game) do
    %{deck: Enum.shuffle(Ruleset.card_ids())}
    |> maybe_put_pencils(game)
    |> maybe_put_objectives(game)
    |> maybe_put_powers(game)
  end

  defp maybe_put_pencils(attrs, %{round: 1, players: players}) do
    offsets = players |> Map.keys() |> Enum.shuffle() |> Enum.zip(0..3) |> Map.new()

    attrs
    |> Map.put(:pencil_cycle, Enum.shuffle(Ruleset.colors()))
    |> Map.put(:pencil_offsets, offsets)
  end

  defp maybe_put_pencils(attrs, _game), do: attrs

  defp maybe_put_objectives(attrs, %{round: 1, objectives: []}) do
    Map.put(attrs, :objectives, Ruleset.objective_ids() |> Enum.shuffle() |> Enum.take(2))
  end

  defp maybe_put_objectives(attrs, _game), do: attrs

  defp maybe_put_powers(attrs, %{round: 1, powers: %{}}) do
    powers = Ruleset.colors() |> Enum.zip(Enum.shuffle(Ruleset.power_ids())) |> Map.new()
    Map.put(attrs, :powers, powers)
  end

  defp maybe_put_powers(attrs, _game), do: attrs
end
