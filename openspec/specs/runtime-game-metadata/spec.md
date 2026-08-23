# runtime-game-metadata Specification

## Purpose
Define how registered games obtain presentation metadata from BGG at runtime and propagate provider failures.

## Requirements
### Requirement: Runtime metadata is resolved from BGG
The system SHALL resolve display metadata for registered games at runtime using each game's configured `bgg_id`.

#### Scenario: Metadata is resolved for a registered game
- **WHEN** runtime metadata is requested for a registered game with `bgg_id` `183006`
- **THEN** the system requests BGG game details for id `183006`
- **AND** the system returns display metadata derived from the BGG response

#### Scenario: Metadata lookup does not search by title
- **WHEN** runtime metadata is requested for a registered game
- **THEN** the system uses the configured BGG id directly
- **AND** the system does not depend on a provider title search to identify the game

### Requirement: Runtime metadata provides display fields
The system SHALL expose runtime display metadata fields for game presentation when those fields are available from BGG.

#### Scenario: Title is available
- **WHEN** BGG returns a primary name for a registered game
- **THEN** the runtime metadata includes that name as the game title

#### Scenario: Title is not synthesized from internal slug
- **WHEN** BGG does not return a primary name for a registered game
- **THEN** the runtime metadata does not synthesize a title from the registry slug

#### Scenario: Preview image is available
- **WHEN** BGG returns a thumbnail or image URL for a registered game
- **THEN** the runtime metadata includes an image URL suitable for a game preview

#### Scenario: Categories and mechanics are available
- **WHEN** BGG returns category and mechanic links for a registered game
- **THEN** the runtime metadata includes a `categories` array derived from `boardgamecategory` links
- **AND** the runtime metadata includes a `mechanics` array derived from `boardgamemechanic` links

#### Scenario: Internal slug is not runtime metadata
- **WHEN** runtime metadata is returned for a registered game
- **THEN** the metadata does not include the internal registry slug

### Requirement: Metadata failure is returned
The system SHALL return metadata source errors when runtime metadata cannot be resolved from BGG.

#### Scenario: BGG request fails
- **WHEN** BGG metadata resolution fails for a registered game
- **THEN** game metadata lookup returns the BGG source error
- **AND** the system does not synthesize display metadata from registry configuration

#### Scenario: BGG returns no matching item
- **WHEN** BGG returns no game details for a configured `bgg_id`
- **THEN** game metadata lookup returns a not-found metadata error
- **AND** the system does not synthesize display metadata from registry configuration

### Requirement: Provider-derived metadata is not stable configuration
The system SHALL NOT require title, preview URL, description, player counts, or other BGG-derived fields in the stable game registry.

#### Scenario: Registry has only stable fields
- **WHEN** a playable game registry entry includes its `engine`, `bgg_id`, and availability `status`
- **THEN** the entry is sufficient for playable game declaration without iframe sandbox policy
- **AND** display metadata is resolved separately at runtime
