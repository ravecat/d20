defmodule D20.MixProject do
  use Mix.Project

  def project do
    [
      app: :d20,
      version: "0.1.0",
      elixir: ">= 1.18.0 and < 2.0.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      usage_rules: usage_rules(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {D20.Application, []}, extra_applications: [:crypto, :logger, :runtime_tools]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:inertia, "~> 3.0.0-rc"},
      {:ueberauth, "~> 0.10.8"},
      {:ueberauth_discord, "~> 0.7.0"},
      {:ueberauth_google, "~> 0.12.1"},
      {:phoenix_vite, "~> 0.4"},
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:schemecto,
       github: "josevalim/schemecto", ref: "f2d09f7c65b0fe25f84db8d4fc10c9bfeb241656"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:typeid_elixir, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:sweet_xml, "~> 0.7.5"},
      {:pathex, "~> 2.6"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:bodyguard, "~> 2.4.3"},
      {:igniter, "~> 0.6", only: [:dev], runtime: false},
      {:recode, "~> 0.8", only: [:dev, :test], runtime: false},
      {:usage_rules, "~> 1.2", only: [:dev], runtime: false},
      {:bun, "~> 1.5 and >= 1.5.1", runtime: Mix.env() == :dev}
    ]
  end

  defp usage_rules do
    [
      skills: [
        location: ".agents/skills",
        build: [
          "phoenix-framework": [
            description:
              "Use this skill working with Phoenix Framework. Consult this when working with the web layer, controllers, views, liveviews etc.",
            usage_rules: [:phoenix, ~r/^phoenix_/]
          ]
        ]
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      serve: ["phx.server"],
      start: ["serve"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "format.check": ["format --check-formatted"],
      "assets.setup": ["bun.install --if-missing", "bun assets install"],
      "assets.format": ["bun assets run format"],
      "assets.format.check": ["bun assets run format.check"],
      "assets.lint": ["bun assets run lint"],
      "assets.test": ["bun assets run test"],
      "assets.storybook": ["bun assets run storybook:build"],
      typecheck: ["bun assets run typecheck"],
      "assets.check": ["bun assets run check"],
      "assets.build": ["bun vite build"],
      "assets.deploy": ["assets.build"],
      deploy: ["deps.get --only prod", "compile", "assets.setup", "assets.deploy"]
    ]
  end
end
