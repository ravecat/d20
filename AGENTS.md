# D20 Repository Guidance

## Purpose

- Use this file as the repository entry point and routing map.
- Keep one-off task details in the task prompt or the matching OpenSpec change.
- Read only the artifacts relevant to the current task.
- Prefer executable manifests, code, tests, and protocol specifications over duplicated prose.

## Project

- `d20` is a Phoenix application shell for embedded tabletop and board-game modules.
- The shell owns routing, accounts, actors, sessions, permissions, game discovery, and runtime framing.
- Game namespaces own game-specific state, rules, commands, permissions, and projections.
- The backend uses Elixir, Phoenix, Ecto, PostgreSQL, and OTP.
- The frontend shell uses Inertia, Svelte, TypeScript, Vite, and Bun.

## Environment Sources

| Concern | Source |
| --- | --- |
| Project setup and local workflows | [`README.md`](README.md) |
| Top-level tasks and command composition | [`justfile`](justfile) |
| Elixir requirements, dependencies, and Mix aliases | [`mix.exs`](mix.exs) |
| Reproducible development shell | [`flake.nix`](flake.nix), [`flake.lock`](flake.lock), [`.envrc`](.envrc) |
| Production image | [`Dockerfile`](Dockerfile) |
| Local routing and shared Docker network | [`compose.yaml`](compose.yaml) |
| Runtime configuration | [`config/config.exs`](config/config.exs), [`config/runtime.exs`](config/runtime.exs) |
| Development and test configuration | [`config/dev.exs`](config/dev.exs), [`config/test.exs`](config/test.exs) |
| Environment variable template | [`envs/.env.example`](envs/.env.example) |
| Frontend scripts and dependencies | [`assets/package.json`](assets/package.json) |
| Frontend compiler and build configuration | [`assets/tsconfig.json`](assets/tsconfig.json), [`assets/vite.config.mjs`](assets/vite.config.mjs), [`assets/svelte.config.mjs`](assets/svelte.config.mjs) |
| Elixir formatting and static checks | [`.formatter.exs`](.formatter.exs), [`.recode.exs`](.recode.exs) |
| Frontend formatting and linting | [`biome.json`](biome.json) |
| OpenSpec workflow configuration | [`openspec/config.yaml`](openspec/config.yaml) |

- Use the Nix or direnv environment when the required toolchain is unavailable.
- Treat versions in manifests and lockfiles as authoritative when prose documentation differs.
- Never read, print, or modify `envs/.env`; use `envs/.env.example` to understand expected variables.

## Repository Map

- `lib/d20/` contains domain logic, game engines, session runtime, and OTP processes.
- `lib/d20_web/` contains Phoenix controllers, channels, plugs, projections, and web boundaries.
- `assets/` contains the Inertia and Svelte frontend shell and source static assets.
- `test/` mirrors application behavior and provides shared cases under [`test/support/`](test/support/).
- `priv/repo/migrations/` contains Ecto migrations.
- `priv/specs/` contains public AsyncAPI contracts.
- `openspec/changes/` contains task-specific proposals, designs, delta specifications, and tasks.

## Task Routing

