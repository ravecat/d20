defmodule D20.RuntimeConfigTest do
  use ExUnit.Case, async: false

  @facebook_env ~w(FACEBOOK_OAUTH_CLIENT_ID FACEBOOK_OAUTH_CLIENT_SECRET)

  setup do
    previous_env = Map.new(@facebook_env, &{&1, System.get_env(&1)})

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

  defp facebook_config do
    runtime_config = Config.Reader.read!("config/runtime.exs", env: :test, target: :host)

    runtime_config
    |> Keyword.fetch!(:ueberauth)
    |> Keyword.fetch!(Ueberauth.Strategy.Facebook.OAuth)
  end

  defp restore_env(previous_env) do
    Enum.each(previous_env, fn
      {name, nil} -> System.delete_env(name)
      {name, value} -> System.put_env(name, value)
    end)
  end
end
