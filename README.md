# d20

`d20` is a Phoenix application shell for embedded tabletop and board-game modules.

It owns the surrounding product experience: routing, users, actors, sessions, permissions, module discovery, and runtime framing. Game modules stay focused on game behavior and run inside configured iframe entries.

## Prerequisites

Required dependencies:

- Elixir `>= 1.18.0`
- Mix and an Erlang/OTP version compatible with that Elixir version
- PostgreSQL `17.9`

Recommended:

- Docker Engine or Docker Desktop when using the Docker Compose module workflow.
- Nix flake environment for local development tooling. The flake provides Elixir, Erlang/OTP, Just, Docker Compose tooling, and PostgreSQL.

<details>
<summary>Prepare Nix environment</summary>

Official docs:

- [Nix installation](https://nixos.org/download/)
- [direnv installation](https://direnv.net/docs/installation.html)
- [direnv shell hook](https://direnv.net/docs/hook.html)
- [nix-direnv](https://github.com/nix-community/nix-direnv)

Linux multi-user Nix install:

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

Enable flakes:

```sh
mkdir -p ~/.config/nix
printf "experimental-features = nix-command flakes\n" >> ~/.config/nix/nix.conf
```

Optional direnv and nix-direnv setup through Nix:

```sh
nix profile install nixpkgs#direnv nixpkgs#nix-direnv
mkdir -p ~/.config/direnv
printf 'source $HOME/.nix-profile/share/nix-direnv/direnvrc\n' >> ~/.config/direnv/direnvrc
```

Add the direnv hook for your shell, then restart the shell. For bash:

```sh
printf 'eval "$(direnv hook bash)"\n' >> ~/.bashrc
```

For other shells, use the [direnv hook docs](https://direnv.net/docs/hook.html).

</details>

<br>

- Run `direnv allow` once so development commands can reload `envs/.env`.
- Enter the environment with `nix develop`, or let direnv load it automatically.

The flake provides the required environment.

Manual setup:

- Install and configure the required dependencies above manually.
- PostgreSQL must be available on `localhost` as user `postgres` with password `postgres`.

## Quick Start

```sh
just serve
```

`just serve` runs full setup first, force-stops the local BEAM process with the exact requested short node name, and starts a fresh watched IEx/Phoenix process in the current terminal. The default name is `d20`; pass `--sname <name>` to replace an explicit short name independently. Partial and different names remain untouched.

Setup completes before takeover, so a setup failure leaves an existing runtime running. Takeover uses `pkill` from procps on Linux and the system utility on macOS, then sends `SIGKILL`, which deliberately skips orderly OTP shutdown. This behavior is only for the disposable local development server.

Watchexec instances started by this workflow exit when a later invocation takes over their node. After updating from the earlier touch-to-restart workflow, stop its existing terminal once before using repeated takeover; that older Watchexec instance does not have the required exit behavior.

Changes under `envs/` or `config/`, and changes to `mix.exs` or `mix.lock`, restart Phoenix inside the current Watchexec owner without repeating setup. Dependency installation and migrations are not run automatically during a watched restart. Run `mix deps.get` after changing Elixir dependencies or `mix ecto.migrate` for pending migrations. Changes under `priv/repo/migrations/` do not restart the runtime or execute migrations automatically. Neither command resets, drops, or rolls development data back.

In development, Phoenix starts the Vite watcher. The asset dev server uses `STATIC_PORT` or defaults to `5174`.
D20 automatically uses the first private IPv4 address for development asset URLs, so the application can also be opened from another device on the same network. Set `STATIC_URL_HOST` to override the detected address.

## Storybook

Run the production-component catalog without Phoenix or other backend services:

```sh
just storybook
```

Storybook uses port 6006 when it is available and otherwise selects the nearest available port without prompting. It does not open a browser automatically, so use the local URL reported in the terminal. Arguments are forwarded unchanged to the Storybook development command, for example `just storybook --host 0.0.0.0 --port 6100`. Build the ignored static catalog into Phoenix's `priv/static/storybook` directory with:

```sh
just assets storybook:build
```

When Phoenix is running after that build, it serves the generated entry point at [http://localhost:5000/storybook/index.html](http://localhost:5000/storybook/index.html). The regular `mix assets.deploy` workflow does not build or publish Storybook automatically.

Stories live under [`assets/stories/`](assets/stories/) and import production components from `assets/js/`. See the [story source conventions](assets/stories/README.md) for deterministic fixtures and connected-dependency mocks.

Run visual regression tests with:

```sh
just assets playwright install chromium # once
just assets test:visual
just assets test:visual --update
```

Storybook runs independently from the routed application workflow. Start `just up` and `just storybook` in separate terminals when both are needed.

## Local Module Development

Use this workflow when you want the D20 shell and one or more local iframe module projects running together:

```sh
just up
```

`just up` starts the shared Traefik container through detached Docker Compose and then invokes the public `serve` workflow. Whether the requested node is absent or already running, the fresh watched Phoenix workflow remains in the current terminal. A repeated invocation force-stops only the BEAM process carrying the exact requested short name. Press Ctrl+C to open the IEx BREAK menu, then select `a` to abort the workflow. Watchexec and its IEx, Phoenix, Vite, and filesystem-watcher children exit with the foreground command. `up` does not start Concurrently or Storybook. Detached Compose services remain running until `docker compose down` is called.

Each local module project should start its own Compose service and join the shared external `d20` Docker network. D20 derives iframe hosts from module slugs and the shell request host: when D20 is opened at `localhost:5000`, a module with slug `<module-slug>` resolves to `http://<module-slug>.localhost`.

The local workflow uses the PostgreSQL instance from the Nix shell and does not start a database container.

If another local workflow is still using port 80, stop it before starting Compose.

Stop the Compose services with:

```sh
docker compose down
```

## Stack

| Area                            | Source files                               |
| ------------------------------- | ------------------------------------------ |
| Development environment         | [flake.nix](flake.nix)                     |
| Phoenix and Elixir dependencies | [mix.exs](mix.exs)                         |
| Frontend asset dependencies     | [assets/package.json](assets/package.json) |

## Configuration

| Key                 | Production required? | Purpose                                                                |
| ------------------- | -------------------- | ---------------------------------------------------------------------- |
| `DATABASE_URL`      | Yes                  | Production PostgreSQL connection URL.                                  |
| `SECRET_KEY_BASE`   | Yes                  | Phoenix secret key base. Generate with `mix phx.gen.secret`.           |
| `PORT`              | No                   | Phoenix HTTP port. Defaults to `5000`.                                 |
| `STATIC_PORT`       | No                   | Development asset server port. Defaults to `5174`.                     |
| `STATIC_URL_HOST`   | No                   | Development asset host. Defaults to an automatically detected LAN IP. |
| `BGG_API_KEY`       | Production           | BoardGameGeek enrichment key. Optional for local development, with fallback metadata when absent. |
| `RESEND_API_KEY`    | Yes                  | Send-only Resend API key restricted to the current sending domain managed by infrastructure. Sender addresses are checked-in config. |
| `DISCORD_OAUTH_CLIENT_ID` | When Discord is available | Discord application OAuth2 client ID. Both Discord credentials are optional, but required together for the provider to be available. |
| `DISCORD_OAUTH_CLIENT_SECRET` | When Discord is available | Discord application OAuth2 client secret. Never expose it to frontend code. |
| `PHX_HOST`          | No                   | Public host used by the Phoenix endpoint. Defaults to `example.com`.   |
| `PHX_SERVER`        | No                   | Enables the endpoint server when running a release.                    |
| `POOL_SIZE`         | No                   | Ecto pool size. Defaults to `10`.                                      |
| `ECTO_IPV6`         | No                   | Enables IPv6 socket options when set to `true` or `1`.                 |
| `DNS_CLUSTER_QUERY` | No                   | DNS cluster query for distributed deployment discovery.                |

## Commands

The project exposes four composite `just` workflows, a standalone Storybook entry point, and two generic dispatchers. Use the `mix` and `assets` dispatchers for all other project and frontend commands.

| Command                          | Purpose                                                                    |
| -------------------------------- | -------------------------------------------------------------------------- |
| `just`                           | List available project workflows and dispatchers.                          |
| `just up`                        | Start Compose routing and the watched Phoenix server.                     |
| `just format`                    | Format Elixir and frontend assets.                                         |
| `just serve`                     | Set up, replace the exact requested local node, and own it in this terminal. |
| `just storybook [args...]`       | Start Storybook independently and forward its CLI arguments.                |
| `just check`                     | Run the backend quality gate plus formatting, asset, type, and lifecycle checks. |
| `mix ci`                         | Run the complete backend quality gate in the test environment.            |
| `just mix <task> [args...]`      | Run a Mix task at the project level from the repository root.              |
| `just assets <script> [args...]` | Run a Bun package script at the asset level from the `assets/` directory.  |
| `just assets storybook:build`    | Build the static Storybook catalog for validation.                         |

## Backend Quality Gate

`mix ci` is the single complete backend quality command. It runs in the test environment (`def cli/0` prefers `MIX_ENV=test`) and stops at the first failing stage:

1. compilation with warnings as errors (`mix compile --warnings-as-errors`);
2. backend formatting verification (`mix format --check-formatted`);
3. backend tests through the existing database-aware `mix test` alias, which creates and migrates the test PostgreSQL database before ExUnit runs;
4. strict Credo with the ExSlop plugin (`mix credo --strict`);
5. Dialyzer (`mix dialyzer`);
6. ExDNA with the checked-in clone budget (`mix ex_dna lib --max-clones 14`);
7. Reach architecture policy and advisory smells (`mix reach.check --arch --smells`).

`just check` runs `mix ci` once, then the OpenSpec lifecycle check, frontend formatting, frontend linting, frontend tests, frontend type checking, and the Storybook catalog build. Backend formatting and backend tests never run twice.

Run each analyzer independently when investigating a failure:

```sh
mix credo --strict
mix dialyzer
mix ex_dna lib --max-clones 14
mix reach.check --arch --smells
```

Analyzer policy is reviewable project configuration, not blanket suppression:

- `.credo.exs` keeps strict Credo with ExSlop's recommended checks. Existing nesting and cyclomatic-complexity findings in validated control flow have exact inline suppressions; the checks remain blocking everywhere else, and cleanup is tracked in issue #179.
- `.dialyzer_ignore.exs` holds one exact file and warning-description filter for the documented `Ecto.Multi.insert/3` opacity false positive. The first `mix dialyzer` run builds the PLT and takes several minutes; later runs reuse it.
- `.ex_dna.exs` plus the `--max-clones 14` budget record the reviewed baseline for the deliberately mirrored provider flows and independent game namespaces. New duplication fails the gate; lower the budget whenever accepted cleanup removes clones, and never raise it to admit new duplication.
- `.reach.exs` forbids dependencies from pure `D20.*` domain modules on `D20Web.*`. `D20.Application` and `D20.Sessions.Server` are classified runtime adapters that intentionally publish through web-owned processes; heuristic smell findings are advisory.

Rollback removes the development/test tool dependencies, `.credo.exs`, `.dialyzer_ignore.exs`, `.ex_dna.exs`, `.reach.exs`, the `mix ci` alias with its `def cli/0` preference, the Dialyzer PLT options, and the `just check` delegation, restoring the previous explicit backend format and test steps. No data, runtime, protocol, or client rollback is required.

This local gate is deliberately separate from release publication: release-workflow issue #113 owns when published images consume `mix ci` and how its Dialyzer PLT is cached in automation.

## OpenSpec Change Completion

Every active change under `openspec/changes/` must link its owning GitHub Issue with a full Issue URL in `proposal.md`. Keep the Issue and Project status aligned with the remaining delivery work.

Run the read-only lifecycle check locally with:

```sh
mix openspec.check
```

The command runs strict non-interactive validation, fails when an active change is complete but unarchived, and identifies active proposals without an Issue link. It never edits specifications, task lists, archives, or GitHub state. `just check` includes the same lifecycle check.

Complete an OpenSpec-backed change in this order:

1. Finish every implementation, test, migration, deployment, rollback, and manual-verification task required by the change.
2. Update the owning Issue acceptance criteria and record the relevant completion evidence.
3. Compare each delta specification with its authoritative file under `openspec/specs/` and synchronize every applicable requirement.
4. Archive the complete proposal, design, delta specifications, and task history under the date-prefixed `openspec/changes/archive/` path.
5. Run `mix openspec.check` and confirm the archived change no longer appears in `openspec list --json`.

Do not infer completion from age. When deployment, migration, rollback, external coordination, or manual verification remains outstanding, keep the change active, leave the corresponding task unchecked, and record the reason beside that task. Do not archive it merely to make the active list shorter.

## License

Licensed under the [GNU Affero General Public License v3.0 or later](LICENSE) (`AGPL-3.0-or-later`).
