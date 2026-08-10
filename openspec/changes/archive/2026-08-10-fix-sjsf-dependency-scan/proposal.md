## Why

Vite's cold development dependency scan fails when the application imports the published SJSF radio component implementation directly, reports a package-exports error, and skips dependency pre-bundling. The application should consume SJSF's supported radio registration entry while relying on Vite's automatic dependency discovery.

## What Changes

- Remove the manually maintained dependency pre-bundling include list from the shared Vite configuration.
- Register the radio widget through the package's JavaScript include entry and resolve it through the basic theme instead of importing the `.svelte` implementation subpath directly.
- Preserve launch-form rendering, frontend dependencies, browser-test optimization settings, and production bundling behavior.

## Capabilities

### New Capabilities

- `frontend-development-runtime`: Defines clean frontend development startup and automatic dependency discovery for shipped application imports.

### Modified Capabilities

None.

## Impact

- Affects `assets/vite.config.mjs`, the shared SJSF form configuration, and Vite development dependency discovery.
- Does not change product behavior, public APIs, persisted data, iframe contracts, or package versions.
- Tracked by GitHub issue #209.
- Rollback restores the direct component import and explicit optimizer include list together with the reproducible cold-start scan error.
