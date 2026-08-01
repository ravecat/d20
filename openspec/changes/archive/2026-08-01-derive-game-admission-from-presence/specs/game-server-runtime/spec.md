## MODIFIED Requirements

### Requirement: Default game server preserves shared session lifecycle behavior

The default game server SHALL preserve session state access, command dispatch, Presence membership and admission, state publication, idle expiration, registration, supervision, and temporary restart semantics.

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

#### Scenario: Presence online admits a player

- **WHEN** the default game server receives a normalized Presence `online` message
- **THEN** it applies Session membership and the internal game `join` command in one serialized transition
- **AND** stores and publishes the final accepted Session state once

#### Scenario: Presence game admission is rejected

- **WHEN** Session membership accepts an `online` actor and the game engine rejects the internal `join`
- **THEN** the default game server stores and publishes the online membership update
- **AND** preserves game player state
- **AND** does not expose the engine rejection as a transport failure

#### Scenario: Presence offline changes status

- **WHEN** the default game server receives a normalized Presence `offline` message
- **THEN** it marks an existing member offline
- **AND** it sends no `left` command to the game engine

#### Scenario: Session remains idle

- **WHEN** the default game server receives no supported activity for the configured idle timeout
- **THEN** it stops normally and is not restarted

#### Scenario: Custom server inherits the default lifecycle

- **WHEN** a custom server uses `D20.Game.Server` without overriding Presence handling
- **THEN** it inherits Presence subscription, automatic game admission, status-only offline handling, publication, and idle expiration
- **AND** it does not need game-specific extension hooks
