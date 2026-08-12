defmodule D20.RuntimeConfigTest do
  use ExUnit.Case, async: false

  @runtime_env %{
    "BGG_API_KEY" => "bgg_test_key",
    "DATABASE_URL" => "ecto://postgres:postgres@localhost/d20_test",
    "GOOGLE_OAUTH_CLIENT_ID" => "google-client-id",
    "GOOGLE_OAUTH_CLIENT_SECRET" => "google-client-secret",
    "RESEND_API_KEY" => "resend_test_key",
    "SECRET_KEY_BASE" => String.duplicate("s", 64)
  }
  @google_env ~w(GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET)

  setup do
    previous_env =
      (@google_env ++ Map.keys(@runtime_env))
      |> Map.new(fn name -> {name, System.get_env(name)} end)

    System.put_env(@runtime_env)

    on_exit(fn -> restore_env(previous_env) end)
  end

  test "production configures the Resend adapter with Req" do
    runtime_config = read_runtime_config()
    compile_config = Config.Reader.read!("config/config.exs", env: :prod, target: :host)

    assert Keyword.fetch!(application_config(runtime_config, :d20), D20.Mailer) == [
             adapter: Swoosh.Adapters.Resend,
             api_key: "resend_test_key"
           ]

    assert Keyword.fetch!(application_config(compile_config, :swoosh), :api_client) ==
             Swoosh.ApiClient.Req
  end

  test "production startup rejects a missing Resend API key without exposing other secrets" do
    System.delete_env("RESEND_API_KEY")

    error = assert_raise RuntimeError, fn -> read_runtime_config() end

    assert Exception.message(error) =~ "environment variable RESEND_API_KEY is missing"
    refute Exception.message(error) =~ "d20.ravecat.io"
    refute Exception.message(error) =~ @runtime_env["BGG_API_KEY"]
    refute Exception.message(error) =~ @runtime_env["DATABASE_URL"]
    refute Exception.message(error) =~ @runtime_env["SECRET_KEY_BASE"]
  end

  test "production startup rejects a blank Resend API key" do
    System.put_env("RESEND_API_KEY", "   ")

    assert_raise RuntimeError, ~r/environment variable RESEND_API_KEY is missing/, fn ->
      read_runtime_config()
    end
  end

  test "test environment keeps the Swoosh Test adapter" do
    assert Application.fetch_env!(:d20, D20.Mailer)[:adapter] == Swoosh.Adapters.Test
  end

  test "test runtime does not inject Google credential stand-ins" do
    Enum.each(@google_env, &System.delete_env/1)

    runtime_config = read_runtime_config(:test)

    assert Keyword.fetch!(
             application_config(runtime_config, :ueberauth),
             Ueberauth.Strategy.Google.OAuth
           ) == [client_id: nil, client_secret: nil]
  end

  test "Google OAuth configures runtime credentials without an enable flag" do
    runtime_config = read_runtime_config(:test)

    assert Keyword.fetch!(
             application_config(runtime_config, :ueberauth),
             Ueberauth.Strategy.Google.OAuth
           ) == [client_id: "google-client-id", client_secret: "google-client-secret"]
  end

  test "production starts with Google unavailable when the client ID is missing" do
    System.delete_env("GOOGLE_OAUTH_CLIENT_ID")

    runtime_config = read_runtime_config()

    assert Keyword.fetch!(
             application_config(runtime_config, :ueberauth),
             Ueberauth.Strategy.Google.OAuth
           ) == [client_id: nil, client_secret: "google-client-secret"]
  end

  test "production passes a blank Google client secret through unchanged" do
    System.put_env("GOOGLE_OAUTH_CLIENT_SECRET", "   ")

    runtime_config = read_runtime_config()

    assert Keyword.fetch!(
             application_config(runtime_config, :ueberauth),
             Ueberauth.Strategy.Google.OAuth
           ) == [client_id: "google-client-id", client_secret: "   "]
  end

  defp read_runtime_config(env \\ :prod) do
    Config.Reader.read!("config/runtime.exs", env: env, target: :host)
  end

  defp application_config(config, application) do
    Keyword.fetch!(config, application)
  end

  defp restore_env(previous_env) do
    Enum.each(previous_env, fn
      {name, nil} -> System.delete_env(name)
      {name, value} -> System.put_env(name, value)
    end)
  end
end
