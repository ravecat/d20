## RENAMED Requirements

- FROM: `Full page reload does not promise restoration`
- TO: `Full page reload follows authoritative attachment state`

## MODIFIED Requirements

### Requirement: Eligibility follows current runtime state

A Session SHALL be eligible only when its runtime is alive, phase is `in_progress` or `finished`, slug is configured, the actor remains a retained member, and `D20.Sessions.Registry` contains the actor-to-Session attachment. Online or offline Presence SHALL NOT change eligibility, and ownership alone SHALL NOT grant it.

#### Scenario: Attached retained member is evaluated

- **WHEN** an attached retained-member Session is live, configured, and in-progress or finished
- **THEN** Workspace includes it

#### Scenario: Attached member is offline

- **WHEN** the actor attachment remains while Presence is offline
- **THEN** Workspace continues to include that Session

#### Scenario: Retained member is detached

- **WHEN** `session.members` contains the actor but its attachment is absent
- **THEN** Workspace excludes that Session

### Requirement: Accepted transitions and Presence publish realtime snapshots

The server SHALL invalidate affected actor Workspaces after eligible phase, retained membership, attach, or detach changes. Online-to-offline Presence alone SHALL NOT change Workspace discovery.

#### Scenario: Actor attaches through SessionChannel

- **WHEN** a successful join creates an actor attachment to an eligible Session
- **THEN** every actor Workspace receives a complete snapshot containing it

#### Scenario: Actor detaches through Close

- **WHEN** accepted Close removes the selected actor attachment
- **THEN** every actor Workspace receives a complete snapshot omitting it

#### Scenario: Final Presence meta leaves ordinarily

- **WHEN** an attached actor's final Presence meta leaves without Close
- **THEN** member status becomes offline
- **AND** Workspace eligibility remains unchanged

### Requirement: Workspace reconciliation supports multiple stable windows

The workspace SHALL reconcile authoritative snapshots by Session id and SHALL NOT maintain a client-side closed-id set. Close persistence and re-entry SHALL be derived from server-owned attachments.

#### Scenario: Detached Session stays absent

- **WHEN** a fresh authoritative snapshot omits a detached Session
- **THEN** its iframe remains unmounted
- **AND** no browser-local exclusion is required

#### Scenario: Direct re-entry restores a Session

- **WHEN** a successful direct SessionChannel join recreates an attachment
- **THEN** every actor Workspace reconciles the returned Session as an addition

#### Scenario: Unrelated retained window survives

- **WHEN** one selected Session is detached
- **THEN** other retained Session ids keep their iframe identity and presentation state

### Requirement: Window close is actor-wide and Session-scoped

Each game window SHALL expose Close for its selected Session. After acceptance, the selected actor attachment SHALL be removed, every active actor Workspace SHALL unmount the matching window, and every matching actor SessionChannel SHALL leave, without deleting membership, changing game player state, stopping the runtime, or affecting another Session or actor.

#### Scenario: Actor closes one game in multiple Workspaces

- **WHEN** the actor closes Session A while Session A and B are visible in two Workspaces
- **THEN** only the actor-to-Session A attachment is removed
- **AND** both Workspaces omit A and retain B
- **AND** matching Session A channels stop

#### Scenario: Later snapshot is built

- **WHEN** ordinary discovery runs after Close
- **THEN** it continues to omit the detached Session

### Requirement: WorkspaceChannel accepts only the close_session application command

WorkspaceChannel SHALL accept self-scoped `close_session`, reject other application events, and delegate attachment mutation to the authenticated Session runtime.

#### Scenario: Attached actor closes

- **WHEN** an authenticated actor sends `close_session` for an attached Session
- **THEN** WorkspaceChannel replies successfully
- **AND** the Session runtime removes only that actor attachment

#### Scenario: Missing or detached target closes

- **WHEN** Close targets a missing runtime, unrelated Session, or absent attachment
- **THEN** WorkspaceChannel replies successfully as an idempotent no-op

### Requirement: Full page reload follows authoritative attachment state

The client SHALL persist no Session discovery or closed-id state in browser storage. A fresh Workspace SHALL restore only Sessions returned by the server-owned attachment index.

#### Scenario: Document reloads during attachment

- **WHEN** reload temporarily makes an attached member offline
- **THEN** the Registry attachment remains
- **AND** the new Workspace snapshot restores the Session

#### Scenario: Document reloads after Close

- **WHEN** a fresh Workspace joins after the actor detached a Session
- **THEN** the snapshot excludes it
- **AND** client state does not recreate it
