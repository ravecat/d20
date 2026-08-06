defmodule D20.FailingMailerAdapter do
  @moduledoc false

  use Swoosh.Adapter

  @impl true
  def deliver(_email, _config), do: {:error, :delivery_failed}
end
