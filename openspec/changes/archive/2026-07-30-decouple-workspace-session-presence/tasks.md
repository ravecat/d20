## 1. Separate Participation and Presence

- [x] 1.1 Add required online or offline status to Session member state and projection types.
- [x] 1.2 Keep game join and left commands independent from Session membership.
- [x] 1.3 Make online add or refresh members and offline retain existing members without invoking the game engine.
- [x] 1.4 Add explicit Session member removal without notifying the game engine.
- [x] 1.5 Cover duplicate joins, multi-meta status, delayed status after removal, reconnect, and explicit removal in Session tests.

## 2. Establish Publication Boundaries

- [x] 2.1 Add actor discovery subscription and publication functions to `D20.Sessions`.
- [x] 2.2 Publish Session state directly to SessionChannel after every accepted change and actor discovery only after phase or member-id changes.
- [x] 2.3 Remove the WorkspaceChannel alias and Presence ref replacement logic from `D20.Game.Server`.
- [x] 2.4 Update custom-server and runtime tests for neutral publication and status transitions.

## 3. Decouple Phoenix Presence and Channels

- [x] 3.1 Normalize Presence joins to online and final-meta leaves to offline without Workspace invalidation.
- [x] 3.2 Make SessionChannel track trusted Presence metadata without directly admitting membership or blocking game join and left commands.
- [x] 3.3 Make WorkspaceChannel subscribe through `D20.Sessions`, invoke explicit member removal on close, and remove Presence inspection and invalidation helpers.
- [x] 3.4 Cover Presence admission, offline retention, multi-tab Presence, explicit close, reload snapshot, and runtime monitoring.
- [x] 3.5 Restore Presence ownership of its private PubSub topic, subscription API, and normalized status broadcasts.
- [x] 3.6 Resolve trusted member profile data in SessionChannel and restrict stored Presence metadata to member fields.

## 4. Simplify Lobby and Workspace Clients

- [x] 4.1 Remove `handoff_ready` from Workspace protocol types, normalization, entry state, and reconciliation.
- [x] 4.2 Remove retained Presence leases and Session controller transfer behavior from the workspace store.
- [x] 4.3 Make Lobby detach its Session store through normal component cleanup immediately after start or finish.
- [x] 4.4 Render only online Lobby members while retaining offline members in authoritative Session state.
- [x] 4.5 Update focused Svelte and TypeScript tests for immediate Lobby cleanup, stable iframe reconciliation, close, stale recovery, and member status.

## 5. Update Public Contracts and Specifications

- [x] 5.1 Remove `handoff_ready` from `priv/specs/workspace.yaml` and document durable membership reload behavior.
- [x] 5.2 Add required member status to every game Session AsyncAPI member schema and update Presence wording.
- [x] 5.3 Validate all affected AsyncAPI and OpenSpec documents.

## 6. Validate Integrated Behavior

- [x] 6.1 Format touched Elixir, TypeScript, Svelte, YAML, and OpenSpec files with repository-native commands.
- [x] 6.2 Run focused Session, game-server, Presence, SessionChannel, WorkspaceChannel, projection, and frontend tests.
- [x] 6.3 Run frontend typecheck, lint, tests, and build plus the complete backend test suite.
- [x] 6.4 Validate in a real browser: Lobby creation and start, Workspace iframe opening, hard reload restoration, explicit close across snapshots, and absence of join loops or console errors.
