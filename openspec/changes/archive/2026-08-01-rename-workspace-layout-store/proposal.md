## Why

The inner `@xstate/store` instance owns only browser-local workspace layout, but its generic `store` name hides that responsibility beside the composed workspace store. Naming it `layout` makes the ownership boundary explicit and keeps trigger calls aligned with the state they change.

## What Changes

- Rename the local `createStore` binding from `store` to `layout`.
- Route layout reads, subscriptions, focus triggers, and Compact triggers through the renamed binding.
- Preserve the flat `WorkspaceLayout` context and every emitted `WorkspaceState` value.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `client-workspace-state`: Name the browser-local presentation store according to its layout-only responsibility.

## Impact

- Affected frontend code: `assets/js/widgets/workspace/model/workspace.ts`.
- Tracking: GitHub issue `#176`.
- No runtime behavior, store contract, route, Phoenix channel, session, persistence, dependency, migration, protocol, or iframe lifecycle change.
- Rollback renames the local binding back to `store`.
