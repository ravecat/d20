## Context

The root `justfile` mixes two responsibilities. It defines useful project workflows such as `serve`, `format`, and `check`, but it also repeats native commands such as `mix test`, `mix deploy`, and `docker compose down` under new names. The duplicated names add documentation and maintenance work without changing behavior. Mix already owns backend task discovery and aliases, while `assets/package.json` owns frontend scripts and Bun is the repository package runner.

`just` cannot catch arbitrary unknown recipe names, and dotted Mix tasks such as `ecto.migrate` are not valid `just` recipe names. Generic dispatch therefore needs an explicit namespace before the native task name.

## Goals / Non-Goals

**Goals:**

- Make `just` the entry point for project-level workflows instead of a second catalog of every native task.
- Provide `just mix ...` for arbitrary Mix tasks and `just assets ...` for arbitrary asset package scripts.
- Preserve argument boundaries and native command exit statuses through both dispatchers.
- Retain the current behavior of genuinely composite workflows.
- Establish a reviewable rule for adding future named recipes.

**Non-Goals:**

- Make `just ecto.migrate` work without a `mix` namespace.
- Rename or remove Mix aliases or Bun package scripts.
- Replace Docker Compose commands with a generic Docker dispatcher.
- Change application runtime, persistence, or public protocols.

## Decisions

### Use explicit native-tool dispatchers

The root `justfile` will define these infrastructure recipes:

- `mix +args` runs `mix "$@"` from the repository root.
- `assets +args` runs `bun run "$@"` with `assets/` as its working directory.

Both recipes will enable positional arguments so whitespace and multiple arguments remain distinct, require at least one argument with `+args`, and suppress the redundant `just` failure footer while preserving the native process exit status.

An unknown-recipe fallback was rejected because `just` validates recipe names before executing any recipe. Generating one recipe per Mix task or package script was also rejected because it would recreate the duplicated catalog this change removes.

### Reserve named recipes for composition

Except for the default discovery recipe and the two generic dispatchers, a named root recipe must coordinate at least two meaningful actions. A recipe does not qualify merely because the one downstream Mix alias internally expands to several tasks. The `justfile` should own the composition it advertises.

This removes `setup`, `start`, `down`, `test`, `build`, `typecheck`, `agent-skills-sync`, `agent-skills-check`, `db-create`, `db-migrate`, and `db-reset`. Their replacements are the native commands, optionally reached through `just mix ...` or `just assets ...` where applicable.

Allowing one-action recipes when they add flags or defaults was considered, but it makes the eligibility rule subjective and would retain wrappers such as `start`. The stricter composition rule keeps the command surface predictable. If a future one-action command needs project policy, that policy should first live in the native task or script; a deliberate exception would require a new specification change.

### Preserve composite workflows by inlining removed dependencies

The retained command surface will be:

- `default`, which lists available commands.
- `mix` and `assets`, which dispatch native commands.
- `serve`, which performs setup and starts the named IEx/Phoenix node with the current defaults.
- `up`, which starts Docker Compose routing and then runs `serve`.
- `format`, which formats backend and frontend sources.
- `check`, which runs skill drift, formatting, linting, frontend tests, type checking, and backend tests.

`serve` will invoke `mix setup` and the existing `iex ... -S mix serve` command directly. `check` will invoke `mix usage_rules.sync --check` directly. This preserves workflow order without keeping private-looking aliases solely for dependency reuse.

### Keep documentation aligned with command ownership

`README.md` and root `AGENTS.md` will list composite `just` workflows separately from direct Mix, Bun, and Docker commands. Removed recipes will not remain as compatibility shims because that would violate the new recipe policy and conceal stale usage.

## Risks / Trade-offs

- [Existing local scripts call removed recipes] -> Treat this as an intentional developer CLI break, document direct replacements, and keep all underlying native commands unchanged.
- [A typo after `just mix` or `just assets` reaches the native tool] -> Rely on Mix and Bun script lookup errors; the explicit namespace still prevents unrelated unknown `just` recipes from executing.
- [Inlining commands duplicates part of a retained workflow] -> Accept the small duplication so named recipes remain independently understandable and removed wrappers do not survive as indirection.
- [The strict rule excludes useful one-command conveniences] -> Prefer native Mix aliases, package scripts, or direct Docker commands; change the specification explicitly if a justified exception emerges.

## Migration Plan

1. Add and validate the `mix` and `assets` dispatchers.
2. Inline required steps into `serve` and `check`.
3. Remove every one-action named recipe covered by this change.
4. Update README and agent command guidance with direct replacements.
5. Validate the exact recipe list, dry-run retained workflows, and execute harmless dispatcher commands.

Rollback restores the previous `justfile` recipes and matching documentation. No data rollback or deployment sequencing is required.

## Open Questions

None.
