## Why

D20 currently uses Biome while the Qwinto and Koala Rescue Club clients use the same Svelte-aware ESLint and Oxfmt toolchain. Aligning the repositories removes divergent lint behavior and lets the shell apply Svelte and TypeScript ecosystem rules consistently with its embedded game clients.

## What Changes

- Replace Biome linting with an ESLint flat configuration for JavaScript, TypeScript, and Svelte sources.
- Replace Biome formatting with Oxfmt while preserving the current formatting conventions and excluded source areas.
- Update frontend scripts, development dependencies, lock data, inline tool directives, and repository guidance for the new toolchain.
- Keep the existing Mix and just command interfaces unchanged.

## Capabilities

### New Capabilities

- `frontend-code-quality-tooling`: Defines the repository's supported frontend linting and formatting commands, coverage, and compatibility expectations.

### Modified Capabilities

None.

## Impact

- Affects frontend tooling configuration and dependencies under `assets/`, the Bun lockfile, and the tooling reference in `AGENTS.md`.
- Removes `biome.json` and the `@biomejs/biome` dependency.
- Adds no runtime, API, persistence, session, or iframe module contract changes.
- Rollback consists of restoring the Biome configuration, scripts, dependency, and lockfile.
