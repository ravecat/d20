## 1. Development Tooling

- [x] 1.1 Add `direnv` and `watchexec` to the Nix development package set without changing production image inputs.
- [x] 1.2 Verify both tools are available through `nix develop` and the authorized repository direnv environment.

## 2. Watched Server Workflow

- [x] 2.1 Keep `mix setup` before the watcher and wrap only the interactive IEx/Phoenix command so watched restarts do not repeat setup.
- [x] 2.2 Watch `envs/.env`, shared configuration, runtime configuration, and the active `MIX_ENV` configuration through directory-safe filters.
- [x] 2.3 Re-evaluate `.envrc` for every child launch so changed and removed dotenv values are reflected in the replacement BEAM.
- [x] 2.4 Preserve direct argument boundaries and terminal ownership so custom node options and interactive IEx input continue to work.
- [x] 2.5 Keep `up` composed through `serve` so routed development inherits the same restart behavior.

## 3. Developer Documentation

- [x] 3.1 Document one-time direnv authorization and the development inputs that trigger automatic restart.

## 4. Validation

- [x] 4.1 Dry-run `serve` and `up` and validate watcher construction for default `dev` and explicit `test` Mix environments.
- [x] 4.2 Start the watched Phoenix server, verify an HTTP 200 response, and confirm the BEAM is a child of watchexec.
- [x] 4.3 Verify the watched IEx prompt accepts an Elixir expression while preserving the Erlang emulator option string.
- [x] 4.4 Change safe temporary dotenv and configuration fixtures and confirm each supported change replaces the child process with refreshed values.
- [x] 4.5 Run whitespace validation for the implementation and OpenSpec artifacts.
