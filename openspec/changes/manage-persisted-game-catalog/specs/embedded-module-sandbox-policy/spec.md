## MODIFIED Requirements

### Requirement: Web module configuration owns iframe sandbox policy
The system SHALL define one non-empty list of string iframe sandbox capabilities in application configuration owned by `D20Web.Module`. Persisted game records SHALL NOT define or override this policy.

#### Scenario: Shared policy is configured
- **WHEN** the application loads module framing configuration
- **THEN** `D20Web.Module` has one non-empty sandbox capability list
- **AND** values are `allow-scripts` and `allow-same-origin`

#### Scenario: Invalid policy is used
- **WHEN** descriptor generation encounters missing, empty, non-list, or non-string sandbox configuration
- **THEN** the system raises an explicit configuration error
- **AND** emits no malformed descriptor

### Requirement: Module descriptors project the configured sandbox policy
The system SHALL include the configured sandbox list unchanged in every persisted game's module descriptor. Descriptor builders SHALL consume a persisted game resolved by public slug or captured local TypeID and SHALL use that row's immutable slug for module origin without duplicating caller-owned identity validation.

#### Scenario: Persisted module descriptor is generated
- **WHEN** the shell builds a descriptor for persisted game slug `qwinto`
- **THEN** `sandbox` equals the configured list
- **AND** embed URL and allowed-origin fields use `qwinto.<shell-host>`

#### Scenario: Different games are framed
- **WHEN** the shell builds descriptors for different persisted games
- **THEN** every descriptor receives the same sandbox policy
- **AND** each descriptor receives the host derived from its own persisted slug
- **AND** no game row supplies a sandbox override

#### Scenario: Unknown game is requested
- **WHEN** a production descriptor path receives an unknown slug or local game id
- **THEN** persisted game lookup rejects it
- **AND** shared sandbox policy does not make it launchable or frameable
