## ADDED Requirements

### Requirement: Workspace web boundary coordinates actor Session close

`D20Web.Workspace` SHALL coordinate an accepted Close for one authenticated actor and one concrete Session through the private actor Workspace topic. WorkspaceChannel and SessionChannel processes for that actor SHALL subscribe to the topic. Close SHALL NOT mutate Session membership, game state, or runtime lifecycle.

#### Scenario: Close is coordinated across active actor Workspaces

- **WHEN** WorkspaceChannel accepts Close for an actor and Session
- **THEN** `D20Web.Workspace` publishes `{:close_session, actor_id, session_id}` to every active WorkspaceChannel for that actor
- **AND** each matching WorkspaceChannel pushes one replacement snapshot with that Session id omitted
- **AND** no retained exclusion state is created

#### Scenario: Matching SessionChannels leave

- **WHEN** the actor-scoped Close is coordinated
- **THEN** every SessionChannel for that actor receives `{:close_session, actor_id, session_id}` through the actor Workspace topic
- **AND** only SessionChannels whose scope contains that Session id handle the command by stopping normally
- **AND** SessionChannels for the actor's other Sessions remain active
- **AND** channels belonging to other actors do not receive the command

## MODIFIED Requirements

### Requirement: WorkspaceChannel owns connection process lifecycle

`D20Web.WorkspaceChannel` SHALL use `D20Web.Workspace` for actor subscription, snapshot construction, and Close coordination while retaining process monitoring, client pushes, and rejection of unsupported client application events. It SHALL NOT own Session membership mutation.

#### Scenario: Workspace invalidation arrives

- **WHEN** a subscribed WorkspaceChannel receives `{:sessions_changed, actor_id}` for its current actor
- **THEN** it obtains a fresh complete snapshot from `D20Web.Workspace`
- **AND** synchronizes its runtime monitors
- **AND** pushes the unchanged `snapshot` event to the client

#### Scenario: Reported runtime terminates

- **WHEN** a runtime monitored by WorkspaceChannel terminates
- **THEN** the channel obtains a fresh complete snapshot
- **AND** pushes a snapshot without the terminated runtime

#### Scenario: Client closes a Session attachment

- **WHEN** an authenticated actor sends `close_session` with a binary Session id
- **THEN** WorkspaceChannel coordinates Close through `D20Web.Workspace`
- **AND** replies successfully without resolving or mutating the Session

#### Scenario: Missing attachment is an idempotent no-op

- **WHEN** the actor has no matching SessionChannel for the supplied id
- **THEN** WorkspaceChannel still accepts `close_session`
- **AND** no other actor or Session is affected

#### Scenario: Client sends an unsupported application event

- **WHEN** an authenticated WorkspaceChannel receives any application event other than valid `close_session`
- **THEN** it replies with `unsupported_event`
- **AND** it does not call `D20.Sessions` dispatch or mutate Session state

### Requirement: Workspace extraction preserves public contracts

The Workspace boundary SHALL preserve the `workspace` channel topic, join reply, `snapshot` event, SessionChannel projection delivery, descriptor shape, Session and game state behavior, and runtime supervision while adding the actor-scoped `close_session` command.

#### Scenario: Current client connects

- **WHEN** a client joins the workspace and consumes complete snapshots
- **THEN** it observes the existing join reply, snapshot payloads, runtime monitoring, and iframe connection descriptors
- **AND** it sends `close_session` only when the actor activates a Session window Close control

#### Scenario: Current client closes a Session

- **WHEN** an authenticated durable member sends valid `close_session`
- **THEN** WorkspaceChannel replies successfully
- **AND** every active Workspace for that actor receives a complete snapshot omitting that Session
- **AND** Session membership and game state remain unchanged

### Requirement: Workspace web boundary owns actor invalidation

`D20Web.Workspace` SHALL own the private actor workspace topic, subscription, Session discovery comparison, and invalidation publication. Discovery comparison SHALL include Session phase and durable member ids, but SHALL NOT use Presence status.

#### Scenario: Session member status changes

- **WHEN** Presence changes an existing member between online and offline
- **THEN** durable Workspace discovery remains unchanged

#### Scenario: Non-discovery member metadata changes

- **WHEN** an existing member remains online and only profile or last-online metadata changes
- **THEN** no workspace invalidation is required

### Requirement: Workspace web boundary builds complete actor snapshots

`D20Web.Workspace` SHALL build complete workspace snapshots from the runtime entries returned by the single `D20.Sessions.list/1` query, durable membership, game registry entries, and the authenticated socket request context. `D20.Sessions` SHALL NOT expose a redundant state-only list alongside that runtime query.

#### Scenario: Eligible runtimes are projected

- **WHEN** the actor is a durable member of one or more live configured in-progress or finished Sessions
- **THEN** the snapshot contains one descriptor per eligible Session ordered by Session id
- **AND** each listed entry provides the pid required for WorkspaceChannel runtime monitoring

#### Scenario: Offline membership remains discoverable

- **WHEN** the actor remains a durable member with `status: offline`
- **THEN** the snapshot may include that Session independently of Presence status

#### Scenario: Legacy or invalid client sends another event

- **WHEN** a client sends an application event other than valid `close_session`
- **THEN** WorkspaceChannel replies with `unsupported_event`
- **AND** Session membership and game state remain unchanged
