## MODIFIED Requirements

### Requirement: Workspace web boundary builds complete actor snapshots
`D20Web.Workspace` SHALL build complete snapshots from the single actor-indexed `D20.Sessions.list/1` query, retained membership, persisted game records resolved by local id, and authenticated socket request context. `D20.Sessions.list/1` SHALL use `D20.Sessions.Registry` attachments rather than selecting all runtime names.

#### Scenario: Attached runtimes are projected
- **WHEN** the actor has attachments to live in-progress or finished Sessions where it remains a retained member and each captured local game id resolves
- **THEN** the snapshot contains one ordered id-based descriptor per eligible Session
- **AND** each entry provides the PID required for monitoring

#### Scenario: Detached membership is retained
- **WHEN** the actor remains in `session.members` but has no attachment to that Session
- **THEN** the snapshot excludes the Session

#### Scenario: Runtime is not eligible
- **WHEN** an attached Session is waiting, terminated, missing the actor, or associated with a missing game id
- **THEN** the snapshot excludes it

#### Scenario: Persisted launch fields change
- **WHEN** an attached running Session's game is disabled or its stage, BGG id, or engine changes
- **THEN** snapshot eligibility and Session engine do not change

### Requirement: Workspace extraction preserves public contracts
The Workspace boundary SHALL preserve the `workspace` topic, join reply, `snapshot` event, Session projection delivery, close behavior, game state, and runtime supervision while replacing descriptor slug with string `game` TypeID.

#### Scenario: Current client connects with revised descriptor
- **WHEN** a client joins Workspace and consumes complete snapshots
- **THEN** it observes the existing join and snapshot envelopes, monitoring, and iframe connection descriptors
- **AND** each descriptor contains `id`, `game_id`, `phase`, `module`, and `connection`
- **AND** it sends `close_session` only when the actor activates a Session window Close control

#### Scenario: Current client closes a Session
- **WHEN** an authenticated attached actor sends valid `close_session`
- **THEN** WorkspaceChannel replies successfully
- **AND** every active actor Workspace receives a complete snapshot omitting that Session
- **AND** retained membership and game state remain available
