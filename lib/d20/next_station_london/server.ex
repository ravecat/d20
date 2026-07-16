defmodule D20.NextStationLondon.Server do
  @moduledoc """
  Session server that prepares each Next Station: London round on state entry.
  """

  use D20.Game.Server

  alias D20.Command
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Ruleset
  alias D20.Sessions.Session

  @impl :gen_statem
  def callback_mode, do: [:handle_event_function, :state_enter]

  def handle_event(:enter, _old_state, :preparing_round, {_slug, Game, session}) do
    command = prepare_command(session.game)

    {:keep_state_and_data, [{:state_timeout, 0, {:prepare_round, command}}]}
  end

  def handle_event(
        :state_timeout,
        {:prepare_round, %Command{} = command},
        :preparing_round,
        {slug, Game, session} = data
      ) do
    case Session.dispatch(session, Game, command) do
      {:ok, %Session{} = updated_session} ->
        broadcast(updated_session)

        {:next_state, updated_session.game.phase, {slug, Game, updated_session}, [idle_action()]}

      {:error, reason} ->
        {:stop, {:invalid_random_setup, reason}, data}
    end
  end

  @doc false
  @spec prepare_command(Game.t()) :: Command.t()
  def prepare_command(%Game{} = game) do
    %Command{event: "prepare_round", attrs: prepare_attrs(game)}
  end

  defp prepare_attrs(game) do
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
