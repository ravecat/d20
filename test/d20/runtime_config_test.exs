defmodule D20.RuntimeConfigTest do
  use ExUnit.Case, async: false

  @provider_env ~w(FACEBOOK_OAUTH_CLIENT_ID FACEBOOK_OAUTH_CLIENT_SECRET STEAM_API_KEY)

  setup do
    previous_env = Map.new(@provider_env, &{&1, System.get_env(&1)})

    on_exit(fn -> restore_env(previous_env) end)
  end

  test "Facebook OAuth reads both optional runtime credentials" do
    System.put_env("FACEBOOK_OAUTH_CLIENT_ID", "facebook-client-id")
    System.put_env("FACEBOOK_OAUTH_CLIENT_SECRET", "facebook-client-secret")

    assert facebook_config() == [
             client_id: "facebook-client-id",
             client_secret: "facebook-client-secret"
           ]
  end

  test "Facebook OAuth normalizes missing and blank credentials without failing startup" do
    System.delete_env("FACEBOOK_OAUTH_CLIENT_ID")
    System.put_env("FACEBOOK_OAUTH_CLIENT_SECRET", "   ")

    assert facebook_config() == [client_id: nil, client_secret: nil]
  end

  test "normalizes the community Steam adapter API key" do
    System.put_env("STEAM_API_KEY", "steam-api-key")
    assert steam_config() == [api_key: "steam-api-key"]

    for value <- ["", "   "] do
      System.put_env("STEAM_API_KEY", value)
      assert steam_config() == [api_key: nil]
    end

    System.delete_env("STEAM_API_KEY")
    assert steam_config() == [api_key: nil]
  end

  defp facebook_config do
    runtime_config()
    |> Keyword.fetch!(:ueberauth)
    |> Keyword.fetch!(Ueberauth.Strategy.Facebook.OAuth)
  end

  defp steam_config do
    runtime_config()
    |> Keyword.fetch!(:ueberauth)
    |> Keyword.fetch!(Ueberauth.Strategy.Steam)
  end

  defp runtime_config do
    Config.Reader.read!("config/runtime.exs", env: :test, target: :host)
  end

  defp restore_env(previous_env) do
    Enum.each(previous_env, fn
      {name, nil} -> System.delete_env(name)
      {name, value} -> System.put_env(name, value)
    end)
  end
end
