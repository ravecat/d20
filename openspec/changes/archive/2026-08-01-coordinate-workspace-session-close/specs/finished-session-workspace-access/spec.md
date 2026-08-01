## MODIFIED Requirements

### Requirement: Finished Sessions use the existing dismissal lifecycle

The Workspace SHALL allow an authenticated durable member to close a reported finished Session for that actor. After server acceptance, every active actor Workspace SHALL unmount the result window and every matching actor SessionChannel SHALL leave, without removing Session membership or stopping the shared runtime.

#### Scenario: Actor closes finished results

- **WHEN** an authenticated durable member closes a reported finished Session window
- **THEN** every active Workspace for that actor receives a complete snapshot omitting that Session and unmounts its result window
- **AND** every matching actor SessionChannel leaves
- **AND** Session membership, game player state, and the shared runtime remain unchanged

#### Scenario: Actor reloads after closing finished results

- **GIVEN** the finished Session remains live and contains the actor in `session.members`
- **WHEN** the actor creates a fresh Workspace through a full reload
- **THEN** the join snapshot reports the finished Session again
- **AND** Workspace remounts its result window

### Requirement: Live finished Sessions remain discoverable

The Workspace SHALL report every live configured Session whose phase is `in_progress` or `finished` and whose durable `members` contains the authenticated actor. It SHALL exclude waiting, unconfigured, terminated, and non-member Sessions independently of Presence status.

#### Scenario: Attached game finishes

- **WHEN** a reported in-progress Session transitions to `finished` while the authenticated actor remains a durable member
- **THEN** the next complete Workspace snapshot includes that Session descriptor

#### Scenario: Offline actor opens finished results

- **WHEN** an offline durable member joins a fresh Workspace while the finished Session remains live
- **THEN** the complete Workspace snapshot includes that Session descriptor independently of Presence status

#### Scenario: Ineligible Sessions remain hidden

- **WHEN** a Session is waiting, unconfigured, terminated, or missing the authenticated actor
- **THEN** the Workspace snapshot excludes that Session

### Requirement: Workspace wire shapes remain compatible

Finished Session discovery SHALL continue using the Workspace join reply, `snapshot` event, Session descriptor, and module connection schemas without adding a phase-specific result payload. Finished window Close SHALL use the common Workspace `close_session` command and reply, followed by the existing complete `snapshot` event.

#### Scenario: Finished descriptor uses the discovery schema

- **WHEN** a Workspace snapshot reports a finished Session
- **THEN** its descriptor contains the existing id, slug, phase, module, and connection fields
- **AND** the client can connect to the Session without a finished-specific payload

#### Scenario: Finished window is closed

- **WHEN** the client closes a finished result window
- **THEN** it sends the common Workspace `close_session` command with the Session id
- **AND** each active actor Workspace receives a complete snapshot omitting that Session
