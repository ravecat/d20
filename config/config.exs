# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :d20, :scopes,
  user: [
    default: true,
    module: D20.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: D20.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :bun,
  version: "1.3.13",
  assets: [args: [], cd: Path.expand("../assets", __DIR__)],
  vite: [
    args: ~w(x vite),
    cd: Path.expand("../assets", __DIR__),
    env: %{"MIX_BUILD_PATH" => Mix.Project.build_path()}
  ]

config :d20,
  ecto_repos: [D20.Repo],
  generators: [timestamp_type: :utc_datetime]

config :d20, D20.Actors.ActorToken,
  salt: "actor",
  max_age: 1_209_600

config :d20, D20.Module.Manifest,
  path: "priv/modules/#{config_env()}.json",
  engines: [qwinto: D20.Qwinto.Game]

config :d20, D20.Module.Token,
  salt: "module",
  max_age: 600

# Configures the endpoint
config :d20, D20Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [formats: [html: D20Web.ErrorHTML, json: D20Web.ErrorJSON], layout: false],
  pubsub_server: D20.PubSub,
  live_view: [signing_salt: "EPfGcCGF"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :d20, D20.Mailer, adapter: Swoosh.Adapters.Local

config :inertia,
  endpoint: D20Web.Endpoint,
  static_paths: ["/assets/js/app.js"],
  default_version: "1",
  camelize_props: true,
  history: [encrypt: false],
  ssr: false,
  raise_on_ssr_failure: config_env() != :prod

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
