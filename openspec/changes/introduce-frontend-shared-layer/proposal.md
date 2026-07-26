## Why

The frontend mixes one root application entry, flat Inertia pages, and root-level technical buckets for components, stores, and types. This makes ownership and allowed dependency direction unclear as the Svelte shell grows. A staged Feature-Sliced Design migration establishes explicit App, Pages, and Shared boundaries now, while deferring behavior-heavy classification until each domain is ready to be refactored safely.

## What Changes

- Keep `assets/js/app.js` as the stable Phoenix/Vite entry and move application bootstrap behavior into an App-layer module.
- Convert flat Inertia page files into page slices with `ui` segments and public APIs.
- Keep the existing `shared/api` transport boundary.
- Move the root `components`, `stores`, and `types` directories into transitional Shared segments without changing their behavior or public contracts.
- Expose each populated Shared segment through a public API and update consumers and tests to use the new boundaries.
- Remove the superseded legacy aliases while preserving the existing root `~/*` alias.
- Preserve Inertia page names, Phoenix channel behavior, iframe SDK integration, Svelte component contracts, and user-visible behavior.
- Do not add empty Widgets, Features, or Entities layers, architectural linting, or new runtime dependencies.

## Capabilities

### New Capabilities

- `frontend-shared-layer`: Defines the ownership, public API, dependency, and compatibility requirements for reusable frontend infrastructure in the Shared layer.

### Modified Capabilities

None.

## Impact

- Affected code is limited to `assets/js/` module locations, imports, page resolution, aliases, and colocated frontend tests.
- Public HTTP, channel, projection, persistence, iframe module, and Svelte component contracts remain unchanged.
- The existing `js/app.js` production entry remains unchanged, so Phoenix templates and the Vite manifest retain their current contract.
- No database migration, session/runtime migration, package dependency, or server contract change is required.
- Rollback consists of restoring the prior file locations, page glob, aliases, and imports.
