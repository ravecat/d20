## MODIFIED Requirements

### Requirement: Default game server preserves shared session lifecycle behavior
The default Session server SHALL preserve state access, command dispatch, Presence membership and admission, actor attachment and detachment, publication, idle expiration, registration, supervision, and temporary restart semantics while carrying stable local game id. Attachment mutations SHALL be serialized by the Session process and SHALL remain distinct from engine commands.

#### Scenario: Session state is requested
- **WHEN** `D20.Sessions.get/1` resolves a running default Session server
- **THEN** it returns the current live Session and captured `game` TypeID through the public API

#### Scenario: Command is accepted
- **WHEN** the engine accepts a dispatched command
- **THEN** the default Session server stores the updated Session
- **AND** replies with and publishes the same authoritative Session
- **AND** derives its next state name from the shared Session lifecycle phase

#### Scenario: Command is rejected
- **WHEN** the engine rejects a dispatched command
- **THEN** the default Session server preserves its current state name and Session data
- **AND** returns the engine error without publishing a new Session

#### Scenario: Actor attaches
- **WHEN** the default Session server receives an authenticated attach call from `D20.Sessions`
- **THEN** its process idempotently registers `actor_id -> session_id` in `D20.Sessions.Registry`
- **AND** a new relationship invalidates that actor's Workspace
- **AND** no engine command or Session projection change occurs solely for attachment

#### Scenario: Actor detaches
- **WHEN** the default Session server receives an authenticated detach call from `D20.Sessions`
- **THEN** its process removes only its own attachment under that actor id
- **AND** normalizes an existing retained member to offline
- **AND** preserves game state and runtime
- **AND** invalidates Workspace only when the relationship existed

#### Scenario: Presence online admits a player
- **WHEN** the default Session server receives normalized Presence online
- **THEN** it updates retained membership and attempts internal game `join`
- **AND** it does not create attachment implicitly

#### Scenario: Presence game admission is rejected
- **WHEN** Session membership accepts an online actor and the engine rejects internal `join`
- **THEN** the default Session server stores and publishes the online membership update
- **AND** preserves engine state
- **AND** does not expose the engine rejection as a transport failure

#### Scenario: Presence offline changes status
- **WHEN** the default Session server receives normalized Presence offline
- **THEN** it marks an existing member offline
- **AND** it does not detach or issue game `left`

#### Scenario: Session remains idle
- **WHEN** the default Session server receives no supported activity for the configured idle timeout
- **THEN** it stops normally and is not restarted

#### Scenario: Custom server inherits the lifecycle
- **WHEN** a custom server uses `D20.Sessions.Server` without overriding attachment handling
- **THEN** it inherits game-id state, attach, detach, Presence, publication, and idle behavior

### Requirement: Public session APIs remain runtime-implementation agnostic
The system SHALL expose runtime-agnostic `D20.Sessions` create, list, get, attach, detach, dispatch, preview, lookup, and stop contracts without exposing raw `:gen_statem` or Registry operations. Session creation SHALL resolve its canonical `game` TypeID through the persisted game boundary and accept a validated engine. Scope mutation and server initialization SHALL trust that resolved id without duplicate guards, and Session/runtime types SHALL reference the Game schema's owning id type directly rather than defining proxy aliases. The server behaviour SHALL NOT duplicate attachment and detachment as caller-facing callbacks.

#### Scenario: Session is created for a persisted game
- **WHEN** a caller creates a Session with local game id, validated engine, owner, and attrs
- **THEN** the selected default or custom server captures that game id and engine
- **AND** returns the initialized Session through the common result shape

#### Scenario: SessionChannel attaches through shared API
- **WHEN** SessionChannel calls `D20.Sessions.attach/1` with authenticated scope
- **THEN** the configured default or custom server owns the Registry mutation

#### Scenario: Workspace detaches through shared API
- **WHEN** Workspace calls `D20.Sessions.detach/2` with authenticated scope and Session id
- **THEN** the configured default or custom server owns the Registry mutation
- **AND** missing runtime and absent relationship may be treated idempotently

#### Scenario: Server contract is inspected
- **WHEN** a default or custom Session server implements the shared runtime behaviour
- **THEN** `attach/2` and `detach/2` are not behaviour callbacks or generated client delegates
- **AND** attachment calls enter through `D20.Sessions`

#### Scenario: Caller uses shared Session API
- **WHEN** a caller interacts with either a default or custom server
- **THEN** `D20.Sessions` resolves the registered server implementation
- **AND** returns the same success and error shapes regardless of concrete server

#### Scenario: Caller stops a Session
- **WHEN** a caller stops a running Session through `D20.Sessions.stop/3`
- **THEN** the system stops the registered `:gen_statem` with the requested reason and timeout
- **AND** treating an already stopped process remains idempotent

#### Scenario: Caller uses existing Session APIs
- **WHEN** a caller gets, dispatches, previews, or stops a Session
- **THEN** success and error shapes remain independent of the concrete server module
