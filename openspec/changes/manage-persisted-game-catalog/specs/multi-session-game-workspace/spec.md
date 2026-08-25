## MODIFIED Requirements

### Requirement: WorkspaceChannel returns complete authoritative snapshots
Every successful join and every `snapshot` event SHALL contain a complete replacement `sessions` collection derived from current runtime state and stable local game association.

#### Scenario: Actor has multiple eligible Sessions
- **GIVEN** the actor is an attached retained member of two live in-progress Sessions
- **WHEN** WorkspaceChannel builds a snapshot
- **THEN** both descriptors are returned
- **AND** Sessions with the same `game_id` remain distinct by Session `id`

#### Scenario: Actor has no eligible Session
- **WHEN** WorkspaceChannel finds no eligible Session
- **THEN** it returns an empty `sessions` collection

### Requirement: Eligibility follows current runtime state
A Session SHALL be eligible only when its runtime is alive, phase is `in_progress` or `finished`, captured local game id resolves to a persisted record, the actor remains a retained member, and `D20.Sessions.Registry` contains the actor-to-Session attachment. Enabled, implementation stage, current engine, current BGG binding, and online/offline Presence MUST NOT alter existing-Session eligibility, and ownership alone SHALL NOT grant it.

#### Scenario: Attached retained member is evaluated
- **WHEN** an attached retained-member Session is live, associated with a persisted game id, and in-progress or finished
- **THEN** Workspace includes it

#### Scenario: Attached member is offline
- **WHEN** the actor attachment remains while Presence is offline
- **THEN** Workspace continues to include that Session

#### Scenario: Retained member is detached
- **WHEN** `session.members` contains the actor but its attachment is absent
- **THEN** Workspace excludes that Session

#### Scenario: Owner is no longer a member
- **GIVEN** an actor owns an in-progress Session
- **AND** the actor id is absent from `session.members`
- **WHEN** Workspace builds a snapshot
- **THEN** it excludes that Session

#### Scenario: Local game no longer resolves
- **WHEN** an otherwise eligible Session carries a local game id absent from persistence
- **THEN** Workspace excludes that Session
- **AND** other valid descriptors remain available

#### Scenario: Game is disabled or edited
- **WHEN** an otherwise eligible running Session's persisted game is disabled or its BGG, stage, or engine field changes
- **THEN** Workspace continues to include the Session under the same local game id
- **AND** its captured Session engine remains unchanged

### Requirement: Descriptors contain module bootstrap and handoff state
Every descriptor SHALL contain Session `id`, string `game_id` with a canonical `game` TypeID, phase, module framing, and fresh actor-bound connection, and SHALL omit cosmetic slug and `handoff_ready`. Descriptor generation SHALL use the authenticated actor and socket request context.

#### Scenario: Eligible descriptor is projected
- **WHEN** Workspace reports an eligible Session
- **THEN** `connection.topic` identifies that existing SessionChannel
- **AND** `connection.token` is signed for the authenticated actor, Session topic, and local game id
- **AND** module URLs use the browser-facing socket scheme and stable DNS-safe `game-<typeid-suffix>` host

#### Scenario: TLS terminates before Phoenix
- **GIVEN** the browser connects securely through the trusted production proxy
- **AND** Phoenix receives the socket upgrade through internal HTTP
- **WHEN** Workspace builds a module descriptor
- **THEN** the Endpoint normalizes the trusted forwarded scheme
- **AND** iframe URL uses HTTPS
- **AND** module endpoint uses WSS with the public port

#### Scenario: Credentials refresh
- **GIVEN** a retained Session receives fresh connection data
- **WHEN** the workspace reconciles the snapshot
- **THEN** it stores the new descriptor
- **AND** does not recreate the retained iframe or SDK bridge

### Requirement: Waiting sessions remain page-owned
Successful creation SHALL redirect with status 303 to `/games/:game_id?session=<id>`. A valid query-selected waiting Session SHALL render in Lobby and SHALL NOT appear in Workspace. The detail GET SHALL remain on the id-only URL without a cosmetic redirect.

#### Scenario: Successful creation opens Lobby
- **WHEN** Session creation succeeds
- **THEN** the redirect selects the live waiting Session on its matching local game id page
- **AND** Lobby presents waiting controls and member state

#### Scenario: Invalid selected Session
- **WHEN** the selected Session is missing or carries another local game id
- **THEN** the page does not expose it as Lobby state
- **AND** page props expose no module token
