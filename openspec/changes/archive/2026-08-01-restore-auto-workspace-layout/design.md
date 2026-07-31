## Context

The workspace originally used `WorkspaceLayout` mode `auto`, which lets the workspace list expand the first authoritative session. The Compact status-bar feature later changed the initial mode to `compact`, and subsequent uncommitted work added pending exact-session focus, Svelte context, and Lobby callback wiring to reopen only a session started locally.

Feature #175 rejects that distinction and requests the original Auto behavior. Existing unrelated Lobby lifecycle simplification must remain intact.

## Goals / Non-Goals

**Goals:**

- Restore `auto` as the initial browser-local workspace layout.
- Remove all uncommitted pending-focus state, context, component wiring, and focused tests.
- Keep the first authoritative session expanded and the remaining sessions represented by Compact status bars.
- Preserve explicit focus, Compact, close, fullscreen, iframe identity, and subscription-owned teardown.

**Non-Goals:**

- Revert the Compact status-bar visual design.
- Revert the independent Lobby exit-rendering simplification.
- Persist or synchronize layout across browser instances.
- Change backend session or workspace contracts.

## Decisions

### Restore the existing Auto state instead of adding another mode

The model already defines `WorkspaceLayout` mode `auto`, and the workspace UI already derives the first authoritative session ID for that mode. The implementation only needs to initialize the local XState store with `auto` and retain the existing derived composition.

### Remove local-start differentiation completely

The game page will stop consuming Workspace context, Lobby will return to its session-only interface, and `WorkspaceStore` will expose only `focus`, `compact`, and `close`. This removes the rejected behavior at its source instead of retaining dormant context or callback infrastructure.

### Preserve unrelated dirty-worktree changes

The rollback removes only exact-focus additions. The existing change that keeps Lobby rendering until Inertia navigation supplies new props remains unchanged because it is independent of workspace layout selection.

## Risks / Trade-offs

- [Existing sessions expand after reload or in another tab] -> This is the intentional Auto behavior requested by #175 and is covered by tests.
- [Authoritative session ordering changes] -> Auto continues to select the first current descriptor, matching the existing workspace arrangement contract.
- [Rollback accidentally removes unrelated Lobby work] -> Apply targeted patches against the pre-focus dirty-worktree behavior instead of resetting files wholesale.

## Migration Plan

1. Remove pending focus, Workspace context, and local-start callback wiring.
2. Restore the model's initial layout to `auto` and update behavioral tests.
3. Remove superseded uncommitted exact-focus OpenSpec artifacts.
4. Run focused and complete frontend validation, sync this delta, and archive the change.

No data migration or compatibility rollout is required. Reverting this change would restore Compact initialization but would require a new decision about local-start behavior.

## Open Questions

None.
