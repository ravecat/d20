defmodule D20.Repo do
  use Ecto.Repo,
    otp_app: :d20,
    adapter: Ecto.Adapters.Postgres
end
