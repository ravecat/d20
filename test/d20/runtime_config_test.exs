defmodule D20.RuntimeConfigTest do
  use ExUnit.Case, async: false

  @runtime_env %{
    "BGG_API_KEY" => "bgg_test_key",
    "DATABASE_URL" => "ecto://postgres:postgres@localhost/d20_test",
    "RESEND_API_KEY" => "resend_test_key",
    "SECRET_KEY_BASE" => String.duplicate("s", 64)
  }

  setup do
    previous_env = Map.new(@runtime_env, fn {name, _value} -> {name, System.get_env(name)} end)
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

  defp read_runtime_config do
    Config.Reader.read!("config/runtime.exs", env: :prod, target: :host)
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
