## Why

The composed workspace state currently publishes a separate `expandedId` even though expansion is already a property of browser-local layout. Keeping the selected ID beside its mode makes the store contract explicit and lets presentation read `$workspace.layout.id` without a second field or one-use resolver.

## What Changes

- Add an `id` field to every workspace layout mode in the local store context.
- Publish the composed layout through `WorkspaceState` instead of a separate `expandedId`.
- Resolve Auto to the first authoritative session ID, preserve the exact focused ID without membership fallback, and publish `undefined` for Compact.
- Make the workspace component compare each session directly with `$workspace.layout.id`.
- Remove the one-use expanded-ID helper and update focused model coverage.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `client-workspace-state`: Expose the selected session ID as part of each layout mode and preserve exact focused intent when its session is absent.

## Impact

- Affected frontend code: `assets/js/widgets/workspace/model/workspace.ts` and `assets/js/widgets/workspace/ui/workspace.svelte`.
- Affected tests: focused workspace model tests; existing presentation tests continue to verify rendering.
- Tracking: GitHub issue `#176`.
- No route, Phoenix channel, backend session, persistence, dependency, migration, public protocol, or iframe module contract changes.
- Rollback restores the separate `expandedId` read field and missing-focus fallback.
