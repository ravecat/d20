defmodule D20.Sessions.RegistryTest do
  use ExUnit.Case, async: false

  alias D20.Sessions.Registry, as: SessionRegistry

  test "indexes many actors and sessions without duplicate owner entries" do
    first_session = start_owner()
    second_session = start_owner()

    on_exit(fn ->
      stop_owner(first_session)
      stop_owner(second_session)
    end)

    assert owner_call(first_session, {:attach, "actor-1", "session-1"}) == :attached
    assert owner_call(first_session, {:attach, "actor-1", "session-1"}) == :unchanged
    assert owner_call(first_session, {:attach, "actor-2", "session-1"}) == :attached
    assert owner_call(second_session, {:attach, "actor-1", "session-2"}) == :attached

    assert SessionRegistry.list("actor-1") |> Enum.sort() ==
             Enum.sort([{first_session, "session-1"}, {second_session, "session-2"}])

    assert SessionRegistry.list("actor-2") == [{first_session, "session-1"}]

    assert owner_call(first_session, {:detach, "actor-1"}) == :detached
    assert owner_call(first_session, {:detach, "actor-1"}) == :unchanged
    assert SessionRegistry.list("actor-1") == [{second_session, "session-2"}]
    assert SessionRegistry.list("actor-2") == [{first_session, "session-1"}]
  end

  test "removes every attachment owned by a terminated process" do
    terminating_session = start_owner()
    surviving_session = start_owner()

    on_exit(fn -> stop_owner(surviving_session) end)

    assert owner_call(terminating_session, {:attach, "actor-1", "session-1"}) == :attached
    assert owner_call(terminating_session, {:attach, "actor-2", "session-1"}) == :attached
    assert owner_call(surviving_session, {:attach, "actor-1", "session-2"}) == :attached

    partition = registry_partition()
    :erlang.trace(partition, true, [:receive])

    reference = Process.monitor(terminating_session)
    send(terminating_session, :stop)
    assert_receive {:DOWN, ^reference, :process, ^terminating_session, :normal}
    assert_registry_cleanup_received(partition, terminating_session)
    :sys.get_state(partition)
    :erlang.trace(partition, false, [:receive])

    assert SessionRegistry.list("actor-1") == [{surviving_session, "session-2"}]
    assert SessionRegistry.list("actor-2") == []
  end

  defp start_owner do
    spawn(fn -> owner_loop() end)
  end

  defp owner_loop do
    receive do
      {:call, caller, reference, {:attach, actor_id, session_id}} ->
        send(caller, {reference, SessionRegistry.attach(actor_id, session_id)})
        owner_loop()

      {:call, caller, reference, {:detach, actor_id}} ->
        send(caller, {reference, SessionRegistry.detach(actor_id)})
        owner_loop()

      :stop ->
        :ok
    end
  end

  defp owner_call(owner, request) do
    reference = make_ref()
    send(owner, {:call, self(), reference, request})
    assert_receive {^reference, result}
    result
  end

  defp stop_owner(owner) do
    if Process.alive?(owner), do: send(owner, :stop)
  end

  defp registry_partition do
    [{_id, partition, :worker, [Registry.Partition]}] =
      SessionRegistry |> Process.whereis() |> Supervisor.which_children()

    partition
  end

  defp assert_registry_cleanup_received(partition, owner) do
    receive do
      {:trace, ^partition, :receive, {:DOWN, _reference, :process, ^owner, :normal}} -> :ok
      {:trace, ^partition, :receive, {:EXIT, ^owner, :normal}} -> :ok
    after
      1_000 -> flunk("Registry did not observe the owner process termination")
    end
  end
end
