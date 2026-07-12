defmodule D20Web.Plugs.AsyncApiTest do
  use D20Web.ConnCase, async: true

  test "routes each public reference to its matching raw contract" do
    specifications = [
      {"/developers/specs/qwinto", "/developers/specs/qwinto/raw",
       "title: Game Session Async API"},
      {"/developers/specs/koala-rescue-club", "/developers/specs/koala-rescue-club/raw",
       "title: Koala Rescue Club Session Async API"}
    ]

    for {reference_path, raw_path, expected_title} <- specifications do
      reference_conn = get(build_conn(), reference_path)
      raw_conn = get(build_conn(), raw_path)

      reference = html_response(reference_conn, 200)

      assert reference =~ "<title>AsyncAPI Reference</title>"
      assert reference =~ "@asyncapi/react-component@3.1.3/browser/standalone/index.js"
      assert reference =~ "#asyncapi { max-width: 100vw; overflow-x: auto; }"
      assert reference =~ "schema: { url: #{Jason.encode!(raw_path, escape: :html_safe)} }"
      assert reference =~ "AsyncApiStandalone.render"

      assert response(raw_conn, 200) =~ expected_title
      assert ["text/yaml; charset=utf-8"] = get_resp_header(raw_conn, "content-type")
    end
  end

  test "returns not found for a registered game without a specification" do
    for path <- ["/developers/specs/aquamarine", "/developers/specs/aquamarine/raw"] do
      assert response(get(build_conn(), path), 404) == "Not found"
    end
  end

  test "returns not found for an unknown game slug" do
    for path <- ["/developers/specs/unknown-game", "/developers/specs/unknown-game/raw"] do
      assert response(get(build_conn(), path), 404) == "Not found"
    end
  end
end
