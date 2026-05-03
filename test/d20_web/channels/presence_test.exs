defmodule D20Web.PresenceTest do
  use ExUnit.Case, async: true

  alias D20Web.Presence

  test "broadcasts join from presence joins" do
    topic = unique_topic()
    :ok = Presence.subscribe(topic)

    assert {:ok, %{}} =
             Presence.handle_metas(
               topic,
               %{joins: %{"actor-1" => %{metas: [%{}]}}, leaves: %{}},
               %{"actor-1" => %{metas: [%{}]}},
               %{}
             )

    assert_receive {:join, "actor-1"}
  end

  test "broadcasts left only to the presence topic after the last meta leaves" do
    topic = unique_topic()
    :ok = Presence.subscribe(topic)
    Phoenix.PubSub.subscribe(D20.PubSub, topic)

    assert {:ok, %{}} =
             Presence.handle_metas(
               topic,
               %{joins: %{}, leaves: %{"actor-1" => %{metas: [%{}]}}},
               %{"actor-1" => %{metas: [%{}]}},
               %{}
             )

    refute_receive {:left, "actor-1"}
    refute_receive :projection

    assert {:ok, %{}} =
             Presence.handle_metas(
               topic,
               %{joins: %{}, leaves: %{"actor-1" => %{metas: [%{}]}}},
               %{},
               %{}
             )

    assert_receive {:left, "actor-1"}
    refute_receive :projection
  end

  defp unique_topic do
    "presence-test:#{System.unique_integer([:positive])}"
  end
end
