## Why

The workspace component currently reconciles layout intent with authoritative sessions even though the workspace store owns both inputs. Publishing the normalized expanded session ID from the store gives presentation consumers one model-owned read value and enables later UI refactoring without duplicating state.

## What Changes

- Derive the expanded session ID in the workspace store from its internal layout and current authoritative sessions.
- Publish the derived ID through `WorkspaceState` and consume it directly in the workspace component.
- Keep layout intent private to the store while preserving Auto selection, explicit focus, missing-focus fallback, and Compact behavior.
- Add focused store coverage for the derived value and preserve existing presentation coverage.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `client-workspace-state`: Publish the effective expanded session ID from the composed workspace store while keeping layout intent inside the model.

## Impact

- Affected frontend code: `assets/js/widgets/workspace/model/workspace.ts` and `assets/js/widgets/workspace/ui/workspace.svelte`.
- Affected tests: focused workspace model tests; existing UI tests continue to verify presentation behavior.
- Affected specification: the client workspace read-store contract and presentation ownership in `client-workspace-state`.
- Tracking: GitHub issue `#176`.
- No route, Phoenix channel, backend session, persistence, dependency, migration, public protocol, or iframe module contract changes.
- Rollback restores the component-local derivation and public layout field.
