defmodule D20Web.PresenceTest do
  use ExUnit.Case, async: true

  alias D20Web.Presence

  @presence_topic "presence:any-topic"

  test "broadcasts join from presence joins" do
    Phoenix.PubSub.subscribe(D20.PubSub, @presence_topic)

    assert {:ok, %{}} =
             Presence.handle_metas(
               "any-topic",
               %{joins: %{"actor-1" => %{metas: [%{}]}}, leaves: %{}},
               %{"actor-1" => %{metas: [%{}]}},
               %{}
             )

    assert_receive {:join, "actor-1"}
  end

  test "broadcasts left only after the last meta leaves" do
    Phoenix.PubSub.subscribe(D20.PubSub, @presence_topic)
    Phoenix.PubSub.subscribe(D20.PubSub, "any-topic")

    assert {:ok, %{}} =
             Presence.handle_metas(
               "any-topic",
               %{joins: %{}, leaves: %{"actor-1" => %{metas: [%{}]}}},
               %{"actor-1" => %{metas: [%{}]}},
               %{}
             )

    refute_receive {:left, "actor-1"}
    refute_receive :projection

    assert {:ok, %{}} =
             Presence.handle_metas(
               "any-topic",
               %{joins: %{}, leaves: %{"actor-1" => %{metas: [%{}]}}},
               %{},
               %{}
             )

    assert_receive {:left, "actor-1"}
    assert_receive :projection
  end
end
