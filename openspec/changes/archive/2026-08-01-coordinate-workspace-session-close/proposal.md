## Why

Workspace Close is currently browser-local, so closing a game in one tab leaves the same actor's iframe and SessionChannel Presence active in every other tab. Close needs to describe one actor leaving one concrete session attachment without conflating that transport lifecycle with durable Session membership or game player state.

## What Changes

- Add an authenticated Workspace `close_session` command scoped to one Session id.
- Coordinate the accepted close across every active Workspace and SessionChannel connection for the same actor and Session.
- Remove the matching window, iframe, and SDK bridge from every affected Workspace while preserving `session.members`, game player state, and the shared Session runtime.
- Let the final SessionChannel Presence meta drive the existing `offline` status transition.
- Let each active actor WorkspaceChannel acknowledge Close with one replacement snapshot omitting the selected Session, without changing durable discovery eligibility or retaining exclusion state.
- Extend the internal Workspace AsyncAPI contract with the `close_session` command and reply while retaining the existing complete `snapshot` event as the only server state update.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `multi-session-game-workspace`: Replace browser-local dismissal with an actor-wide, Session-scoped close lifecycle.
- `session-workspace-lifecycle`: Require all matching SessionChannel metas to leave while retaining offline membership and game state.
- `workspace-web-boundary`: Allow only the validated close application command and coordinate actor Workspace and SessionChannel processes without mutating Session state.
- `finished-session-workspace-access`: Apply the same actor-wide close lifecycle to finished result windows.

## Impact

- Backend: `D20Web.WorkspaceChannel`, `D20Web.Workspace`, and `D20Web.SessionChannel` gain self-scoped close coordination and focused channel tests.
- Frontend: the Workspace model sends `close_session` and reconciles the resulting complete snapshot without maintaining a second closed-id state; Workspace component tests cover iframe teardown after acknowledgement.
- Contract: `priv/specs/workspace.yaml` gains a backward-compatible command message and reply and advances its minor version.
- Runtime compatibility: no Session aggregate, game aggregate, persistence, supervision, or iframe module bootstrap shape changes.
- Migration and rollback: no data migration is required; rollback restores browser-local close behavior and the read-only Workspace protocol.
