defmodule D20Web.PresenceTest do
  use ExUnit.Case, async: true

  alias D20Web.Presence
  alias D20Web.SessionChannel

  test "broadcasts online status from Presence joins with metadata" do
    session_id = Ecto.UUID.generate()
    topic = SessionChannel.topic(session_id)
    :ok = Presence.subscribe(session_id)

    assert {:ok, %{}} =
             Presence.handle_metas(
               topic,
               %{joins: %{"actor-1" => %{metas: [%{online_at: 123}]}}, leaves: %{}},
               %{"actor-1" => %{metas: [%{online_at: 123}]}},
               %{}
             )

    assert_receive {:online, "actor-1", %{online_at: 123}}
  end

  test "broadcasts offline status only after the last Presence meta leaves" do
    session_id = Ecto.UUID.generate()
    topic = SessionChannel.topic(session_id)
    :ok = Presence.subscribe(session_id)
    Phoenix.PubSub.subscribe(D20.PubSub, topic)

    assert {:ok, %{}} =
             Presence.handle_metas(
               topic,
               %{joins: %{}, leaves: %{"actor-1" => %{metas: [%{}]}}},
               %{"actor-1" => %{metas: [%{}]}},
               %{}
             )

    refute_receive {:offline, "actor-1"}
    refute_receive :projection

    assert {:ok, %{}} =
             Presence.handle_metas(
               topic,
               %{joins: %{}, leaves: %{"actor-1" => %{metas: [%{}]}}},
               %{},
               %{}
             )

    assert_receive {:offline, "actor-1"}
    refute_receive :projection
  end
end
