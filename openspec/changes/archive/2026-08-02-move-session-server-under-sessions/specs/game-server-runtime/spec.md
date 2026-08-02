## MODIFIED Requirements

### Requirement: All live game sessions use the game-server contract
The system SHALL run every live game session through a module that implements the `D20.Sessions.Server` contract and SHALL use `:gen_statem` as the sole OTP primitive for that runtime contract.

#### Scenario: Default game session starts
- **WHEN** the system creates a session for an engine without a custom server
- **THEN** it starts `D20.Sessions.Server` as a temporary registered `:gen_statem` process
- **AND** that process is the sole owner of the live session state

#### Scenario: Custom game session starts
- **WHEN** the system creates a session for an engine with a custom server
- **THEN** it starts the configured custom `:gen_statem` process through the same game-server contract
- **AND** it does not start an additional default session process

#### Scenario: Unsupported GenServer adapter is requested
- **WHEN** a game server attempts to select the removed `:gen_server` adapter
- **THEN** macro expansion fails because `D20.Sessions.Server` accepts no configuration options

### Requirement: Engines use the default game server unless explicitly configured
The system SHALL generate a `server/0` callback that selects the default `:gen_statem` Session-server implementation unless an engine explicitly configures a custom server.

#### Scenario: Engine omits server option
- **WHEN** an engine calls `use D20.Game` without a `:server` option
- **THEN** the macro generates `server/0` returning `D20.Sessions.Server`
- **AND** `D20.Game.server/1` returns `D20.Sessions.Server`

#### Scenario: Engine configures custom server
- **WHEN** an engine explicitly implements `server/0`
- **THEN** `D20.Game.server/1` returns that custom server

#### Scenario: Game macro is used without server option
- **WHEN** a game module calls `use D20.Game` without a `:server` option
- **THEN** the game satisfies the required server callback with the default implementation

### Requirement: Default game server preserves shared session lifecycle behavior
The default Session server SHALL preserve state access, command dispatch, Presence membership and admission, actor attachment and detachment, publication, idle expiration, registration, supervision, and temporary restart semantics. Attachment mutations SHALL be serialized by the Session process and SHALL remain distinct from game-engine commands.

#### Scenario: Session state is requested
- **WHEN** `D20.Sessions.get/1` resolves a running default Session server
- **THEN** it returns the current live session and slug through the existing public API

#### Scenario: Command is accepted
- **WHEN** the engine accepts a dispatched command
- **THEN** the default Session server stores the updated session
- **AND** replies with and publishes the same authoritative session
- **AND** derives its next state name from the shared session lifecycle phase

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
The system SHALL expose runtime-agnostic `D20.Sessions` create, list, get, attach, detach, dispatch, preview, lookup, and stop contracts without exposing raw `:gen_statem` or Registry operations. The Session-server behaviour SHALL NOT duplicate attachment and detachment as caller-facing callbacks.

#### Scenario: SessionChannel attaches through shared API
- **WHEN** SessionChannel calls `D20.Sessions.attach/1` with authenticated scope
- **THEN** the configured default or custom server owns the Registry mutation

#### Scenario: Workspace detaches through shared API
- **WHEN** Workspace calls `D20.Sessions.detach/2` with authenticated scope and Session id
- **THEN** the configured default or custom server owns the Registry mutation
- **AND** missing runtime and absent relationship can be treated idempotently by the web workflow

#### Scenario: Server contract is inspected
- **WHEN** a default or custom Session server implements the shared runtime behaviour
- **THEN** `attach/2` and `detach/2` are not behaviour callbacks or generated client delegates
- **AND** attachment calls enter through `D20.Sessions`

#### Scenario: Caller uses shared session API
- **WHEN** a caller creates or interacts with either a default or custom game session
- **THEN** `D20.Sessions` resolves and calls the registered game-server implementation
- **AND** returns the same success and error shapes regardless of the concrete server module

#### Scenario: Caller stops a session
- **WHEN** a caller stops a running game session through `D20.Sessions.stop/3`
- **THEN** the system stops the registered `:gen_statem` process with the requested reason and timeout
- **AND** treating an already stopped process remains idempotent

#### Scenario: Caller uses existing Session APIs
- **WHEN** a caller gets, dispatches, previews, or stops a Session
- **THEN** existing success and error shapes remain independent of the concrete server module
