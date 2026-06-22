# d20

`d20` is a Phoenix application shell for embedded tabletop and board-game modules.

It owns the surrounding product experience: routing, users, actors, sessions, permissions, module discovery, and runtime framing. Game modules stay focused on game behavior and run inside configured iframe entries.

## Prerequisites

Required dependencies:

- Elixir `>= 1.18.0`
- Mix and an Erlang/OTP version compatible with that Elixir version
- PostgreSQL `17.9`

Recommended:

- Nix flake environment for the optional Garden/Telepresence local workflow. The flake provides pinned Garden and Telepresence CLIs.

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

In development, Phoenix starts the Vite watcher. The asset dev server uses `VITE_PORT` or defaults to `5174`.

## Local Cluster Workflow

Use the local cluster workflow when you want D20 and its module projects behind stable local ingress names:

```sh
just up
```

Open [http://d20.localhost](http://d20.localhost). `just up` creates the k3d cluster when needed, runs module discovery, deploys the Garden graph, intercepts the cluster `backend` service with Telepresence, and starts the local Phoenix backend in the foreground.

Discovery is source-name based. `scripts/discovery.py` reads every source declared in `garden.yml`, looks for a sibling directory with the same name and its own `garden.yml`, and links it with `garden link source`. If no local match exists, the source is unlinked so Garden uses the source `repositoryUrl`.

Module-specific build and deploy behavior lives in each linked Garden source project. The local workflow uses the PostgreSQL instance from the Nix shell and does not start a database workload in the cluster.

References: [Garden](https://docs.garden.io/) and [Telepresence](https://telepresence.io/docs/).

Stop the Garden/Telepresence mode and delete the local k3d cluster with:

```sh
just down
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

| Key                 | Production required? | Purpose                                                                |
| ------------------- | -------------------- | ---------------------------------------------------------------------- |
| `DATABASE_URL`      | Yes                  | Production PostgreSQL connection URL.                                  |
| `SECRET_KEY_BASE`   | Yes                  | Phoenix secret key base. Generate with `mix phx.gen.secret`.           |
| `PORT`              | No                   | Phoenix HTTP port. Defaults to `5000`.                                 |
| `VITE_PORT`         | No                   | Vite development server port. Defaults to `5174`.                      |
| `BGG_API_KEY`       | No                   | API key for the board-game metadata source.                            |
| `PHX_HOST`          | No                   | Public host used by the Phoenix endpoint. Defaults to `example.com`.   |
| `PHX_SERVER`        | No                   | Enables the endpoint server when running a release.                    |
| `POOL_SIZE`         | No                   | Ecto pool size. Defaults to `10`.                                      |
| `ECTO_IPV6`         | No                   | Enables IPv6 socket options when set to `true` or `1`.                 |
| `DNS_CLUSTER_QUERY` | No                   | DNS cluster query for distributed deployment discovery.                |

## Commands

| Command          | Purpose                                                                                |
| ---------------- | -------------------------------------------------------------------------------------- |
| `just serve`     | Set up dependencies and start the development server.                                  |
| `just setup`     | Fetch dependencies, set up the database, install asset dependencies, and build assets. |
| `just test`      | Run ExUnit tests.                                                                      |
| `just check`     | Run formatting checks, asset linting, type checks, and tests.                          |
| `just typecheck` | Run TypeScript and Svelte checks.                                                      |
| `just lint`      | Run frontend asset linting.                                                            |
| `just format`    | Format Elixir and frontend assets.                                                     |
| `just db-reset`  | Drop and recreate the development database.                                            |

## Testing and Checks

```sh
just test
just typecheck
just lint
```

## License

Licensed under the [GNU Affero General Public License v3.0 or later](LICENSE) (`AGPL-3.0-or-later`).
