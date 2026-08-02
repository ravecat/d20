## MODIFIED Requirements

### Requirement: Default game server preserves shared session lifecycle behavior

The default game server SHALL preserve state access, command dispatch, Presence membership and admission, actor attachment and detachment, publication, idle expiration, registration, supervision, and temporary restart semantics. Attachment mutations SHALL be serialized by the Session process and SHALL remain distinct from game-engine commands.

#### Scenario: Actor attaches

- **WHEN** the default game server receives an authenticated attach call
- **THEN** its process idempotently registers `actor_id -> session_id` in `D20.Sessions.Registry`
- **AND** a new relationship invalidates that actor's Workspace
- **AND** no game command or Session projection change occurs solely for attachment

#### Scenario: Actor detaches

- **WHEN** the default game server receives an authenticated detach call
- **THEN** its process removes only its own attachment under that actor id
- **AND** normalizes an existing retained member to offline
- **AND** preserves game state and runtime
- **AND** invalidates Workspace only when the relationship existed

#### Scenario: Presence online admits a player

- **WHEN** the default game server receives normalized Presence online
- **THEN** it updates retained membership and attempts internal game `join`
- **AND** it does not create attachment implicitly

#### Scenario: Presence offline changes status

- **WHEN** the default game server receives normalized Presence offline
- **THEN** it marks an existing member offline
- **AND** it does not detach or issue game `left`

#### Scenario: Custom server inherits the lifecycle

- **WHEN** a custom server uses `D20.Game.Server` without overriding attachment handling
- **THEN** it inherits attach, detach, Presence, publication, and idle behavior

### Requirement: Public session APIs remain runtime-implementation agnostic

The system SHALL expose runtime-agnostic `D20.Sessions` create, list, get, attach, detach, dispatch, preview, lookup, and stop contracts without exposing raw `:gen_statem` or Registry operations.

#### Scenario: SessionChannel attaches through shared API

- **WHEN** SessionChannel calls `D20.Sessions.attach/1` with authenticated scope
- **THEN** the configured default or custom server owns the Registry mutation

#### Scenario: Workspace detaches through shared API

- **WHEN** Workspace calls `D20.Sessions.detach/2` with authenticated scope and Session id
- **THEN** the configured default or custom server owns the Registry mutation
- **AND** missing runtime and absent relationship can be treated idempotently by the web workflow

#### Scenario: Caller uses existing Session APIs

- **WHEN** a caller gets, dispatches, previews, or stops a Session
- **THEN** existing success and error shapes remain independent of the concrete server module
