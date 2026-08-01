## MODIFIED Requirements

### Requirement: WorkspaceChannel owns connection process lifecycle

`D20Web.WorkspaceChannel` SHALL use `D20Web.Workspace` for actor subscription and snapshot construction while retaining authorization, process monitoring, socket state, client pushes, and rejection of client application events. It SHALL NOT own Session membership mutation.

#### Scenario: Workspace invalidation arrives

- **WHEN** a subscribed WorkspaceChannel receives `{:sessions_changed, actor_id}` for its current actor
- **THEN** it obtains a fresh complete snapshot from `D20Web.Workspace`
- **AND** synchronizes its runtime monitors
- **AND** pushes the unchanged `snapshot` event to the client

#### Scenario: Reported runtime terminates

- **WHEN** a runtime monitored by WorkspaceChannel terminates
- **THEN** the channel obtains a fresh complete snapshot
- **AND** pushes a snapshot without the terminated runtime

#### Scenario: Client sends an application event

- **WHEN** an authenticated WorkspaceChannel receives `close` or any other client application event
- **THEN** it replies with `unsupported_event`
- **AND** it does not call `D20.Sessions` or mutate Session state

### Requirement: Workspace extraction preserves public contracts

The Workspace boundary SHALL preserve the `workspace` channel topic, join reply, `snapshot` event, SessionChannel projection delivery, descriptor shape, Session and game state behavior, and runtime supervision while exposing no client-sent Workspace application operation.

#### Scenario: Current client connects

- **WHEN** a client joins the workspace and consumes complete snapshots
- **THEN** it observes the existing join reply, snapshot payloads, runtime monitoring, and iframe connection descriptors
- **AND** it performs window dismissal without sending a WorkspaceChannel event

#### Scenario: Legacy client sends close

- **WHEN** a client uses the removed Workspace close contract
- **THEN** WorkspaceChannel replies with `unsupported_event`
- **AND** Session membership and game state remain unchanged
