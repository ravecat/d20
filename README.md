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

- Enter the environment with `nix develop`, or run `direnv allow` once and let direnv load it automatically.

The flake provides the required environment.

Manual setup:

- Install and configure the required dependencies above manually.
- PostgreSQL must be available on `localhost` as user `postgres` with password `postgres`.

## Quick Start

```sh
just serve
```

Open [http://localhost:5000](http://localhost:5000).

In development, Phoenix starts the Vite watcher. The asset dev server uses `STATIC_PORT` or defaults to `5174`.
D20 automatically uses the first private IPv4 address for development asset URLs, so the application can also be opened from another device on the same network. Set `STATIC_URL_HOST` to override the detected address.

## Local Module Development

Use this workflow when you want the D20 shell and one or more local iframe module projects running together:

```sh
just up
```

Open [http://localhost:5000](http://localhost:5000). `just up` starts the shared Traefik container and then runs the local Phoenix backend in the foreground.

Each local module project should start its own Compose service and join the shared external `d20` Docker network. D20 derives iframe hosts from module slugs and the shell request host: when D20 is opened at `localhost:5000`, a module with slug `<module-slug>` resolves to `http://<module-slug>.localhost`.

The local workflow uses the PostgreSQL instance from the Nix shell and does not start a database container.

If another local workflow is still using port 80, stop it before starting Compose.

Stop the Compose services with:

```sh
docker compose down
```

## Features

- Browse configured game modules.
- Create game sessions from available modules.

## Stack

| Area                            | Source files                               |
| ------------------------------- | ------------------------------------------ |
| Development environment         | [flake.nix](flake.nix)                     |
| Phoenix and Elixir dependencies | [mix.exs](mix.exs)                         |
| Frontend asset dependencies     | [assets/package.json](assets/package.json) |

## Configuration

| Key                     | Production required? | Purpose                                                                                 |
| ----------------------- | -------------------- | --------------------------------------------------------------------------------------- |
| `DATABASE_URL`          | Yes                  | Production PostgreSQL connection URL.                                                   |
| `SECRET_KEY_BASE`       | Yes                  | Phoenix secret key base. Generate with `mix phx.gen.secret`.                            |
| `PORT`                  | No                   | Phoenix HTTP port. Defaults to `5000`.                                                  |
| `STATIC_PORT`           | No                   | Development asset server port. Defaults to `5174`.                                      |
| `STATIC_URL_HOST`       | No                   | Development asset host. Defaults to an automatically detected LAN IP.                  |
| `GAMES_METADATA_SOURCE` | No                   | `local` for offline development or `board_game_geek`. Dev defaults to local without a key. |
| `BGG_API_KEY`           | Yes                  | API key for the BoardGameGeek metadata source.                                         |
| `PHX_HOST`              | No                   | Public host used by the Phoenix endpoint. Defaults to `example.com`.                    |
| `PHX_SERVER`            | No                   | Enables the endpoint server when running a release.                                     |
| `POOL_SIZE`             | No                   | Ecto pool size. Defaults to `10`.                                                       |
| `ECTO_IPV6`             | No                   | Enables IPv6 socket options when set to `true` or `1`.                                  |
| `DNS_CLUSTER_QUERY`     | No                   | DNS cluster query for distributed deployment discovery.                                |

In development, the catalog automatically uses bundled minimal metadata when `BGG_API_KEY`
is absent. Set `GAMES_METADATA_SOURCE=local` to force offline mode, or set
`GAMES_METADATA_SOURCE=board_game_geek` together with a valid key for rich metadata.

## Commands

Named `just` recipes are reserved for workflows that compose multiple project actions. The default command-listing recipe and the generic Mix and asset dispatchers are the only infrastructure exceptions.

| Command                          | Purpose                                                             |
| -------------------------------- | ------------------------------------------------------------------- |
| `just`                           | List available project workflows and dispatchers.                   |
| `just serve`                     | Set up dependencies and start the development server.               |
| `just up`                        | Start shared Docker Compose routing and run the development server. |
| `just format`                    | Format Elixir and frontend assets.                                  |
| `just check`                     | Run formatting, asset, type, and test checks.                       |
| `just mix <task> [args...]`      | Run any Mix task from the repository root.                          |
| `just assets <script> [args...]` | Run any package script from `assets/` through Bun.                   |

Run single native operations directly, or use the matching dispatcher:

| Removed recipe            | Native replacement                         |
| ------------------------- | ------------------------------------------ |
| `just setup`              | `mix setup` or `just mix setup`            |
| `just start`              | `iex --sname d20 --erl "-proto_dist inet6_tcp" -S mix serve` |
| `just down`               | `docker compose down`                      |
| `just test`               | `mix test` or `just mix test`              |
| `just build`              | `mix deploy` or `just mix deploy`          |
| `just typecheck`          | `mix typecheck` or `just mix typecheck`    |
| `just agent-skills-sync`  | `mix usage_rules.sync --yes`               |
| `just agent-skills-check` | `mix usage_rules.sync --check`             |
| `just db-create`          | `mix ecto.create`                          |
| `just db-migrate`         | `mix ecto.migrate`                         |
| `just db-reset`           | `mix ecto.reset`                           |

## Agent Skills

`AGENTS.md` and `.agents/skills/implement-playable-game/` are maintained manually. Skills containing `metadata.managed-by: usage-rules` are generated from the locked Mix dependencies configured in `mix.exs`.

Run `mix usage_rules.sync --yes` after changing those dependencies or the UsageRules configuration, then review and commit the generated diff. Use `mix usage_rules.sync --check` when a read-only verification of generated agent skills is needed.

UsageRules covers Mix dependencies only. Frontend guidance for Svelte, TypeScript, Inertia, Bun, and npm packages remains outside this synchronization path.

## Testing and Checks

```sh
mix test
mix typecheck
mix assets.lint
```

## License

Licensed under the [GNU Affero General Public License v3.0 or later](LICENSE) (`AGPL-3.0-or-later`).
