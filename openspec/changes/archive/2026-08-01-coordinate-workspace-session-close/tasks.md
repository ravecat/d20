## 1. Characterize Actor-wide Close

- [x] 1.1 Replace WorkspaceChannel regression expectations with accepted Close across two actor Workspace channels while preserving the exact Session and live runtime.
- [x] 1.2 Add SessionChannel coverage proving Close removes every matching actor Presence meta, leaves other actors attached, and preserves offline membership and game player state.
- [x] 1.3 Update Workspace model and component tests to require a `close_session` call, server-pushed replacement snapshot, authoritative reconciliation, and iframe teardown.

## 2. Coordinate Backend Lifecycle

- [x] 2.1 Subscribe SessionChannel to the actor Workspace topic, handle matching Close directly, and keep the actor's other SessionChannels active.
- [x] 2.2 Add one actor Workspace topic Close command without dispatching a Session or game command.
- [x] 2.3 Accept self-scoped Workspace `close_session` without Session lookup, push one replacement snapshot omitting the id, and retain existing unsupported-event behavior.
- [x] 2.4 Consolidate `D20.Sessions.list/1` and `list_runtime/1` into one runtime-entry query used by Workspace monitoring.

## 3. Apply Client Close Acknowledgement

- [x] 3.1 Add the Workspace transport `closeSession(id)` action over `close_session` and keep the window mounted until the replacement snapshot arrives.
- [x] 3.2 Reconcile complete snapshots directly and unmount the matching iframe and SDK bridge without a client dismissal set or close-specific layout event.

## 4. Update Contracts

- [x] 4.1 Advance the Workspace AsyncAPI minor version and add the close command, reply and error schemas while retaining `snapshot` as the server state event.
- [x] 4.2 Update focused AsyncAPI contract assertions and keep game Session contracts unchanged.

## 5. Validate and Deliver

- [x] 5.1 Format touched files and run focused WorkspaceChannel, SessionChannel, Workspace model/UI, typecheck, lint, and AsyncAPI validation commands.
- [x] 5.2 Verify the live two-tab browser scenario removes both iframes, marks the member offline, and preserves Session and game state.
- [x] 5.3 Run `just check`, validate OpenSpec strictly, sync the delta specs, and archive the completed change linked to issue #180.
