defmodule D20.TestResendApiClient do
  @moduledoc false

  @behaviour Swoosh.ApiClient

  @impl true
  def init, do: :ok

  @impl true
  def post(url, headers, body, email) do
    send(self(), {:resend_request, IO.iodata_to_binary(url), headers, body, email})

    Process.get({__MODULE__, :response}, {:ok, 200, [], Jason.encode!(%{id: "email_test_123"})})
  end

  @doc false
  def respond_with(response), do: Process.put({__MODULE__, :response}, response)
end
