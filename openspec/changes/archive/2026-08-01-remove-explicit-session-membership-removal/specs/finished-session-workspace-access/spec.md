## MODIFIED Requirements

### Requirement: Finished Sessions use the existing dismissal lifecycle

The Workspace SHALL allow an authenticated durable member to dismiss a reported finished Session in the current browser tab. Dismissal SHALL unmount the local result window without removing Session membership or stopping the shared runtime.

#### Scenario: Actor dismisses finished results

- **WHEN** an authenticated durable member closes a reported finished Session window
- **THEN** the current Workspace immediately suppresses and unmounts that result window
- **AND** Session membership and the shared runtime remain unchanged
- **AND** other actor tabs remain unaffected

#### Scenario: Actor reloads after dismissing finished results

- **GIVEN** the finished Session remains live and contains the actor in `session.members`
- **WHEN** the actor creates a fresh Workspace through a full reload
- **THEN** the join snapshot reports the finished Session again
- **AND** Workspace remounts its result window

### Requirement: Workspace wire shapes remain compatible

Finished Session discovery SHALL use the Workspace join reply, `snapshot` event, Session descriptor, and module connection schemas without adding a phase-specific result payload or close operation.

#### Scenario: Finished descriptor uses the discovery schema

- **WHEN** a Workspace snapshot reports a finished Session
- **THEN** its descriptor contains the existing id, slug, phase, module, and connection fields
- **AND** the client can connect to the Session without a finished-specific payload

#### Scenario: Finished window is dismissed

- **WHEN** the client closes a finished result window
- **THEN** no Workspace protocol message is sent
- **AND** the common local dismissal state removes the window
