## Why

The Svelte frontend currently requires a running Phoenix application and realistic backend state to inspect most production UI. D20 needs an isolated component catalog so contributors can develop and review representative states quickly and establish a foundation for later browser-backed story testing.

## What Changes

- Add a Storybook 10 environment for the existing Svelte 5 and Vite 8 frontend, following the proven Next Station London structure while preserving D20's Bun, Phoenix Vite, Tailwind, daisyUI, and browser-policy boundaries.
- Add frontend commands to run and statically build the catalog without starting Phoenix, plus repository validation that detects broken Storybook configuration or stories.
- Start the development catalog on port 6006 when available and automatically use the nearest available port without an interactive confirmation when it is occupied.
- Extend `just up` to start Docker Compose first and then supervise Phoenix and Storybook concurrently with distinguishable combined logs, with the orchestration command declared in the root `justfile`.
- Provision the process supervisor through the Nix development shell while keeping frontend package scripts atomic.
- Emit the generated catalog under Phoenix's standard `priv/static/storybook` tree and allow Phoenix to serve it when the explicit Storybook build exists.
- Load production global styles and aliases in Storybook and add a typed production-component smoke story with deterministic props.
- Define story discovery, reusable-fixture, and connected-dependency mocking conventions so future stories do not open live sockets or require backend state.
- Document the local workflow and the boundary between Storybook review, behavior tests, and full application browser coverage.

## Capabilities

### New Capabilities

- `storybook-component-catalog`: Defines the isolated Svelte component catalog, production-style rendering, deterministic story boundaries, developer commands, and static-build validation.

### Modified Capabilities

- `project-command-interface`: Extends the routed development workflow to include supervised Storybook startup and combined Phoenix and Storybook output.

## Impact

- Affected systems: `flake.nix`, `assets/package.json`, the Bun lockfile, frontend Vite, TypeScript, ESLint, and formatting configuration, Storybook configuration and stories under `assets/`, Phoenix static-path configuration, the root validation workflow, and README developer documentation.
- Dependencies: Storybook's Svelte/Vite framework, docs addon, core CLI, and ESLint plugin are added as development-only frontend dependencies; the `concurrently` process supervisor is supplied by the Nix development shell.
- Public behavior: application routes, runtime bundles, session behavior, APIs, and iframe game contracts remain unchanged; Phoenix can serve an explicitly built catalog under `/storybook/`, but the production asset deploy does not build it automatically.
- Migrations and rollback: no database migration is required. Rollback removes the Storybook dependencies, configuration, story sources, commands, and validation step.
- Tracking: [GitHub issue #159](https://github.com/ravecat/d20/issues/159).
