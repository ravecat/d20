defmodule D20.NextStationLondon.CommandTest do
  use ExUnit.Case, async: true

  alias D20.Command
  alias D20.NextStationLondon.Command, as: LondonCommand
  alias D20.NextStationLondon.Ruleset

  test "normalizes empty start and bounded player commands" do
    assert {:ok, %Command{event: "join", attrs: %{}}} =
             LondonCommand.validate(%Command{
               event: "join",
               actor_id: "p1",
               attrs: %{ignored: true}
             })

    assert {:ok, %Command{event: "leave", attrs: %{}}} =
             LondonCommand.validate(%Command{event: "leave", actor_id: "p1"})

    assert {:ok, %Command{attrs: %{}}} =
             LondonCommand.validate(%Command{event: "start", actor_id: "p1", attrs: %{}})
  end

  test "normalizes actorless round preparation" do
    assert {:ok,
            %Command{
              attrs: %{
                deck: deck,
                pencil_cycle: [:green, :blue, :pink, :purple],
                pencil_offsets: %{"p1" => 0, "p2" => 1},
                objectives: [:all_districts, :central_district],
                powers: %{green: :joker, blue: :double_section}
              }
            }} =
             LondonCommand.validate(%Command{
               event: "prepare_round",
               attrs: %{
                 "deck" => Ruleset.card_ids(),
                 "pencil_cycle" => ~w(green blue pink purple),
                 "pencil_offsets" => %{"p1" => 0, "p2" => 1},
                 "objectives" => ~w(all_districts central_district),
                 "powers" => %{"green" => "joker", "blue" => "double_section"}
               }
             })

    assert deck == Ruleset.card_ids()
  end

  test "normalizes draw and pass payloads" do
    assert {:ok,
            %Command{
              attrs: %{
                sections: [%{from: "r2c3", to: "r1c3"}, %{from: "r1c3", to: "r0c2"}],
                power: :double_section,
                chosen_symbol: :square,
                power_target: nil
              }
            }} =
             LondonCommand.validate(%Command{
               event: "draw_sections",
               actor_id: "p1",
               attrs: %{
                 "sections" => [
                   %{"from" => "r2c3", "to" => "r1c3"},
                   %{"from" => "r1c3", "to" => "r0c2"}
                 ],
                 "power" => "double_section",
                 "chosen_symbol" => "square"
               }
             })

    assert {:ok, %Command{attrs: %{power: :double_station, power_target: "r2c3"}}} =
             LondonCommand.validate(%Command{
               event: "pass",
               actor_id: "p1",
               attrs: %{"power" => "double_station", "power_target" => "r2c3"}
             })
  end

  test "rejects malformed or unbounded payloads without creating atoms" do
    invalid_commands = [
      %Command{event: "start", attrs: []},
      %Command{event: "start", attrs: %{"pencil_order" => ~w(green blue pink purple)}},
      %Command{event: "prepare_round", attrs: %{"deck" => ["missing"]}},
      %Command{event: "prepare_round", attrs: %{"deck" => [], "extra" => true}},
      %Command{event: "draw_sections", attrs: %{"sections" => []}},
      %Command{event: "draw_sections", attrs: %{"sections" => [%{"from" => "r2c3"}]}},
      %Command{
        event: "draw_sections",
        attrs: %{"sections" => [%{"from" => "r2c3", "to" => "missing"}]}
      },
      %Command{event: "pass", attrs: %{"power" => "unknown"}},
      %Command{event: "pass", attrs: %{"unexpected" => true}}
    ]

    assert Enum.all?(invalid_commands, fn command ->
             LondonCommand.validate(command) == {:error, :invalid_command}
           end)

    assert {:error, :unknown_command} =
             LondonCommand.validate(%Command{event: "missing", attrs: %{}})
  end
end
