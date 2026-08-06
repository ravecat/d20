## Why

The global header and footer are application-shell composition elements but currently live in the transitional `shared/components` segment. Issue #199 tracks moving these single-purpose components to the App boundary so Shared no longer presents application-specific navigation as reusable infrastructure.

## What Changes

- Move the existing global header and footer components into an App UI segment.
- Update the application layout to compose the relocated components through local App imports.
- Remove the obsolete header and footer exports from the transitional Shared component public API.
- Preserve existing markup, styling, accessibility, authentication, navigation, layout variants, and runtime behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `frontend-shared-layer`: Require application-shell-specific UI to be owned by the App layer rather than exposed through the transitional Shared component segment.

## Impact

- Affected frontend files are the App layout, the relocated Svelte header and footer, and the Shared component public API.
- Existing layout and header tests continue to cover the same rendered behavior from the new source locations.
- No Phoenix route, Inertia contract, account behavior, iframe module contract, dependency, migration, deployment, or rollback procedure changes. Rollback consists of restoring the previous file locations, exports, and layout import.
