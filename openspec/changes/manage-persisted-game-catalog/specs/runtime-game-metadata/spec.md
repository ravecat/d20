## MODIFIED Requirements

### Requirement: Runtime metadata is resolved from BGG
The system SHALL resolve display metadata for a persisted game at runtime using that row's current `bgg_id`.

#### Scenario: Metadata is resolved for a persisted game
- **WHEN** runtime metadata is requested for Qwinto's persisted `game` TypeID whose `bgg_id` is `183006`
- **THEN** the system requests BGG game details for id `183006`
- **AND** returns display metadata derived from the response beside the unchanged TypeID

#### Scenario: Metadata lookup does not search by title or slug
- **WHEN** runtime metadata is requested for a persisted game
- **THEN** the system uses the stored BGG id directly
- **AND** does not use a title or slug to identify the game

### Requirement: Runtime metadata provides display fields
The system SHALL expose runtime display metadata fields without deriving a public game slug.

#### Scenario: Title is available
- **WHEN** BGG returns primary name `Next Station: London`
- **THEN** runtime metadata includes that title
- **AND** public navigation remains based only on local game id

#### Scenario: Title is unavailable
- **WHEN** BGG does not return a usable primary name
- **THEN** runtime metadata has no title
- **AND** no title or public slug is synthesized from local id or engine

#### Scenario: Preview image is available
- **WHEN** BGG returns a thumbnail or image URL
- **THEN** runtime metadata includes an image URL suitable for a preview

#### Scenario: Categories and mechanics are available
- **WHEN** BGG returns category and mechanic links
- **THEN** runtime metadata includes categories from `boardgamecategory` links
- **AND** mechanics from `boardgamemechanic` links

### Requirement: Provider-derived metadata is not stable configuration
The system SHALL NOT require or persist title, public slug, preview URL, description, player counts, or other BGG-derived fields in the stable game record.

#### Scenario: Persisted row has only operational fields
- **WHEN** a game row includes local id, engine, BGG id, implementation stage, and enabled
- **THEN** it is sufficient for D20 catalog and runtime binding
- **AND** display metadata is resolved separately at runtime
- **AND** the row contains no iframe sandbox or presentation fields
