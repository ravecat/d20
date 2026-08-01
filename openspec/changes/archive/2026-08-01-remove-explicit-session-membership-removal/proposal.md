## Why

Workspace Close currently treats a browser-local window dismissal as an explicit removal from Session membership, even though closing that window is indistinguishable from closing the final game tab or losing the connection. This duplicates Phoenix Presence lifecycle state, creates a larger public Session API, and can leave game player state disconnected from Workspace discovery.

Tracked by [GitHub issue #26](https://github.com/ravecat/d20/issues/26).

## What Changes

- Make Workspace window dismissal browser-local: immediately unmount the selected iframe in the current Workspace instance without sending a WorkspaceChannel command.
- Let iframe channel teardown flow through Phoenix Presence, so the actor becomes offline only when the final Presence meta disappears; other tabs and devices remain authoritative.
- Restore dismissed live Sessions on a fresh Workspace mount or full browser reload because durable runtime membership remains unchanged.
- **BREAKING** Remove `D20.Sessions.remove_member/1`, `D20.Sessions.Session.remove_member/2`, the corresponding game-server call, and the WorkspaceChannel `close` operation.
- Remove redundant actor-id validation and the `:invalid_identity` result from `D20.Sessions.Session.online/3` and `offline/2`; the trusted Presence pipeline owns actor identity.
- **BREAKING** Remove the Workspace AsyncAPI close operation, messages, payloads, replies, and errors.
- Preserve game-specific `left` commands as a separate domain capability; Workspace dismissal does not invoke them.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `session-workspace-lifecycle`: Session membership is retained for all Presence offline transitions and is no longer explicitly removed by Workspace.
- `multi-session-game-workspace`: Window dismissal becomes current-tab presentation state instead of an authoritative membership mutation.
- `finished-session-workspace-access`: Finished result windows use the same browser-local dismissal and return after a fresh Workspace mount.
- `workspace-web-boundary`: WorkspaceChannel becomes a read-only discovery boundary with join, snapshots, monitoring, and unsupported-event rejection only.

## Impact

- Backend: `D20.Sessions`, `D20.Sessions.Session`, `D20.Game.Server`, `D20Web.WorkspaceChannel`, trusted Presence identity handling, and focused Session/Workspace tests.
- Frontend: the Workspace model keeps an in-memory dismissed-id set and filters server snapshots; closing unmounts the iframe and SDK bridge locally.
- Contracts: `priv/specs/workspace.yaml` loses the `close` operation and advances its breaking version.
- Runtime compatibility: existing clients that send Workspace `close` receive `unsupported_event`; game SessionChannel commands and iframe bootstrap shapes are unchanged.
- Persistence and migrations: none. Dismissal is intentionally not stored and resets on Workspace remount or full reload.
- Rollback: restoring the removed API and prior authoritative-close behavior is code-only and requires no data migration.
