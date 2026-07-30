## Why

The frontend still type-checks with TypeScript 5.9 even though TypeScript 7.0.2 is the current stable release and its native compiler can make project-wide checks substantially faster. The upgrade must distinguish that benefit from Vite production build performance, because Vite 8 transpiles TypeScript with Oxc and does not invoke `tsc`.

## What Changes

- Upgrade the command-line type checker from TypeScript 5.9 to the native TypeScript 7 line.
- Keep the TypeScript 6 compatibility API available for `typescript-eslint`, `svelte-check`, and other tools that cannot consume the TypeScript 7 API yet.
- **BREAKING**: Remove the TypeScript 7-incompatible `baseUrl` compiler option while preserving every existing `paths` alias and its resolution behavior.
- Preserve the existing `bun run typecheck` and `mix typecheck` command boundaries, with native `tsc` checking followed by Svelte-aware checking.
- Benchmark the standalone compiler and complete typecheck command before and after migration, while treating Vite build timing as a separate non-regression measurement rather than an expected TypeScript speedup.

## Capabilities

### New Capabilities

- `frontend-typecheck-toolchain`: Defines the supported TypeScript 7 command-line checker, compatibility compiler API, project configuration, stable commands, and performance validation boundary.

### Modified Capabilities

None.

## Impact

- Affects `assets/package.json`, `assets/bun.lock`, and `assets/tsconfig.json`.
- Changes development and CI type-checking dependencies without changing Vite's Oxc/Rolldown production pipeline.
- Does not change browser targets, emitted browser code, Svelte component interfaces, routes, runtime payloads, persistence, sessions, or iframe module contracts.
- Rollback restores the TypeScript 5.9 dependency and `baseUrl`; no application data or runtime rollback is required.
