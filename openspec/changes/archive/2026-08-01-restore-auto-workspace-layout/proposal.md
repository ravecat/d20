## Why

The pending exact-session focus implementation adds client context, Lobby callbacks, and reconciliation state to distinguish local starts from passively discovered sessions. Feature #175 intentionally removes that distinction and restores the earlier Auto layout, where the first authoritative session opens immediately in Theater.

## What Changes

- Initialize every newly mounted workspace in Auto instead of Compact.
- Expand the first authoritative session automatically and keep the remaining sessions Compact.
- Remove the pending started-session ID, Workspace context, and Lobby start-completion callback introduced for exact local-start focus.
- Preserve explicit focus, Compact, close, fullscreen, iframe lifecycle, and the existing simplified Lobby exit behavior.
- Remove the uncommitted OpenSpec artifacts for the superseded exact-session focus work.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `workspace-session-status-bars`: Replace Compact-on-mount and local-start-specific selection with Auto-on-mount and first-session Theater selection.

## Impact

- Affects browser-local workspace initialization, game page and Lobby wiring, focused frontend tests, and workspace layout specifications.
- Does not change Phoenix channels, backend session state, routes, persistence, migrations, dependencies, or iframe module contracts.
- Rollback is frontend-only and removes uncommitted exact-focus artifacts rather than introducing a compatibility transition.
