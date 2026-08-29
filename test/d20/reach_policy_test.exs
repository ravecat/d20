defmodule D20.ReachPolicyTest do
  @moduledoc """
  Covers the `.reach.exs` architecture boundary policy: a pure D20 domain
  dependency on `D20Web.*` must be rejected, while the classified runtime
  adapter's intentional web dependency stays allowed.
  """

  use ExUnit.Case, async: true

  @policy_path Path.expand("../../.reach.exs", __DIR__)
  @policy @policy_path |> Code.eval_file() |> elem(0)

  test "pure domain module depending on D20Web is rejected" do
    project =
      project_from_sources(%{
        "domain_probe.ex" => """
        defmodule D20.PolicyProbe.Domain do
          def url, do: D20Web.Endpoint.url()
        end
        """,
        "web_probe.ex" => """
        defmodule D20Web.Endpoint.Probe do
          def url, do: "https://example.test"
        end
        """
      })

    result = Reach.Check.Architecture.run(project, @policy)

    violation =
      Enum.find(result.violations, fn violation ->
        violation.type == :forbidden_dependency and
          violation.caller_module == "D20.PolicyProbe.Domain"
      end)

    assert violation, "expected a forbidden domain-to-web dependency violation"
    assert violation.caller_layer == :domain
    assert violation.callee_layer == :web
    assert violation.callee_module == "D20Web.Endpoint"
  end

  test "runtime adapter depending on D20Web remains allowed" do
    project =
      project_from_sources(%{
        "adapter_probe.ex" => """
        defmodule D20.Sessions.Server do
          def broadcast, do: D20Web.Presence.list("topic")
        end
        """,
        "presence_probe.ex" => """
        defmodule D20Web.Presence do
          def list(topic), do: topic
        end
        """
      })

    result = Reach.Check.Architecture.run(project, @policy)

    refute Enum.any?(
             result.violations,
             &(&1.type == :forbidden_dependency and &1.caller_module == "D20.Sessions.Server")
           ),
           "runtime adapter web dependency must not be classified as a domain violation"

    assert Reach.Check.Architecture.module_matches_any?(
             D20.Sessions.Server,
             @policy[:layers][:runtime]
           )

    refute Reach.Check.Architecture.module_matches_any?(
             D20.PolicyProbe.Domain,
             @policy[:layers][:runtime]
           )
  end

  defp project_from_sources(sources) do
    dir = Path.join(System.tmp_dir!(), "d20_reach_probe_#{System.unique_integer()}")

    File.mkdir_p!(dir)

    try do
      paths =
        for {name, source} <- sources do
          path = Path.join(dir, name)
          File.write!(path, source)
          path
        end

      Reach.Project.from_sources(paths)
    after
      File.rm_rf!(dir)
    end
  end
end
