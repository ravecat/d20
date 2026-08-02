## 1. Specification and Registry Module

- [x] 1.1 Validate the updated proposal, design, new `session-actor-registry` capability, and related delta specifications with strict OpenSpec validation.
- [x] 1.2 Add supervised duplicate `D20.Sessions.Registry` without changing the existing unique `D20.Registry`.
- [x] 1.3 Implement documented idempotent `attach/2`, `detach/1`, and `list/1` interfaces with process-owned cleanup behavior.
- [x] 1.4 Add focused Registry tests for many-to-many lookup, duplicate prevention, scoped detach, and automatic Session-process cleanup.

## 2. Serialized Session Attachment Lifecycle

- [x] 2.1 Extend `D20.Game.Server` and generated custom servers with serialized attach and detach calls that own Registry mutation and never dispatch game commands.
- [x] 2.2 Add runtime-agnostic `D20.Sessions.attach/1` and `detach/2`, preserving authenticated scope, idempotent Close behavior, and existing error shapes.
- [x] 2.3 Keep Presence online and offline focused on retained member status and game admission, with ordinary offline preserving attachments.
- [x] 2.4 Add default and custom server tests for attach, repeated attach, detach, offline normalization, unchanged game state, and no game `left` event.

## 3. SessionChannel and Workspace Integration

- [x] 3.1 Attach through `D20.Sessions` after SessionChannel authorization succeeds and before after-join Presence tracking.
- [x] 3.2 Replace `D20.Sessions.list/1` all-runtime membership scanning with actor-indexed attachment lookup while preserving return shape and stale-runtime handling.
- [x] 3.3 Make Workspace Close detach synchronously before actor-wide channel shutdown and rebuild snapshots from authoritative attachment discovery.
- [x] 3.4 Publish actor Workspace invalidation only for attachment changes and existing phase or retained-member discovery changes, not online-to-offline Presence.
- [x] 3.5 Add channel tests for multiple tabs and Workspaces, unrelated actors and Sessions, repeated Close, ordinary reload, direct-link reattachment, and finished results.

## 4. Client and Contract Compatibility

- [x] 4.1 Update Workspace unit and browser tests for persistent detach, direct reattachment, retained unrelated iframes, and absence of client closed-id persistence.
- [x] 4.2 Update Workspace AsyncAPI Close and re-entry descriptions and contract tests while preserving payload shapes and `online | offline` member enums.
- [x] 4.3 Verify existing iframe teardown, stable retained iframe identity, reconnect overlay, and accessible Close behavior remain intact.

## 5. Validation and Completion

- [x] 5.1 Format touched Elixir files and run targeted Registry, Session, Sessions, game-server, SessionChannel, WorkspaceChannel, projection, and AsyncAPI tests.
- [x] 5.2 Run targeted Workspace frontend tests, frontend type checking, and affected lint checks.
- [x] 5.3 Run `just check` and `openspec validate --all --strict --no-interactive`, resolve every failure, and archive the completed change.
