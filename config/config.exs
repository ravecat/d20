# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :d20, :scopes,
  actor: [
    default: true,
    module: D20.Accounts.Scope,
    assign_key: :scope,
    access_path: [:actor, :id],
    schema_key: :actor_id,
    schema_type: :string,
    # Actor is not persisted; generated resources store actor_id directly.
    schema_table: nil,
    test_data_fixture: D20.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :bun,
  version: "1.3.13",
  path: System.get_env("MIX_BUN_PATH"),
  assets: [args: [], cd: Path.expand("../assets", __DIR__)],
  vite: [
    args: ~w(x vite),
    cd: Path.expand("../assets", __DIR__),
    env: %{"MIX_BUILD_PATH" => Mix.Project.build_path()}
  ]

config :backpex,
  pubsub_server: D20.PubSub,
  translator_function: {D20Web.CoreComponents, :translate_backpex},
  error_translator_function: {D20Web.CoreComponents, :translate_error}

config :d20,
  ecto_repos: [D20.Repo],
  generators: [timestamp_type: :utc_datetime],
  # Temporary gate until game availability is controlled by runtime feature flags or experiments.
  allow_launch_in_development: config_env() != :prod,
  session_idle_timeout: :timer.minutes(30)

# Steam OpenID assertions arrive in query parameters before the provider controller runs.
# Phoenix's global logging boundary must therefore redact them here; the Ueberauth adapter
# cannot prevent earlier endpoint/request logging from seeing the callback values.
config :phoenix, :filter_parameters, [
  "password",
  "openid.assoc_handle",
  "openid.claimed_id",
  "openid.identity",
  "openid.response_nonce",
  "openid.sig",
  "state"
]

# ueberauth_google 0.12.1 does not implement PKCE. D20 therefore uses it only as a
# confidential server-side client with state validation and a client-secret exchange.
config :ueberauth, Ueberauth,
  providers: [
    discord:
      {Ueberauth.Strategy.Discord,
       [
         default_scope: "identify email",
         request_path: "/auth/discord",
         callback_path: "/auth/discord/callback"
       ]},
    facebook:
      {Ueberauth.Strategy.Facebook,
       [
         default_scope: "email",
         profile_fields: "id,email",
         request_path: "/auth/facebook",
         callback_path: "/auth/facebook/callback"
       ]},
    google:
      {Ueberauth.Strategy.Google,
       [
         default_scope: "openid email",
         userinfo_endpoint: "https://openidconnect.googleapis.com/v1/userinfo"
       ]},
    steam:
      {Ueberauth.Strategy.Steam,
       [request_path: "/auth/steam", callback_path: "/auth/steam/callback"]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  token_url: "https://oauth2.googleapis.com/token"

config :ueberauth, Ueberauth.Strategy.Discord.OAuth,
  site: "https://discord.com/api",
  authorize_url: "https://discord.com/oauth2/authorize",
  token_url: "https://discord.com/api/oauth2/token"

# ueberauth_facebook 0.10.0 defaults to the retired Graph API v2.8 token endpoint
# and has no PKCE support. D20 pins explicit current Graph endpoints and uses it
# only as a confidential server client with state and appsecret_proof validation.
config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  site: "https://graph.facebook.com/v26.0",
  authorize_url: "https://www.facebook.com/dialog/oauth",
  token_url: "https://graph.facebook.com/v26.0/oauth/access_token"

config :d20, D20.Actors.Token,
  salt: "actor",
  max_age: 1_209_600

config :d20, D20Web.Module, sandbox: ["allow-scripts", "allow-same-origin"]

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

config :d20, D20.Accounts.UserNotifier,
  from: {"D20", "noreply@d20.ravecat.io"},
  reply_to: {"D20 Support", "support@ravecat.io"}

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
