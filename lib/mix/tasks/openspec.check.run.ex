defmodule Mix.Tasks.Openspec.Check.Run do
  @moduledoc false

  use Mix.Task

  @issue_url ~r{https://github\.com/[^/\s]+/[^/\s]+/issues/\d+}
  @validate_args ["validate", "--all", "--strict", "--no-interactive"]
  @list_args ["list", "--json"]

  @type command_runner ::
          (String.t(), [String.t()], keyword() -> {String.t(), non_neg_integer()})

  @impl Mix.Task
  def run(_args) do
    case check(File.cwd!(), &System.cmd/3) do
      {:ok, %{active_changes: count}} ->
        Mix.shell().info("OpenSpec lifecycle check passed for #{count} active changes.")

      {:error, message} ->
        Mix.raise(message)
    end
  end

  @doc false
  @spec check(Path.t(), command_runner()) ::
          {:ok, %{active_changes: non_neg_integer()}} | {:error, String.t()}
  def check(root, command_runner) do
    with {:ok, _output} <- run_openspec(root, @validate_args, command_runner, "validation"),
         {:ok, output} <- run_openspec(root, @list_args, command_runner, "active change listing"),
         {:ok, changes} <- decode_changes(output) do
      completed = completed_changes(changes)
      unlinked = unlinked_changes(root, changes)

      lifecycle_result(changes, completed, unlinked)
    end
  end

  defp run_openspec(root, args, command_runner, operation) do
    case command_runner.("openspec", args, cd: root, stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}

      {output, status} ->
        {:error,
         "OpenSpec #{operation} failed with exit status #{status}:\n#{String.trim(output)}"}
    end
  rescue
    error in ErlangError ->
      {:error, "OpenSpec #{operation} could not start: #{Exception.message(error)}"}
  end

  defp decode_changes(output) do
    case Jason.decode(output) do
      {:ok, %{"changes" => changes}} when is_list(changes) ->
        validate_changes(changes)

      {:ok, _value} ->
        {:error, "OpenSpec active change listing has an unexpected JSON shape."}

      {:error, error} ->
        {:error, "OpenSpec active change listing is not valid JSON: #{Exception.message(error)}"}
    end
  end

  defp validate_changes(changes) do
    if Enum.all?(changes, &valid_change?/1) do
      {:ok, changes}
    else
      {:error, "OpenSpec active change listing contains an invalid change entry."}
    end
  end

  defp valid_change?(%{"name" => name, "status" => status})
       when is_binary(name) and is_binary(status),
       do: true

  defp valid_change?(_change), do: false

  defp completed_changes(changes) do
    changes
    |> Enum.filter(&(&1["status"] == "complete"))
    |> Enum.map(& &1["name"])
    |> Enum.sort()
  end

  defp unlinked_changes(root, changes) do
    changes
    |> Enum.reject(&linked_proposal?(root, &1["name"]))
    |> Enum.map(& &1["name"])
    |> Enum.sort()
  end

  defp linked_proposal?(root, change_name) do
    proposal = Path.join([root, "openspec", "changes", change_name, "proposal.md"])

    case File.read(proposal) do
      {:ok, content} -> Regex.match?(@issue_url, content)
      {:error, _reason} -> false
    end
  end

  defp lifecycle_result(changes, [], []), do: {:ok, %{active_changes: length(changes)}}

  defp lifecycle_result(_changes, completed, unlinked) do
    messages =
      []
      |> append_violation(completed, "completed active changes must be reconciled and archived")
      |> append_violation(
        unlinked,
        "active changes must link their owning GitHub Issue in proposal.md"
      )

    {:error, "OpenSpec lifecycle check failed:\n- #{Enum.join(messages, "\n- ")}"}
  end

  defp append_violation(messages, [], _description), do: messages

  defp append_violation(messages, changes, description) do
    messages ++ ["#{description}: #{Enum.join(changes, ", ")}"]
  end
end
