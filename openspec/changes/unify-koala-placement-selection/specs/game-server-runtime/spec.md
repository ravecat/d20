## MODIFIED Requirements

### Requirement: Default game server preserves shared session lifecycle behavior
The default Session server SHALL preserve state access, command dispatch, Presence membership and admission, actor attachment and detachment, publication, idle expiration, registration, supervision, and temporary restart semantics. Attachment mutations SHALL be serialized by the Session process and SHALL remain distinct from game-engine commands. Accepted dispatches SHALL use only `:ok` and `:error` result status atoms and SHALL represent either an authoritative Session result or the exact unchanged Session plus a game-specific reply.

#### Scenario: Session state is requested
- **WHEN** `D20.Sessions.get/1` resolves a running default Session server
- **THEN** it returns the current live session and game id through the existing public API

#### Scenario: State-changing command is accepted
- **WHEN** the engine accepts a dispatched command with an updated game
- **THEN** the default Session server stores the updated session
- **AND** replies with and publishes the same authoritative session
- **AND** derives its next state name from the shared session lifecycle phase

#### Scenario: Idempotent command is accepted
- **WHEN** the engine accepts a dispatched command with the exact unchanged game and no reply
- **THEN** the default Session server returns the unchanged authoritative session
- **AND** it does not store a replacement or publish a session projection

#### Scenario: Request-scoped calculation is accepted
- **WHEN** the engine accepts a dispatched command with the exact unchanged game plus a game-specific reply
- **THEN** the default Session server returns the exact unchanged session plus that reply through dispatch
- **AND** it does not store a replacement, publish a session projection, or retain the reply

#### Scenario: Command is rejected
- **WHEN** the engine rejects a dispatched command
- **THEN** the default Session server preserves its current state name and session data
- **AND** returns the engine error without publishing a new session

#### Scenario: Actor attaches
- **WHEN** the default Session server receives an authenticated attach call from `D20.Sessions`
- **THEN** its process idempotently registers `actor_id -> session_id` in `D20.Sessions.Registry`
- **AND** a new relationship invalidates that actor's Workspace
- **AND** no game command or Session projection change occurs solely for attachment

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
- **WHEN** Session membership accepts an `online` actor and the game engine rejects the internal `join`
- **THEN** the default Session server stores and publishes the online membership update
- **AND** preserves game player state
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
- **THEN** it inherits attach, detach, Presence, publication, and idle behavior

### Requirement: Public session APIs remain runtime-implementation agnostic
The system SHALL expose runtime-agnostic `D20.Sessions` create, list, get, attach, detach, dispatch, lookup, and stop contracts without exposing raw `:gen_statem` or Registry operations. `dispatch` SHALL be the sole public command boundary for state-changing and request-scoped game events. The Session-server behaviour SHALL NOT duplicate attachment and detachment as caller-facing callbacks and SHALL NOT expose a separate preview callback or client function.

#### Scenario: SessionChannel attaches through shared API
- **WHEN** SessionChannel calls `D20.Sessions.attach/1` with authenticated scope
- **THEN** the configured default or custom server owns the Registry mutation

#### Scenario: Workspace detaches through shared API
- **WHEN** Workspace calls `D20.Sessions.detach/2` with authenticated scope and Session id
- **THEN** the configured default or custom server owns the Registry mutation
- **AND** missing runtime and absent relationship can be treated idempotently by the web workflow

#### Scenario: Server contract is inspected
- **WHEN** a default or custom Session server implements the shared runtime behaviour
- **THEN** `attach/2`, `detach/2`, and `preview/2` are not behaviour callbacks or generated client delegates
- **AND** attachment calls enter through `D20.Sessions`
- **AND** every game event enters through dispatch

#### Scenario: Caller uses shared session API
- **WHEN** a caller creates or interacts with either a default or custom game session
- **THEN** `D20.Sessions` resolves and calls the registered game-server implementation
- **AND** returns the same dispatch success and error shapes regardless of the concrete server module

#### Scenario: Caller dispatches a state-changing command
- **WHEN** a caller dispatches an accepted state-changing command through `D20.Sessions.dispatch/3`
- **THEN** the result contains the authoritative Session

#### Scenario: Caller dispatches a request-scoped calculation
- **WHEN** a caller dispatches an accepted non-mutating calculation through `D20.Sessions.dispatch/3`
- **THEN** the result contains the exact unchanged Session plus a game-specific reply
- **AND** no separate public preview operation is required

#### Scenario: Caller stops a session
- **WHEN** a caller stops a running game session through `D20.Sessions.stop/3`
- **THEN** the system stops the registered `:gen_statem` process with the requested reason and timeout
- **AND** treating an already stopped process remains idempotent

#### Scenario: Caller uses existing Session APIs
- **WHEN** a caller gets, dispatches, or stops a Session
- **THEN** existing success and error shapes remain independent of the concrete server module

### Requirement: Game engines remain independent from OTP runtime callbacks
The system SHALL keep `D20.Game` engines and `D20.Sessions.Session` focused on pure initialization, validation, command reduction, request-scoped calculation, and completion checks while server modules own OTP lifecycle and timer behavior. A game dispatch SHALL return either `{:ok, game}`, `{:ok, unchanged_game, reply}`, or `{:error, reason}` and SHALL introduce no additional result status atoms.

#### Scenario: Default engine processes a state-changing command
- **WHEN** the default game server dispatches a state-changing command to an engine
- **THEN** the engine receives the current game state and command without receiving process state, timer references, or OTP callback data
- **AND** returns the accepted authoritative game value

#### Scenario: Default engine processes a request-scoped calculation
- **WHEN** the default game server dispatches a non-mutating game event to an engine
- **THEN** the engine validates it through the same command and rules boundary
- **AND** returns the exact source game plus a game-specific reply
- **AND** no game or session preview callback exists

#### Scenario: Custom server needs state-machine behavior
- **WHEN** a game requires phase-specific timers or runtime events
- **THEN** its custom game-server module overrides the required standard `:gen_statem` callbacks
- **AND** it delegates unmatched events to the generated default implementation with `super`
- **AND** neither the default server nor the server macro exposes game-specific extension hooks
- **AND** the game engine remains usable as a pure reducer outside a running process
