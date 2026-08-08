defmodule D20.Accounts.UserNotifierTest do
  use ExUnit.Case, async: false

  alias D20.Accounts.User
  alias D20.Accounts.UserNotifier

  setup do
    previous_mailer_config = Application.fetch_env!(:d20, D20.Mailer)
    previous_api_client = Application.fetch_env!(:swoosh, :api_client)

    Application.put_env(:d20, D20.Mailer,
      adapter: Swoosh.Adapters.Resend,
      api_key: "resend_test_key"
    )

    Application.put_env(:swoosh, :api_client, D20.TestResendApiClient)

    on_exit(fn ->
      Application.put_env(:d20, D20.Mailer, previous_mailer_config)
      Application.put_env(:swoosh, :api_client, previous_api_client)
    end)

    :ok
  end

  test "delivers configured authentication email through the Resend adapter" do
    user = %User{email: "player@example.com", confirmed_at: DateTime.utc_now()}
    url = "https://d20.ravecat.io/users/log-in/token"

    assert {:ok,
            %Swoosh.Email{
              from: {"D20", "noreply@d20.ravecat.io"},
              reply_to: {"D20 Support", "support@ravecat.io"},
              subject: "Log in instructions"
            } = email} = UserNotifier.deliver_login_instructions(user, url)

    assert_receive {:resend_request, "https://api.resend.com/emails", headers, body, ^email}
    assert {"Authorization", "Bearer resend_test_key"} in headers

    assert %{
             "from" => "D20 <noreply@d20.ravecat.io>",
             "reply_to" => "D20 Support <support@ravecat.io>",
             "subject" => "Log in instructions",
             "text" => text,
             "to" => ["player@example.com"]
           } = Jason.decode!(body)

    assert text =~ url
  end

  test "returns a Resend transport timeout without retrying" do
    D20.TestResendApiClient.respond_with({:error, :timeout})
    user = %User{email: "player@example.com", confirmed_at: DateTime.utc_now()}

    assert {:error, :timeout} =
             UserNotifier.deliver_login_instructions(
               user,
               "https://d20.ravecat.io/users/log-in/token"
             )

    assert_receive {:resend_request, "https://api.resend.com/emails", _headers, _body, _email}
    refute_receive {:resend_request, _url, _headers, _body, _email}
  end
end
