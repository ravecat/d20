## MODIFIED Requirements

### Requirement: Koala sessions use a phase-aligned state machine
The system SHALL run each Koala Rescue Club Session with `:gen_statem` while preserving the shared game-server API and stable local game association used by `D20.Sessions`.

#### Scenario: Koala Session starts
- **WHEN** the system creates a Koala Rescue Club Session
- **THEN** it starts a temporary registered `:gen_statem` process
- **AND** the process state name reflects the current Koala phase
- **AND** process data retains local game id, captured engine, and live Session

#### Scenario: Accepted command changes phase
- **WHEN** the Koala engine accepts a command that changes phase
- **THEN** the server transitions to the corresponding state name
- **AND** stores the updated live Session as state data
- **AND** replies with and publishes the same authoritative Session

#### Scenario: Rejected command preserves state
- **WHEN** the Koala engine rejects a command
- **THEN** the server keeps its current state name and state data
- **AND** returns the engine error without publishing a new Session

### Requirement: Koala state-machine sessions preserve shared lifecycle behavior
The system SHALL preserve Session lookup, local game association, Presence membership and admission, publication, roll scheduling, and idle expiration when Koala uses `:gen_statem`.

#### Scenario: Session state is requested
- **WHEN** `D20.Sessions.get/1` resolves a running Koala server
- **THEN** the server returns the current live Session and local game id through the shared server API

#### Scenario: Presence online admits a Koala player
- **WHEN** a Koala server receives Presence online during setup
- **THEN** it applies online Session membership and internal game `join`
- **AND** stores and publishes the final Session once
- **AND** transitions to the resulting phase without disturbing unrelated timers

#### Scenario: Presence admission is rejected
- **WHEN** the Koala engine rejects a Presence-driven internal join
- **THEN** the server retains and publishes online Session membership
- **AND** preserves Koala player state and the active roll timeout

#### Scenario: Presence offline changes status only
- **WHEN** the actor's final Presence meta leaves
- **THEN** the Koala server marks the member offline
- **AND** sends no game `left` command
- **AND** preserves Koala player state and the active roll timeout

#### Scenario: Session remains idle
- **WHEN** the Koala server receives no supported activity for the configured idle timeout
- **THEN** it stops normally

#### Scenario: Session receives activity
- **WHEN** the Koala server handles a supported call, Presence event, or automatic transition
- **THEN** it resets the independent idle timeout without changing the roll timeout
