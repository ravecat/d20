# workspace-web-boundary Specification

## Purpose
TBD - created by archiving change extract-workspace-module. Update Purpose after archive.
## Requirements
### Requirement: Workspace web boundary owns actor invalidation

`D20Web.Workspace` SHALL own the private actor workspace topic, subscription, Session discovery comparison, and invalidation publication. `D20.Sessions` SHALL NOT subscribe to or publish workspace transport messages.

#### Scenario: Session phase changes

- **WHEN** an accepted Session transition changes its phase
- **THEN** `D20Web.Workspace` publishes `{:sessions_changed, actor_id}` for every actor in the union of previous and current Session members

#### Scenario: Session membership changes

- **WHEN** the set of member ids changes
- **THEN** both added and removed actors receive workspace invalidation

#### Scenario: Discovery state is unchanged

- **WHEN** only game state or existing member attributes change without changing phase or member ids
- **THEN** no workspace invalidation is published

### Requirement: Workspace web boundary builds complete actor snapshots

`D20Web.Workspace` SHALL build complete workspace snapshots from `D20.Sessions.list_runtime/1`, current game registry entries, and the authenticated socket request context. It SHALL return the snapshot together with the runtime mapping required by the subscribing channel.

#### Scenario: Eligible runtimes are projected

- **WHEN** the actor is a durable member of one or more live configured in-progress Sessions
- **THEN** the snapshot contains one descriptor per eligible Session ordered by Session id
- **AND** every descriptor retains the existing `id`, `slug`, `module`, and actor-bound `connection` fields

#### Scenario: Runtime is not eligible

- **WHEN** a Session is waiting, finished, missing the actor from durable membership, or has no configured game module
- **THEN** the snapshot excludes that Session

### Requirement: WorkspaceChannel owns connection process lifecycle

`D20Web.WorkspaceChannel` SHALL use `D20Web.Workspace` for actor subscription and snapshot construction while retaining authorization, close handling, process monitoring, socket state, and client pushes.

#### Scenario: Workspace invalidation arrives

- **WHEN** a subscribed WorkspaceChannel receives `{:sessions_changed, actor_id}` for its current actor
- **THEN** it obtains a fresh complete snapshot from `D20Web.Workspace`
- **AND** synchronizes its runtime monitors
- **AND** pushes the unchanged `snapshot` event to the client

#### Scenario: Reported runtime terminates

- **WHEN** a runtime monitored by WorkspaceChannel terminates
- **THEN** the channel obtains a fresh complete snapshot
- **AND** pushes a snapshot without the terminated runtime

### Requirement: Session publication precedes workspace invalidation

`D20.Game.Server` SHALL continue to publish an accepted Session update directly to the existing SessionChannel topic and SHALL then delegate workspace invalidation to `D20Web.Workspace`.

#### Scenario: Accepted transition changes discovery

- **WHEN** an accepted Session transition changes phase or member ids
- **THEN** SessionChannel subscribers receive `{:session, session}` through the existing topic
- **AND** affected WorkspaceChannel processes receive actor invalidation through `D20Web.Workspace`

#### Scenario: Accepted transition does not change discovery

- **WHEN** an accepted Session transition changes only game state or existing member attributes
- **THEN** SessionChannel subscribers receive the updated Session
- **AND** workspace discovery is not invalidated

### Requirement: Workspace extraction preserves public contracts

The refactor SHALL preserve the `workspace` channel topic, join reply, `snapshot` event, `close` operation, SessionChannel projection delivery, descriptor shape, Session and game state behavior, runtime supervision, and AsyncAPI contracts.

#### Scenario: Existing client connects after refactor

- **WHEN** a client uses the existing workspace and SessionChannel contracts
- **THEN** it observes the same replies, events, payloads, and runtime behavior as before the extraction
