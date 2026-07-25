## ADDED Requirements

### Requirement: Koala sessions use a phase-aligned state machine
The system SHALL run each Koala Rescue Club session process with `:gen_statem` while preserving the shared game-server API used by `D20.Sessions`.

#### Scenario: Koala session starts
- **WHEN** the system creates a Koala Rescue Club session
- **THEN** it starts a temporary registered `:gen_statem` process
- **AND** the process state name reflects the current Koala game phase
- **AND** the process state data retains the session slug, engine, and live session

#### Scenario: Accepted command changes phase
- **WHEN** the Koala engine accepts a command that changes the game phase
- **THEN** the server transitions to the corresponding state name
- **AND** stores the updated live session as its state data
- **AND** replies with and publishes the same authoritative session

#### Scenario: Rejected command preserves state
- **WHEN** the Koala engine rejects a command
- **THEN** the server keeps its current state name and state data
- **AND** returns the engine error without publishing a new session


### Requirement: Automatic rolls use a roll-state timeout
The system SHALL schedule the authoritative Koala roll with a `state_timeout` that belongs to the roll state and SHALL NOT require a timer correlation token in server state.

#### Scenario: Server enters the roll state
- **WHEN** an accepted transition enters the Koala roll phase with no current roll
- **THEN** the server records a projected `roll_due_at`
- **AND** schedules exactly one roll-state timeout
- **AND** publishes the session containing that deadline

#### Scenario: Roll-state timeout expires
- **WHEN** the roll-state timeout expires while the server remains in the roll state
- **THEN** the server dispatches one authoritative roll for a joined player
- **AND** transitions to the phase returned by the game engine
- **AND** publishes the resulting session with no pending roll deadline

#### Scenario: Server leaves the roll state before timeout
- **WHEN** the server transitions out of the roll state before its timeout expires
- **THEN** the roll-state timeout is cancelled by the state transition
- **AND** no stale automatic roll is applied later

#### Scenario: Roll state receives unrelated activity
- **WHEN** the server handles a read, Presence event, or accepted command that keeps the same roll state
- **THEN** it does not create a duplicate automatic roll timeout
- **AND** the existing roll deadline remains authoritative

#### Scenario: Client requests a roll through the session channel
- **WHEN** a client sends the `roll` event through a Koala session channel
- **THEN** the channel rejects it with `:automatic_roll` without dispatching it to the session server
- **AND** the server-owned roll-state timeout remains responsible for rolling

#### Scenario: Later turn enters the roll state
- **WHEN** all required submissions advance the game into a later roll phase
- **THEN** the server schedules a new roll-state timeout for that turn
- **AND** exposes a new `roll_due_at`


### Requirement: Koala state-machine sessions preserve shared lifecycle behavior
The system SHALL preserve the existing session lookup, Presence membership, publication, and idle-expiration behavior when Koala uses `:gen_statem`.

#### Scenario: Session state is requested
- **WHEN** `D20.Sessions.get/1` resolves a running Koala server
- **THEN** the server returns the current live session and its slug through the shared server API

#### Scenario: Presence membership event succeeds
- **WHEN** a Koala server receives an accepted Presence `join` or `left` event
- **THEN** it stores and publishes the updated session
- **AND** preserves any active roll-state timeout when the game phase does not change

#### Scenario: Presence membership event is rejected
- **WHEN** the Koala engine rejects a Presence `join` or `left` event
- **THEN** the server preserves its current state and publishes no update

#### Scenario: Session remains idle
- **WHEN** the Koala server receives no supported activity for the configured idle timeout
- **THEN** it stops normally

#### Scenario: Session receives activity
- **WHEN** the Koala server handles a supported call, Presence event, or automatic transition
- **THEN** it resets the independent idle timeout without changing the roll-state timeout
