## MODIFIED Requirements

### Requirement: Koala state-machine sessions preserve shared lifecycle behavior

The system SHALL preserve session lookup, Presence membership and admission, publication, roll scheduling, and idle-expiration behavior when Koala uses `:gen_statem`.

#### Scenario: Session state is requested

- **WHEN** `D20.Sessions.get/1` resolves a running Koala server
- **THEN** the server returns the current live session and its slug through the shared server API

#### Scenario: Presence online admits a Koala player

- **WHEN** a Koala server receives a Presence `online` event during setup
- **THEN** it applies online Session membership and internal game `join` admission
- **AND** stores and publishes the final Session once
- **AND** transitions to the resulting game phase without disturbing unrelated timers

#### Scenario: Presence admission is rejected

- **WHEN** the Koala engine rejects a Presence-driven internal `join`
- **THEN** the server retains and publishes online Session membership
- **AND** preserves Koala player state and the active roll-state timeout

#### Scenario: Presence offline changes status only

- **WHEN** the actor's final Presence meta leaves
- **THEN** the Koala server marks the member offline
- **AND** sends no game `left` command
- **AND** preserves Koala player state and the active roll-state timeout

#### Scenario: Session remains idle

- **WHEN** the Koala server receives no supported activity for the configured idle timeout
- **THEN** it stops normally

#### Scenario: Session receives activity

- **WHEN** the Koala server handles a supported call, Presence event, or automatic transition
- **THEN** it resets the independent idle timeout without changing the roll-state timeout