- For setup, startup, or local services, read [`README.md`](README.md), [`justfile`](justfile), and the relevant files under `config/`.
- For the game catalog, read [`config/config.exs`](config/config.exs), [`lib/d20/games/`](lib/d20/games/), and [`test/d20/games/`](test/d20/games/).
- For session lifecycle, read [`lib/d20/sessions.ex`](lib/d20/sessions.ex), [`lib/d20/sessions/session.ex`](lib/d20/sessions/session.ex), and their tests.
- For game processes, read [`lib/d20/game.ex`](lib/d20/game.ex), [`lib/d20/game/server.ex`](lib/d20/game/server.ex), and focused server tests.
- For game behavior, read the complete `lib/d20/<game>/` namespace and matching `test/d20/<game>/` tests.
- For implementing a playable game from a rules specification, use [`.agents/skills/implement-playable-game/SKILL.md`](.agents/skills/implement-playable-game/SKILL.md).
- For channels and public projections, read [`lib/d20_web/channels/session_channel.ex`](lib/d20_web/channels/session_channel.ex), [`lib/d20_web/projection.ex`](lib/d20_web/projection.ex), and the matching file under `priv/specs/`.
- For frontend work, read the affected files under `assets/js/`, [`assets/package.json`](assets/package.json), and nearby frontend tests.
- For an existing OpenSpec change, read its `proposal.md`, `design.md`, delta specifications, and `tasks.md` before editing.
- Do not treat every directory under `openspec/changes/` as current behavior.
- Changes to a separate iframe game repository require explicit task scope.

## Architecture Boundaries

- Use `D20.Sessions` as the public runtime boundary for game sessions.
- `D20.Sessions.Session` owns generic table and session lifecycle.
- `D20.Game` defines the game-engine contract.
- Use `D20.Game.Server` unless server-owned timers or automatic transitions require a custom server.
- Inside a game namespace:
  - `Command` validates and normalizes external payloads.
  - `Rules` validates state-dependent legality and derives legal actions.
  - `Ruleset` contains static rules, limits, and board definitions.
  - `Game` owns aggregate state and deterministic transitions.
  - `Permission` computes caller authorization.
  - `Projection` produces caller-specific public state.
  - `Server` owns process-level scheduling and automatic commands.
- Keep authoritative legality and state transitions on the server.
- Do not expose internal session or game state in place of a caller-specific projection.
- Preserve command names, payload shapes, reason atoms, behaviour callbacks, projections, permissions, and persistence contracts unless the task explicitly changes them.
- Use `D20.Qwinto` as the default-server reference and `D20.KoalaRescueClub` as the custom-server reference.

## Commands and Validation

- Use [`justfile`](justfile) and the aliases in [`mix.exs`](mix.exs) as command sources of truth.
- Use `just setup` only when the environment needs initialization.
- Be aware that `just serve` runs setup before starting the server.
- Run targeted backend tests with `mix test test/path_test.exs[:line]`.
- Run targeted frontend tests from `assets/` with `bun run test -- <path>`.
- Run all backend tests with `just test`.
- Run frontend checks with `mix assets.lint`, `mix assets.test`, and `mix typecheck`.
- Run `just check` for broad, cross-stack, or release-relevant changes.
- Format touched Elixir files with `mix format <files>`.
- Avoid repository-wide autocorrection when it would create unrelated changes.
- `mix test` requires PostgreSQL and creates and migrates the test database through its Mix alias.
- Do not run `just db-reset` or `mix ecto.reset` without explicit approval.

## Tests

- Reproduce bugs in the nearest relevant test when practical.
- Test behavior at the layer being changed.
- Reuse [`D20.DataCase`](test/support/data_case.ex), [`D20.ConnCase`](test/support/conn_case.ex), and [`D20.ChannelCase`](test/support/channel_case.ex).
- Synchronize process tests with messages, monitors, or public calls instead of `Process.sleep/1`.
- Use `async: false` when tests share named processes, registries, application configuration, or database state.

## Contracts and Generated Files

- Update the matching file under [`priv/specs/`](priv/specs/) when channel events, payloads, projections, permissions, or error reasons change.
- Update channel and projection tests together with public protocol changes.
- Edit frontend sources under `assets/`, not generated Vite output under `priv/static/`.
- Do not edit `_build/`, `deps/`, `node_modules/`, `.pg_data/`, `tmp/`, or `envs/.env`.

## Completion

- Cover the requested behavior with relevant tests.
- Run the smallest relevant formatting, tests, linting, and type checks, then broaden according to risk.
- Update public contracts and durable documentation when behavior changes.
- Report commands run, verified behavior, and remaining risks.
