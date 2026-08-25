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
The system SHALL include the configured sandbox list unchanged in every persisted game's module descriptor. Descriptor builders SHALL consume the local game id already resolved by the persisted game or Session boundary without duplicating caller-owned id validation.

#### Scenario: Persisted module descriptor is generated
- **WHEN** the shell builds a descriptor for an existing local game id
- **THEN** `sandbox` equals the configured list
- **AND** embed URL and allowed-origin fields use the same DNS-safe `game-<typeid-suffix>` module host

#### Scenario: Different games are framed
- **WHEN** the shell builds descriptors for different local game ids
- **THEN** every descriptor receives the same sandbox policy
- **AND** no game row supplies an override

#### Scenario: Unknown game is requested
- **WHEN** a production descriptor path receives an unknown local game id
- **THEN** persisted game lookup rejects it
- **AND** shared sandbox policy does not make it launchable or frameable
