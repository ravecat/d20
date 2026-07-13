## ADDED Requirements

### Requirement: All live game sessions use the game-server contract
The system SHALL run every live game session through a module that implements the `D20.Game.Server` contract and SHALL use `:gen_statem` as the sole OTP primitive for that runtime contract.

#### Scenario: Default game session starts
- **WHEN** the system creates a session for an engine without a custom server
- **THEN** it starts `D20.Game.Server` as a temporary registered `:gen_statem` process
- **AND** that process is the sole owner of the live session state

#### Scenario: Custom game session starts
- **WHEN** the system creates a session for an engine with a custom server
- **THEN** it starts the configured custom `:gen_statem` process through the same game-server contract
- **AND** it does not start an additional default session process

#### Scenario: Unsupported GenServer adapter is requested
- **WHEN** a game server attempts to select the removed `:gen_server` adapter
- **THEN** macro expansion fails because `D20.Game.Server` accepts no configuration options

### Requirement: Engines use the default game server unless explicitly configured
The system SHALL generate a `server/0` callback that selects the default `:gen_statem` game-server implementation unless an engine explicitly configures a custom server.

#### Scenario: Engine omits server option
- **WHEN** an engine calls `use D20.Game` without a `:server` option
- **THEN** the macro generates `server/0` returning `D20.Game.Server`
- **AND** `D20.Game.server/1` returns `D20.Game.Server`

#### Scenario: Engine configures custom server
- **WHEN** an engine explicitly implements `server/0`
- **THEN** `D20.Game.server/1` returns that custom server

#### Scenario: Game macro is used without server option
- **WHEN** a game module calls `use D20.Game` without a `:server` option
- **THEN** the game satisfies the required server callback with the default implementation

### Requirement: Default game server preserves shared session lifecycle behavior
The default game server SHALL preserve the existing session state access, command dispatch, Presence membership, state publication, idle expiration, registration, supervision, and temporary restart semantics.

#### Scenario: Session state is requested
- **WHEN** `D20.Sessions.get/1` resolves a running default game server
- **THEN** it returns the current live session and slug through the existing public API

#### Scenario: Command is accepted
- **WHEN** the engine accepts a dispatched command
- **THEN** the default game server stores the updated session
- **AND** replies with and publishes the same authoritative session
- **AND** derives its next state name from the shared session lifecycle phase

#### Scenario: Command is rejected
- **WHEN** the engine rejects a dispatched command
- **THEN** the default game server preserves its current state name and session data
- **AND** returns the engine error without publishing a new session

#### Scenario: Presence membership changes
- **WHEN** the default game server receives a Presence join or leave notification
- **THEN** it preserves the existing profile enrichment and membership dispatch behavior
- **AND** stores and publishes an accepted update
- **AND** preserves state without publication when the engine rejects the update

#### Scenario: Session remains idle
- **WHEN** the default game server receives no supported activity for the configured idle timeout
- **THEN** it stops normally and is not restarted

#### Scenario: Custom server inherits the default lifecycle
- **WHEN** a custom server uses `D20.Game.Server` without overriding `init/1` or `handle_event/4`
- **THEN** it inherits Presence subscription, membership dispatch, publication, and idle expiration
- **AND** it does not need game-specific extension hooks

### Requirement: Public session APIs remain runtime-implementation agnostic
The system SHALL preserve the public `D20.Sessions` create, get, dispatch, lookup, and stop contracts without exposing GenServer-specific details.

#### Scenario: Caller uses shared session API
- **WHEN** a caller creates or interacts with either a default or custom game session
- **THEN** `D20.Sessions` resolves and calls the registered game-server implementation
- **AND** returns the same success and error shapes regardless of the concrete server module

#### Scenario: Caller stops a session
- **WHEN** a caller stops a running game session through `D20.Sessions.stop/3`
- **THEN** the system stops the registered `:gen_statem` process with the requested reason and timeout
- **AND** treating an already stopped process remains idempotent

### Requirement: Game engines remain independent from OTP runtime callbacks
The system SHALL keep `D20.Game` engines and `D20.Sessions.Session` focused on pure initialization, validation, command reduction, and completion checks while server modules own OTP lifecycle and timer behavior.

#### Scenario: Default engine processes a command
- **WHEN** the default game server dispatches a command to an engine
- **THEN** the engine receives the current game state and command without receiving process state, timer references, or OTP callback data

#### Scenario: Custom server needs state-machine behavior
- **WHEN** a game requires phase-specific timers or runtime events
- **THEN** its custom game-server module overrides the required standard `:gen_statem` callbacks
- **AND** it delegates unmatched events to the generated default implementation with `super`
- **AND** neither the default server nor the server macro exposes game-specific extension hooks
- **AND** the game engine remains usable as a pure reducer outside a running process
