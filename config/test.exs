import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :d20, D20.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "d20_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :d20, D20Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Mzij4XkWW1nq/dbTyhMn0ci6O25B16e6jX6aRZeyrA23dnzflzLhFdJYOBPOND1d",
  server: false,
  # Render Vite dev URLs in tests so controller tests do not depend on built assets.
  watchers: [vite: {Bun, :install_and_run, [:vite, ~w(dev)]}],
  static_url: [host: "localhost", port: 5174]

# In test we don't send emails
config :d20, D20.Mailer, adapter: Swoosh.Adapters.Test

config :d20, session_idle_timeout: :infinity

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
