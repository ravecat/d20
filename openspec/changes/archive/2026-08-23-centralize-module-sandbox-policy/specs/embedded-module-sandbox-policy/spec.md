## ADDED Requirements

### Requirement: Web module configuration owns iframe sandbox policy
The system SHALL define one non-empty list of string iframe sandbox capabilities in application configuration owned by `D20Web.Module`. The game registry SHALL NOT define or override this policy per slug.

#### Scenario: Shared policy is configured
- **WHEN** the application loads module framing configuration
- **THEN** `D20Web.Module` has one non-empty sandbox capability list
- **AND** the configured values are `allow-scripts` and `allow-same-origin`

#### Scenario: Invalid policy is used
- **WHEN** module descriptor generation encounters missing, empty, non-list, or non-string sandbox configuration
- **THEN** the system raises an explicit configuration error
- **AND** it does not emit a malformed module descriptor

### Requirement: Module descriptors project the configured sandbox policy
The system SHALL include the configured `D20Web.Module` sandbox list unchanged in every registered game's module descriptor while preserving registry lookup as the prerequisite for descriptor generation.

#### Scenario: Registered module descriptor is generated
- **WHEN** the shell builds a module descriptor for a registered game
- **THEN** the descriptor's `sandbox` value equals the configured `D20Web.Module` sandbox list
- **AND** the descriptor retains its existing embed URL and allowed-origin fields

#### Scenario: Different registered games are framed
- **WHEN** the shell builds descriptors for different registered game slugs
- **THEN** every descriptor receives the same configured sandbox policy
- **AND** no registry entry supplies a sandbox override

#### Scenario: Unknown game is requested
- **WHEN** a production descriptor path receives an unregistered game slug
- **THEN** the existing registry lookup rejects the game
- **AND** the shared sandbox policy does not make that game launchable or frameable
