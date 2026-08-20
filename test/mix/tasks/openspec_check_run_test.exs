defmodule Mix.Tasks.Openspec.Check.RunTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Openspec.Check.Run

  test "accepts a valid incomplete catalog without changing proposals" do
    root = temporary_root!()
    proposal = write_proposal!(root, "linked-change", "https://github.com/ravecat/d20/issues/153")
    original = File.read!(proposal)

    assert {:ok, %{active_changes: 1}} =
             Run.check(
               root,
               runner({"valid", 0}, {changes_json("linked-change", "in-progress"), 0})
             )

    assert File.read!(proposal) == original
  end

  test "returns strict validation failures without listing changes" do
    command_runner = fn
      "openspec", ["validate" | _args], _options -> {"invalid specification", 1}
      "openspec", ["list" | _args], _options -> flunk("list must not run after validation fails")
    end

    assert {:error, message} = Run.check("/tmp", command_runner)
    assert message =~ "OpenSpec validation failed with exit status 1"
    assert message =~ "invalid specification"
  end

  test "rejects a completed active change" do
    root = temporary_root!()
    write_proposal!(root, "completed-change", "https://github.com/ravecat/d20/issues/153")

    assert {:error, message} =
             Run.check(
               root,
               runner({"valid", 0}, {changes_json("completed-change", "complete"), 0})
             )

    assert message =~ "completed active changes must be reconciled and archived: completed-change"
  end

  test "rejects an active change without a GitHub Issue link" do
    root = temporary_root!()
    write_proposal!(root, "unlinked-change", "No delivery link")

    assert {:error, message} =
             Run.check(
               root,
               runner({"valid", 0}, {changes_json("unlinked-change", "in-progress"), 0})
             )

    assert message =~
             "active changes must link their owning GitHub Issue in proposal.md: unlinked-change"
  end

  test "returns active change listing command failures" do
    assert {:error, message} = Run.check("/tmp", runner({"valid", 0}, {"list failed", 2}))

    assert message =~ "OpenSpec active change listing failed with exit status 2"
    assert message =~ "list failed"
  end

  test "rejects malformed active change JSON" do
    assert {:error, message} = Run.check("/tmp", runner({"valid", 0}, {"not-json", 0}))

    assert message =~ "OpenSpec active change listing is not valid JSON"
  end

  defp runner(validation_result, list_result) do
    fn
      "openspec", ["validate" | _args], _options -> validation_result
      "openspec", ["list" | _args], _options -> list_result
    end
  end

  defp changes_json(name, status) do
    Jason.encode!(%{"changes" => [%{"name" => name, "status" => status}]})
  end

  defp temporary_root! do
    root =
      Path.join(
        System.tmp_dir!(),
        "d20-openspec-check-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end

  defp write_proposal!(root, change_name, content) do
    change_root = Path.join([root, "openspec", "changes", change_name])
    File.mkdir_p!(change_root)
    proposal = Path.join(change_root, "proposal.md")
    File.write!(proposal, content)
    proposal
  end
end
