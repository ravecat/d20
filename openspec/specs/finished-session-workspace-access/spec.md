# finished-session-workspace-access Specification

## Purpose
TBD - created by archiving change keep-finished-sessions-in-workspace. Update Purpose after archive.
## Requirements
### Requirement: Live finished Sessions remain discoverable

The Workspace SHALL report every live configured Session whose phase is `in_progress` or `finished` and whose durable `members` contains the authenticated actor. It SHALL exclude waiting, unconfigured, terminated, and non-member Sessions.

#### Scenario: Attached game finishes

- **WHEN** a reported in-progress Session transitions to `finished` while the authenticated actor remains a durable member
- **THEN** the next complete Workspace snapshot includes that Session descriptor

#### Scenario: Actor reconnects to finished results

- **WHEN** an actor joins the Workspace while they remain a durable member of a live configured finished Session
- **THEN** the initial snapshot includes that Session descriptor

#### Scenario: Ineligible Sessions remain hidden

- **WHEN** a Session is waiting, unconfigured, terminated, or missing the authenticated actor from durable membership
- **THEN** the Workspace snapshot excludes that Session

### Requirement: Finished game results remain accessible

The system SHALL keep an attached finished Session module available to receive and render its terminal caller-specific projection without adding game-specific result data to the Workspace descriptor.

#### Scenario: Mounted module receives terminal state

- **WHEN** an attached Session publishes its terminal projection and changes phase to `finished`
- **THEN** the Workspace retains the existing Session entry so the mounted module can continue rendering the final results

#### Scenario: Restored module receives terminal state

- **WHEN** the Workspace restores a live finished Session from a new join snapshot
- **THEN** the module can join its existing SessionChannel and receive the current terminal caller-specific projection

### Requirement: Finished Sessions use the existing dismissal lifecycle

The Workspace SHALL allow an authenticated durable member to close a reported finished Session through the existing `close` operation. Closing SHALL remove that actor from Session membership and their Workspace snapshot without stopping the shared runtime for other members.

#### Scenario: Actor closes finished results

- **WHEN** an authenticated durable member closes a reported finished Session
- **THEN** the operation succeeds and the next Workspace snapshot excludes that Session for the actor
- **AND** the Session runtime remains live for its other durable members until normal termination or idle expiry

### Requirement: Workspace wire shapes remain compatible

Finished Session discovery SHALL use the existing Workspace join reply, `snapshot` event, Session descriptor, module connection, and `close` operation schemas without adding a phase or result field.

#### Scenario: Finished descriptor uses the existing schema

- **WHEN** a Workspace snapshot reports a finished Session
- **THEN** its descriptor contains the existing id, slug, module, and connection fields
- **AND** clients require no new Workspace payload handling to connect to the Session
