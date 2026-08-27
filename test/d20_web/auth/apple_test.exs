defmodule D20Web.Auth.AppleTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  alias D20Web.Auth.Apple
  alias Ueberauth.Auth
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Auth.Info

  describe "normalize/1" do
    test "keeps only the stable subject and valid optional email" do
      auth = %Auth{
        provider: :apple,
        uid: "000321.abc",
        info: %Info{email: "relay@privaterelay.appleid.com", name: "Private Name"},
        credentials: %Credentials{token: "secret-access-token"},
        extra: %Extra{raw_info: %{id_token: "secret-id-token"}}
      }

      assert {:ok,
              %{
                provider: :apple,
                provider_uid: "000321.abc",
                email: "relay@privaterelay.appleid.com"
              }} = Apple.normalize(auth)
    end

    test "accepts a returning subject when Apple no longer sends email" do
      auth = %Auth{provider: :apple, uid: "000321.abc", info: %Info{email: nil}}

      assert {:ok, %{email: nil, provider_uid: "000321.abc"}} = Apple.normalize(auth)
    end

    test "rejects another provider and malformed subject while discarding invalid email" do
      assert {:error, :unexpected_provider} =
               Apple.normalize(%Auth{provider: :google, uid: "subject", info: %Info{}})

      assert {:error, :invalid_provider_uid} =
               Apple.normalize(%Auth{provider: :apple, uid: "", info: %Info{}})

      assert {:error, :invalid_provider_uid} =
               Apple.normalize(%Auth{provider: :apple, uid: "   ", info: %Info{}})

      assert {:ok, identity} =
               Apple.normalize(%Auth{
                 provider: :apple,
                 uid: "subject",
                 info: %Info{email: "not-an-email"}
               })

      assert {:ok, %{provider_uid: "subject", email: nil}} = Apple.registration_data(identity)
    end
  end

  describe "flow state" do
    test "attempt state is encrypted, cross-site, short-lived, and consumed once" do
      response =
        Apple.put_attempt(build_conn(), %{
          action: :authenticate,
          return_to: "/tables/one",
          user_id: nil
        })

      cookie = response.resp_cookies[Apple.flow_cookie()]
      refute cookie.value =~ "authenticate"
      assert cookie.secure
      assert cookie.http_only
      assert cookie.same_site == "None"
      assert cookie.path == "/auth/apple"
      assert cookie.max_age == 600

      request = request_with_cookie(Apple.flow_cookie(), cookie.value)
      {consumed, result} = Apple.consume_attempt(request)

      assert {:ok, %{action: :authenticate, return_to: "/tables/one", user_id: nil}} = result
      assert consumed.resp_cookies[Apple.flow_cookie()].max_age == 0
      assert {_, {:error, :missing_flow_state}} = Apple.consume_attempt(build_conn())
    end

    test "attempt state binds links and rejects invalid, tampered, or expired values" do
      link_response =
        Apple.put_attempt(build_conn(), %{
          action: :link,
          return_to: "/users/settings",
          user_id: "user_123"
        })

      link_request = request_with_cookie(Apple.flow_cookie(), cookie_value(link_response))

      assert {_, {:ok, %{action: :link, user_id: "user_123"}}} =
               Apple.consume_attempt(link_request)

      reauthenticate_response =
        Apple.put_attempt(build_conn(), %{
          action: :reauthenticate,
          return_to: "/users/settings",
          user_id: "user_123"
        })

      reauthenticate_request =
        request_with_cookie(Apple.flow_cookie(), cookie_value(reauthenticate_response))

      assert {_, {:ok, %{action: :reauthenticate, user_id: "user_123"}}} =
               Apple.consume_attempt(reauthenticate_request)

      tampered_request =
        request_with_cookie(Apple.flow_cookie(), cookie_value(link_response) <> "tampered")

      assert {_, {:error, :invalid_flow_state}} = Apple.consume_attempt(tampered_request)

      invalid_response =
        Apple.put_attempt(build_conn(), %{
          action: :link,
          return_to: "/users/settings",
          user_id: nil
        })

      invalid_request = request_with_cookie(Apple.flow_cookie(), cookie_value(invalid_response))
      assert {_, {:error, :invalid_flow_state}} = Apple.consume_attempt(invalid_request)

      expired_response =
        Apple.put_attempt(build_conn(), %{action: :authenticate, return_to: "/", user_id: nil},
          signed_at: System.system_time(:second) - 601
        )

      expired_request = request_with_cookie(Apple.flow_cookie(), cookie_value(expired_response))
      assert {_, {:error, :expired_flow_state}} = Apple.consume_attempt(expired_request)
    end

    test "registration replaces the attempt with stricter state and remains retryable" do
      response =
        Apple.put_registration(build_conn(), %{
          provider_uid: "000321.abc",
          email: "relay@privaterelay.appleid.com",
          return_to: "/tables/one"
        })

      cookie = response.resp_cookies[Apple.flow_cookie()]
      refute cookie.value =~ "relay@privaterelay.appleid.com"
      assert cookie.secure
      assert cookie.http_only
      assert cookie.same_site == "Lax"
      assert cookie.path == "/auth/apple"
      assert cookie.max_age == 600

      request = request_with_cookie(Apple.flow_cookie(), cookie.value)

      assert {:ok,
              %{
                provider_uid: "000321.abc",
                email: "relay@privaterelay.appleid.com",
                return_to: "/tables/one"
              }} = Apple.fetch_registration(request)

      assert Apple.clear_registration(request).resp_cookies[Apple.flow_cookie()].max_age == 0
      assert {_, {:error, :invalid_flow_state}} = Apple.consume_attempt(request)

      without_email =
        Apple.put_registration(build_conn(), %{
          provider_uid: "000321.without-email",
          email: nil,
          return_to: "/"
        })

      without_email_request =
        request_with_cookie(Apple.flow_cookie(), cookie_value(without_email))

      assert {:ok, %{provider_uid: "000321.without-email", email: nil}} =
               Apple.fetch_registration(without_email_request)
    end

    test "registration rejects missing, wrong-phase, and expired flow state" do
      assert {:error, :missing_flow_state} = Apple.fetch_registration(build_conn())

      attempt_response =
        Apple.put_attempt(build_conn(), %{action: :authenticate, return_to: "/", user_id: nil})

      attempt_request = request_with_cookie(Apple.flow_cookie(), cookie_value(attempt_response))

      assert {:error, :invalid_flow_state} = Apple.fetch_registration(attempt_request)

      expired_response =
        Apple.put_registration(
          build_conn(),
          %{provider_uid: "000321.abc", email: "player@example.com", return_to: "/"},
          signed_at: System.system_time(:second) - 601
        )

      expired_request = request_with_cookie(Apple.flow_cookie(), cookie_value(expired_response))
      assert {:error, :expired_flow_state} = Apple.fetch_registration(expired_request)
    end

    test "link results use encrypted one-use state scoped to Account Settings" do
      response = Apple.put_link_result(build_conn(), :conflict)
      cookie = response.resp_cookies[Apple.link_result_cookie()]

      refute cookie.value =~ "conflict"
      assert cookie.secure
      assert cookie.http_only
      assert cookie.same_site == "Lax"
      assert cookie.path == "/users/settings"
      assert cookie.max_age == 600

      consumed =
        Apple.link_result_cookie()
        |> request_with_cookie(cookie.value)
        |> init_test_session(%{})
        |> Phoenix.Controller.fetch_flash([])
        |> Apple.call(:link_result)

      assert consumed.halted
      assert redirected_to(consumed) == "/users/settings"
      assert consumed.resp_cookies[Apple.link_result_cookie()].max_age == 0

      assert Phoenix.Flash.get(consumed.assigns.flash, :error) ==
               "Apple could not be linked because that identity is unavailable."

      expired_response =
        Apple.put_link_result(build_conn(), :failed, signed_at: System.system_time(:second) - 601)

      expired =
        Apple.link_result_cookie()
        |> request_with_cookie(expired_response.resp_cookies[Apple.link_result_cookie()].value)
        |> init_test_session(%{})
        |> Phoenix.Controller.fetch_flash([])
        |> Apple.call(:link_result)

      refute expired.halted
      assert expired.resp_cookies[Apple.link_result_cookie()].max_age == 0
      assert Phoenix.Flash.get(expired.assigns.flash, :error) == nil
    end
  end

  defp request_with_cookie(name, value) do
    put_req_cookie(build_conn(), name, value)
  end

  defp cookie_value(conn), do: conn.resp_cookies[Apple.flow_cookie()].value
end
