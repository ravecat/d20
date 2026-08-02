## MODIFIED Requirements

### Requirement: Workspace web boundary owns actor invalidation

`D20Web.Workspace` SHALL own the private actor workspace topic, subscription, snapshot construction, and invalidation publication. Discovery changes SHALL include Session phase, retained member ids, and actor attachment creation or removal. Online-to-offline Presence and member profile changes SHALL NOT invalidate Workspace.

#### Scenario: Session phase or membership changes

- **WHEN** an accepted Session transition changes eligible phase or retained member ids
- **THEN** affected actors receive `{:sessions_changed, actor_id}`

#### Scenario: Actor attachment changes

- **WHEN** a Session process creates or removes an actor attachment
- **THEN** that actor receives `{:sessions_changed, actor_id}`

#### Scenario: Presence changes only

- **WHEN** an attached retained member changes between online and offline
- **THEN** no Workspace invalidation is required

### Requirement: Workspace web boundary builds complete actor snapshots

`D20Web.Workspace` SHALL build complete snapshots from the single actor-indexed `D20.Sessions.list/1` query, retained membership, game registry entries, and authenticated socket request context. `D20.Sessions.list/1` SHALL use `D20.Sessions.Registry` attachments rather than selecting all runtime names.

#### Scenario: Attached runtimes are projected

- **WHEN** the actor has attachments to live configured in-progress or finished Sessions where it remains a retained member
- **THEN** the snapshot contains one ordered descriptor per eligible Session
- **AND** each entry provides the PID required for monitoring

#### Scenario: Detached membership is retained

- **WHEN** the actor remains in `session.members` but has no attachment to that Session
- **THEN** the snapshot excludes the Session

#### Scenario: Runtime is not eligible

- **WHEN** an attached Session is waiting, terminated, missing the actor from retained membership, or unconfigured
- **THEN** the snapshot excludes it

### Requirement: Workspace web boundary coordinates actor Session close

`D20Web.Workspace` SHALL coordinate Close for one authenticated actor and one Session by synchronously detaching through `D20.Sessions` and then publishing the private actor close message. Close SHALL retain Session membership, game state, and runtime lifecycle.

#### Scenario: Close is coordinated across actor Workspaces

- **WHEN** WorkspaceChannel accepts Close for an attached actor and Session
- **THEN** `D20Web.Workspace` detaches that actor through the Session runtime
- **AND** publishes `{:close_session, actor_id, session_id}`
- **AND** every actor Workspace rebuilds a complete snapshot omitting the Session
- **AND** later snapshots continue to omit it while detached

#### Scenario: Matching SessionChannels leave

- **WHEN** the actor-scoped Close message is published
- **THEN** every matching actor SessionChannel stops normally
- **AND** other Sessions and actors remain active

#### Scenario: Close is repeated or missing

- **WHEN** the runtime is missing, the actor is unrelated, or its attachment is already absent
- **THEN** Close remains an idempotent success
- **AND** no unrelated relationship or state changes

### Requirement: WorkspaceChannel owns connection process lifecycle

`D20Web.WorkspaceChannel` SHALL use `D20Web.Workspace` for subscription, snapshot construction, and authenticated Close coordination while retaining runtime monitoring, pushes, and unsupported-event rejection. It SHALL NOT call raw Registry functions or mutate Session state directly.

#### Scenario: Client closes a Session attachment

- **WHEN** an authenticated actor sends `close_session` with a binary Session id
- **THEN** WorkspaceChannel delegates scope and id to `D20Web.Workspace`
- **AND** replies successfully after detach or an idempotent no-op

#### Scenario: Actor close message arrives

- **WHEN** WorkspaceChannel receives its actor's close message
- **THEN** it rebuilds from authoritative `D20.Sessions.list/1`
- **AND** synchronizes monitors and pushes a complete snapshot

#### Scenario: Unsupported event arrives

- **WHEN** any other application event is received
- **THEN** WorkspaceChannel replies `unsupported_event`
- **AND** performs no Session or Registry mutation

### Requirement: Session publication precedes workspace invalidation

`D20.Game.Server` SHALL publish a changed Session projection before delegating Workspace invalidation. Attachment-only changes MAY invalidate Workspace without publishing an unchanged Session projection.

#### Scenario: Detach also changes member status

- **WHEN** detach changes an online retained member to offline
- **THEN** SessionChannel subscribers receive the updated Session first
- **AND** Workspace is then invalidated for the detached actor

#### Scenario: Attach changes only the Registry

- **WHEN** a successful SessionChannel join creates an attachment for an already retained actor
- **THEN** Workspace is invalidated for that actor
- **AND** no unchanged Session projection is published solely for attachment

### Requirement: Workspace extraction preserves public contracts

The Workspace boundary SHALL preserve the `workspace` topic, join reply, `snapshot` event, descriptor shape, Session projection delivery, game state behavior, and runtime supervision while making `close_session` remove the actor attachment authoritatively.

#### Scenario: Current client closes a Session

- **WHEN** an authenticated attached actor sends valid `close_session`
- **THEN** WorkspaceChannel replies successfully
- **AND** every active actor Workspace receives a complete snapshot omitting that Session
- **AND** retained membership and game state remain available
