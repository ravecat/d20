defmodule D20Web.Auth.SteamTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest, only: [init_test_session: 2]

  alias D20Web.Auth.Steam
  alias Ueberauth.Auth

  describe "available?/0" do
    test "requires the community strategy and a nonblank API key" do
      previous_ueberauth = Application.fetch_env!(:ueberauth, Ueberauth)
      previous_steam = Application.get_env(:ueberauth, Ueberauth.Strategy.Steam, :not_configured)

      on_exit(fn ->
        Application.put_env(:ueberauth, Ueberauth, previous_ueberauth)

        case previous_steam do
          :not_configured -> Application.delete_env(:ueberauth, Ueberauth.Strategy.Steam)
          config -> Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, config)
        end
      end)

      Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, api_key: "steam-api-key")
      assert Steam.available?()

      for api_key <- [nil, "", "   "] do
        Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, api_key: api_key)
        refute Steam.available?()
      end

      Application.put_env(:ueberauth, Ueberauth.Strategy.Steam, api_key: "steam-api-key")

      Application.put_env(
        :ueberauth,
        Ueberauth,
        Keyword.update!(previous_ueberauth, :providers, &Keyword.delete(&1, :steam))
      )

      refute Steam.available?()
    end
  end

  describe "normalize/1" do
    test "keeps only the canonical SteamID and discards transient profile data" do
      auth = %Auth{
        provider: :steam,
        uid: 76_561_198_012_345_678,
        info: %Ueberauth.Auth.Info{name: "Transient persona", image: "https://steam/avatar"},
        extra: %Ueberauth.Auth.Extra{raw_info: %{user: %{realname: "Transient name"}}}
      }

      assert {:ok, %{provider: :steam, provider_uid: "76561198012345678"}} = Steam.normalize(auth)

      assert {:ok, %{provider: :steam, provider_uid: "76561198012345678"}} =
               Steam.normalize(%Auth{provider: "steam", uid: "76561198012345678"})
    end

    test "rejects another provider and malformed UIDs" do
      assert {:error, :unexpected_provider} =
               Steam.normalize(%Auth{provider: :google, uid: "76561198012345678"})

      for uid <- [nil, "", "0", "01234", "-5", "not-a-number"] do
        assert {:error, :invalid_provider_uid} =
                 Steam.normalize(%Auth{provider: :steam, uid: uid})
      end
    end
  end

  describe "failure_reason/1" do
    test "classifies Steam failures without retaining provider details" do
      failure = %Ueberauth.Failure{
        provider: :steam,
        errors: [
          %Ueberauth.Failure.Error{message_key: "invalid_user", message: "provider failed"}
        ]
      }

      assert Steam.failure_reason(failure) == :provider_failure
      assert Steam.failure_reason(%Ueberauth.Failure{provider: :google}) == :unexpected_provider
      assert Steam.failure_reason(:not_a_failure) == :invalid_provider_failure
    end
  end

  describe "authentication and link intents" do
    test "stores and consumes an authenticate intent within its lifetime" do
      conn = Steam.put_authenticate_intent(build_conn())
      assert {:ok, :authenticate} = Steam.fetch_intent(conn)
      assert {:ok, :authenticate} = Steam.fetch_intent(conn)
      {intent, conn} = Steam.take_intent(conn)
      assert {:ok, :authenticate} = intent
      assert {:error, :invalid_or_expired_intent} = Steam.fetch_intent(conn)
    end

    test "stores a user-bound link intent" do
      conn = Steam.put_link_intent(build_conn(), %{id: "user_123"})
      assert {:ok, {:link, "user_123"}} = Steam.fetch_intent(conn)
    end

    test "records the accepted safe return path in the intent" do
      conn =
        put_session(build_conn(), :return_to, "/games/qwinto") |> Steam.put_authenticate_intent()

      assert %{"action" => "authenticate", "return_to" => "/games/qwinto"} =
               Plug.Conn.get_session(conn, :steam_auth_intent)
    end

    test "rejects expired intents" do
      conn =
        put_session(build_conn(), :steam_auth_intent, %{
          "action" => "authenticate",
          "issued_at" => 0
        })

      assert {:error, :invalid_or_expired_intent} = Steam.fetch_intent(conn)
    end
  end

  describe "provider-only registration completion" do
    @steam_id "76561198012345678"

    test "reduces registration data to the canonical SteamID and nil email" do
      assert {:ok, %{provider_uid: @steam_id, email: nil}} =
               Steam.registration_data(%{provider: :steam, provider_uid: @steam_id})
    end

    test "stores and verifies session-bound completion state" do
      conn = Steam.put_registration(build_conn(), %{provider_uid: @steam_id})

      assert {:ok, %{provider_uid: @steam_id}} = Steam.fetch_registration(conn)
      assert is_binary(Plug.Conn.get_session(conn, :steam_registration_token))
      assert is_binary(Plug.Conn.get_session(conn, :steam_registration_nonce))
    end

    test "rejects missing, expired, and tampered completion state" do
      assert {:error, :invalid_or_expired_completion} = Steam.fetch_registration(build_conn())

      expired =
        Steam.put_registration(build_conn(), %{provider_uid: @steam_id},
          signed_at: System.system_time(:second) - 601
        )

      assert {:error, :invalid_or_expired_completion} = Steam.fetch_registration(expired)

      tampered =
        expired
        |> Steam.put_registration(%{provider_uid: @steam_id})
        |> put_session(:steam_registration_nonce, "different-browser-nonce")

      assert {:error, :invalid_or_expired_completion} = Steam.fetch_registration(tampered)
    end

    test "clears completion state" do
      conn =
        build_conn()
        |> Steam.put_registration(%{provider_uid: @steam_id})
        |> Steam.clear_registration()

      assert {:error, :invalid_or_expired_completion} = Steam.fetch_registration(conn)
      refute Plug.Conn.get_session(conn, :steam_registration_token)
      refute Plug.Conn.get_session(conn, :steam_registration_nonce)
    end
  end

  defp build_conn do
    init_test_session(Plug.Test.conn("GET", "/"), %{})
  end

  defp put_session(conn, key, value), do: Plug.Conn.put_session(conn, key, value)
end
