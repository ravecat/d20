## MODIFIED Requirements

### Requirement: Live finished Sessions remain discoverable
Workspace SHALL report every live finished Session where the actor remains a retained member with an active attachment and the captured local game id resolves to a persisted game. It SHALL exclude detached, waiting, missing-game, terminated, and non-member Sessions independently of Presence. Current enabled, stage, BGG, or engine edits SHALL NOT remove a live finished Session.

#### Scenario: Attached game finishes
- **WHEN** an attached in-progress Session becomes finished
- **THEN** the next complete snapshot retains it with the same local game id

#### Scenario: Attached offline actor opens results
- **WHEN** an offline retained actor attachment joins a fresh Workspace
- **THEN** the snapshot includes the finished Session

#### Scenario: Detached actor opens a fresh Workspace
- **WHEN** a retained actor has no attachment to the live finished Session
- **THEN** the snapshot excludes it

#### Scenario: Ineligible Sessions remain hidden
- **WHEN** a Session is detached, waiting, associated with a missing game id, terminated, or missing the authenticated actor
- **THEN** Workspace excludes it

#### Scenario: Persisted game is disabled
- **WHEN** an operator disables the game associated with a live finished Session
- **THEN** attached actors retain results access

### Requirement: Workspace wire shapes remain compatible
Finished Session discovery SHALL keep the Workspace join reply, `snapshot`, module connection, and common `close_session` schemas while replacing descriptor slug with string `game` TypeID. Attachment state SHALL remain server-internal.

#### Scenario: Finished descriptor uses the discovery schema
- **WHEN** a Workspace snapshot reports a finished Session
- **THEN** its descriptor contains Session `id`, `game_id`, phase, module, and connection
- **AND** the client can connect without a finished-specific payload

#### Scenario: Finished window is closed
- **WHEN** the client closes a finished result window
- **THEN** it sends common `close_session` with the Session id
- **AND** each active actor Workspace receives a complete snapshot omitting it

#### Scenario: Finished result is closed and restored
- **WHEN** a client closes and later directly rejoins a finished Session
- **THEN** all messages use the revised common Workspace and Session payload shapes
- **AND** member status remains `online | offline`
