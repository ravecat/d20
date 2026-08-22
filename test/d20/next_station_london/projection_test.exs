defmodule D20.NextStationLondon.ProjectionTest do
  use ExUnit.Case, async: true

  alias D20.Accounts.Scope
  alias D20.Actors.Actor
  alias D20.NextStationLondon.Game
  alias D20.NextStationLondon.Projection
  alias D20.Sessions.Session

  test "renders a complete public read model and caller-only legal choices" do
    session = build_session()
    projection = Projection.render(scope("owner"), session)

    assert %{
             id: "session-1",
             phase: :in_progress,
             owner_id: "owner",
             self: "owner",
             objectives: [:all_districts, :central_district],
             powers: %{green: :double_section},
             permissions: %{can_draw: true, can_pass: true},
             game: %{
               phase: :turn,
               round: 1,
               current_instruction: %{destination: :square},
               reveals: [%{cards: ["street_square"]}],
               players: %{"owner" => owner, "p2" => _other},
               scores: %{"owner" => %{total: _total}},
               outcome: nil
             }
           } = projection

    assert owner.current_color == :green
    assert owner.status == :pending
    assert projection.options.power == :double_section
    assert %{from: "r2c3", to: "r1c3"} in projection.options.sections
    assert projection.options.double_sections != []

    refute Map.has_key?(projection.game, :remaining_deck)
    refute Map.has_key?(projection.game, :draws)
    refute Map.has_key?(projection, :variants)
    refute Map.has_key?(projection, :attrs)
    refute Map.has_key?(projection.game, :order)
    refute Map.has_key?(owner, :options)
  end

  test "omits runtime attrs when start has no game-specific fields" do
    game = %Game{phase: :setup, players: %{"owner" => Game.initial_player()}}

    session = %Session{
      id: "session-1",
      phase: :waiting_for_players,
      owner_id: "owner",
      members: %{"owner" => %{}},
      game: game
    }

    owner = Projection.render(scope("owner"), session)
    spectator = Projection.render(scope("spectator"), session)

    assert owner.permissions.can_start_game
    refute Map.has_key?(owner, :attrs)
    refute Map.has_key?(spectator, :attrs)
  end

  test "hides options from submitted players, other players, and spectators" do
    session = build_session()

    spectator = Projection.render(scope("spectator"), session)
    assert spectator.options == empty_options()

    assert spectator.permissions == %{can_start_game: false, can_draw: false, can_pass: false}

    submitted_session = put_in(session.game.players["owner"].status, :submitted)
    submitted = Projection.render(scope("owner"), submitted_session)

    assert submitted.options == empty_options()
    assert submitted.permissions.can_draw == false
    assert submitted.permissions.can_pass == false
  end

  test "renders reveal without an active instruction or mutation options" do
    session = build_session()
    session = %{session | game: %{session.game | phase: :reveal}}
    projection = Projection.render(scope("owner"), session)

    assert projection.game.current_instruction == nil
    assert [%{cards: ["street_square"]}] = projection.game.reveals
    assert projection.options == empty_options()
    assert projection.permissions.can_draw == false
    assert projection.permissions.can_pass == false
  end

  test "projects wildcard, switch, and Double Station alternatives from Rules" do
    joker = put_in(build_session().game.draws, [%{cards: ["street_joker"]}])
    joker_projection = Projection.render(scope("owner"), joker)

    assert Map.keys(joker_projection.options.wildcard_sections) |> MapSet.new() ==
             MapSet.new([:circle, :square, :triangle, :pentagon])

    switch = build_session()
    switch = put_in(switch.game.powers, %{green: :railroad_switch})

    switch = put_in(switch.game.players["owner"].lines.green.edges, ["r1c3-r2c3", "r0c2-r1c3"])

    switch_projection = Projection.render(scope("owner"), switch)
    assert switch_projection.options.power == :railroad_switch
    assert switch_projection.options.switch_sections != []

    double_station = put_in(build_session().game.powers, %{green: :double_station})
    station_projection = Projection.render(scope("owner"), double_station)

    assert "r2c3" in station_projection.options.double_station_targets
    refute "r1c3" in station_projection.options.double_station_targets

    assert %{section: %{from: "r2c3", to: "r1c3"}, targets: targets} =
             Enum.find(
               station_projection.options.double_station_sections,
               &(&1.section == %{from: "r2c3", to: "r1c3"})
             )

    assert "r2c3" in targets
    assert "r1c3" in targets
  end

  test "renders final scores and outcome without exposing future cards" do
    session = %{build_session() | phase: :finished}
    session = %{session | game: %{session.game | phase: :finished}}
    projection = Projection.render(scope("spectator"), session)

    assert %{mode: :multiplayer, winners: winners} = projection.game.outcome
    assert winners != []
    assert projection.options == empty_options()
    refute Map.has_key?(projection.game, :remaining_deck)
  end

  test "routes through the explicit web projection instead of returning the raw Session" do
    session = build_session()
    rendered = D20Web.Projection.render(scope("owner"), session)

    assert rendered == Projection.render(scope("owner"), session)
    refute match?(%Session{}, rendered)
  end

  defp build_session do
    owner = %{Game.initial_player() | status: :pending, pencil_offset: 0}
    other = %{Game.initial_player() | status: :pending, pencil_offset: 1}

    %Session{
      id: "session-1",
      phase: :in_progress,
      owner_id: "owner",
      members: %{"owner" => %{}, "p2" => %{}},
      game: %Game{
        phase: :turn,
        round: 1,
        players: %{"owner" => owner, "p2" => other},
        objectives: [:all_districts, :central_district],
        powers: %{green: :double_section},
        pencil_cycle: [:green, :blue, :pink, :purple],
        remaining_deck: ["underground_circle"],
        draws: [%{cards: ["street_square"]}]
      }
    }
  end

  defp scope(actor_id) do
    Scope.for_actor(%Actor{id: actor_id, type: :anonymous})
  end

  defp empty_options do
    %{
      sections: [],
      wildcard_sections: %{},
      joker_sections: [],
      switch_sections: [],
      double_sections: [],
      double_station_targets: [],
      double_station_sections: [],
      power: nil
    }
  end
end
