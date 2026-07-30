# koala-rescue-club-map-data Specification

## Purpose
TBD - created by archiving change implement-koala-rescue-club-rules. Update Purpose after archive.
## Requirements
### Requirement: Rule source and map selection are explicit
The system SHALL derive Koala Rescue Club rules from the selected map structure encoded from the local Koala Rescue Club rule assets. Shared rules SHALL apply to every supported map unless the selected map structure defines a map-specific override.

#### Scenario: Local rule assets are the source material
- **WHEN** Koala Rescue Club map data is encoded or reviewed
- **THEN** the implementation uses the local rule assets under `assets/public/rules/koala_rescue_club`
- **AND** the implementation does not use BoardGameGeek metadata, catalog metadata, route slugs, or display text as a rules source

#### Scenario: Shared rules apply across maps
- **WHEN** a rule is not map-specific
- **THEN** the system follows the shared Koala Rescue Club ruleset for player count, 30 turns, 2 rounds, die values, die shapes, volunteer adjustment, badge award policy, and tie breakers

#### Scenario: Selected map overrides shared defaults
- **WHEN** the selected map defines map-specific structure
- **THEN** the system uses that selected map structure for initial volunteers, hospital scoring, solo rating bands, sheet geometry, row and column bonuses, skybridges, and badge predicates

### Requirement: Supported maps expose stable rule structures
The system SHALL expose supported Koala Rescue Club maps as stable, machine-readable rule structures.

#### Scenario: Dharug structure is available
- **WHEN** Koala Rescue Club map `dharug` is requested
- **THEN** the system returns a map structure with slug `dharug`
- **AND** the structure grants 1 initial volunteer
- **AND** the structure uses completed-only hospital scoring
- **AND** the structure includes Dharug solo rating bands

#### Scenario: Yugambeh structure is available
- **WHEN** Koala Rescue Club map `yugambeh` is requested
- **THEN** the system returns a map structure with slug `yugambeh`
- **AND** the structure grants 0 initial volunteers
- **AND** the structure scores started incomplete hospitals with negative points
- **AND** the structure includes Yugambeh solo rating bands

#### Scenario: Unknown map is rejected
- **WHEN** a caller requests an unsupported Koala Rescue Club map
- **THEN** the system rejects the request with an unknown-map result

### Requirement: Sheet geometry is encoded before placement validation
The system SHALL encode Koala Rescue Club sheet geometry as data before any placement-dependent rule is treated as implemented.

#### Scenario: Geometry includes placement cells
- **WHEN** a supported map structure is loaded
- **THEN** the structure includes tree cells with stable ids
- **AND** each tree cell belongs to exactly one area
- **AND** each tree cell indicates whether it contains a printed koala

#### Scenario: Geometry includes accessibility graph
- **WHEN** a supported map structure is loaded
- **THEN** the structure marks the initial accessible area
- **AND** the structure includes skybridge edges that connect areas

#### Scenario: Geometry includes scoring and bonus structures
- **WHEN** a supported map structure is loaded
- **THEN** the structure includes row and column groups
- **AND** each row or column bonus is bound to one group
- **AND** hospitals include size, positive score, and any map-specific negative score

### Requirement: Die shapes are reviewable data
The system SHALL expose the canonical Koala Rescue Club die shapes and allowed transforms as reviewable ruleset data.

#### Scenario: Die shape is fetched
- **WHEN** the shape for a die value from 1 through 6 is requested
- **THEN** the system returns the canonical set of offsets for that die value

#### Scenario: Invalid die shape is rejected
- **WHEN** the shape for a value outside 1 through 6 is requested
- **THEN** the system rejects the request with an invalid-die-value result

#### Scenario: Shape transforms are available
- **WHEN** placement validation evaluates a die shape
- **THEN** the system allows rotations and flips of the canonical offsets

### Requirement: Badges are data-backed
The system SHALL define each Koala Rescue Club badge as map data with a stable id, point values, and a machine-readable completion predicate.

#### Scenario: Badge data is loaded
- **WHEN** a supported map structure is loaded
- **THEN** each badge includes a stable id
- **AND** each badge includes large and small point values
- **AND** each badge includes a predicate that can be evaluated from player sheet state

#### Scenario: Unencoded badge is not awarded
- **WHEN** a badge has no machine-readable predicate
- **THEN** the system does not award that badge
- **AND** the implementation records the missing predicate as incomplete map data rather than guessing the requirement
