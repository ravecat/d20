## MODIFIED Requirements

### Requirement: Live finished Sessions remain discoverable

Workspace SHALL report every live configured finished Session where the actor remains a retained member with an active attachment. It SHALL exclude detached, waiting, unconfigured, terminated, and non-member Sessions independently of Presence status.

#### Scenario: Attached game finishes

- **WHEN** an attached in-progress Session becomes finished
- **THEN** the next complete snapshot retains it

#### Scenario: Attached offline actor opens results

- **WHEN** an offline retained actor attachment joins a fresh Workspace
- **THEN** the snapshot includes the finished Session

#### Scenario: Detached actor opens a fresh Workspace

- **WHEN** a retained actor has no attachment to the live finished Session
- **THEN** the snapshot excludes it

### Requirement: Finished Sessions use the existing dismissal lifecycle

Workspace SHALL allow an attached actor to Close finished results. Acceptance SHALL detach that actor and stop matching channels while retaining member profile, game results, and shared runtime.

#### Scenario: Actor closes finished results

- **WHEN** an attached actor closes a finished Session
- **THEN** every actor Workspace omits and unmounts it
- **AND** every matching actor SessionChannel leaves
- **AND** retained membership, terminal game state, and runtime remain unchanged except member Presence becomes offline

#### Scenario: Actor reloads after closing results

- **WHEN** the detached actor creates a fresh Workspace
- **THEN** the finished Session remains absent

#### Scenario: Actor follows a direct results link

- **WHEN** a valid direct SessionChannel join recreates the actor attachment
- **THEN** all actor Workspaces restore the finished Session
- **AND** the module receives its retained terminal projection

### Requirement: Workspace wire shapes remain compatible

Finished Session discovery SHALL keep the existing Workspace join reply, `snapshot`, descriptor, module connection, and common `close_session` schemas. Attachment state SHALL remain server-internal.

#### Scenario: Finished result is closed and restored

- **WHEN** a client closes and later directly rejoins a finished Session
- **THEN** all messages use existing Workspace and Session payload shapes
- **AND** member status remains `online | offline`
