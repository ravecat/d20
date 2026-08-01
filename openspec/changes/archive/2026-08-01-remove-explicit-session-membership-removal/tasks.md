## 1. Characterize Presence-only Dismissal

- [x] 1.1 Update Workspace model and component tests to require immediate current-tab dismissal, iframe teardown, snapshot suppression, and restoration in a fresh Workspace instance without a channel call.
- [x] 1.2 Update Session and WorkspaceChannel tests to reject legacy `close` and preserve offline membership and game state without an explicit removal API.

## 2. Remove Explicit Membership Removal

- [x] 2.1 Remove `remove_member` from `D20.Sessions.Session`, `D20.Sessions`, and `D20.Game.Server` while preserving Presence online/offline behavior.
- [x] 2.2 Remove WorkspaceChannel close handling so all client application events return `unsupported_event` without Session mutation.
- [x] 2.3 Remove redundant actor-id validation and `invalid_identity` results from trusted Session Presence status functions.

## 3. Make Workspace Dismissal Local

- [x] 3.1 Replace the Workspace transport close extension with in-memory dismissed-id state that filters complete snapshots and updates layout deterministically.
- [x] 3.2 Verify closing a rendered window unmounts its iframe and bridge while other windows and actor tabs remain server-owned.

## 4. Update Contracts

- [x] 4.1 Remove the Workspace AsyncAPI close operation, messages, reply, payload, and error schemas and advance the breaking contract version.
- [x] 4.2 Update affected OpenSpec requirements for Presence-only membership, browser-local dismissal, finished results, and the read-only WorkspaceChannel boundary.

## 5. Validate and Deliver

- [x] 5.1 Format touched files and run focused Session, game-server, WorkspaceChannel, Workspace model/UI, typecheck, lint, and AsyncAPI validation commands.
- [x] 5.2 Run `just check`, validate OpenSpec strictly, document the legacy-client compatibility break, sync the delta specs, and archive the completed change.
