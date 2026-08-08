defmodule D20.FailingMailerAdapter do
  @moduledoc false

  use Swoosh.Adapter

  @impl true
  def deliver(_email, config),
    do: {:error, Keyword.get(config, :failure_reason, :delivery_failed)}
end
