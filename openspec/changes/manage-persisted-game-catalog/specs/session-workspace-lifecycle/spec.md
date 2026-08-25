## MODIFIED Requirements

### Requirement: Workspace derives sessions from durable membership
WorkspaceChannel SHALL report every live in-progress or finished Session returned by the authenticated actor's attachment lookup whose captured local game id resolves to a persisted game. The actor SHALL remain a retained member. Waiting, missing-game, non-member, detached, and terminated Sessions SHALL remain excluded independently of Presence, while current enabled, stage, BGG, and engine edits SHALL NOT exclude a running Session.

#### Scenario: Offline attached member joins WorkspaceChannel
- **GIVEN** an actor is an offline retained member with an active attachment to a Session carrying a persisted game id
- **WHEN** the actor joins WorkspaceChannel
- **THEN** the complete snapshot includes that Session

#### Scenario: Offline detached member joins WorkspaceChannel
- **GIVEN** an actor remains an offline retained member without an attachment
- **WHEN** the actor joins WorkspaceChannel
- **THEN** the snapshot excludes that Session

#### Scenario: Runtime terminates
- **WHEN** a reported Session process terminates
- **THEN** the monitoring WorkspaceChannel pushes a complete snapshot without it

#### Scenario: Game is disabled after start
- **WHEN** an operator disables the persisted game associated with an attached running Session
- **THEN** Workspace continues to report the Session
- **AND** no existing SessionChannel is stopped

### Requirement: Lobby transition does not retain a Presence lease
When Lobby observes that its Session is in progress or finished, it SHALL navigate to the id-only game detail URL while the current page Session descriptor continues to own Lobby. The navigation response SHALL remove that descriptor, allowing normal component cleanup to detach the Session store. Workspace discovery SHALL NOT wait for Presence overlap or a handoff flag.

#### Scenario: Waiting Session starts
- **WHEN** Lobby receives an in-progress projection
- **THEN** Lobby requests `/games/:game_id` without a slug segment
- **AND** Lobby remains mounted while navigation is pending
- **AND** the response supplies no selected Session and returns the page to Play only if new launch is currently available
- **AND** normal cleanup detaches Lobby's SessionChannel
- **AND** Workspace mounts the in-progress iframe from retained membership and attachment
- **AND** no Session controller or Presence lease is transferred

#### Scenario: Selected Session is already finished
- **WHEN** Lobby receives a finished projection
- **THEN** it follows the same id-only navigation and response-owned cleanup lifecycle

### Requirement: Workspace descriptors omit Presence handoff state
Workspace join replies and snapshots SHALL contain Session id, string local `game_id` with a canonical `game` TypeID, phase, module bootstrap, and actor-bound connection data without cosmetic slug or `handoff_ready`. Descriptor refresh SHALL preserve retained iframe identity by Session id.

#### Scenario: Workspace receives a descriptor
- **WHEN** an eligible Session is projected
- **THEN** the descriptor contains `id`, `game_id`, `phase`, `module`, and `connection`
- **AND** does not contain `slug` or `handoff_ready`
