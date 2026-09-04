## MODIFIED Requirements

### Requirement: Runtime metadata is resolved from BGG
The system SHALL resolve display metadata for a persisted game at runtime using that row's current `bgg_id`. It SHALL identify the local row by its persisted TypeID or slug before provider access and SHALL NOT ask BGG to resolve application identity.

#### Scenario: Metadata is resolved for a persisted game
- **WHEN** runtime metadata is requested for Qwinto whose persisted `bgg_id` is `183006`
- **THEN** the system requests BGG game details for id `183006`
- **AND** returns display metadata beside unchanged local TypeID and slug

#### Scenario: Metadata lookup does not search by title or slug
- **WHEN** runtime metadata is requested for a persisted game
- **THEN** the system uses stored BGG id directly for provider lookup
- **AND** does not use title or local slug to search BGG

### Requirement: Runtime metadata provides display fields
The system SHALL expose runtime display metadata fields without deriving, replacing, or owning the persisted game slug.

#### Scenario: Title is available
- **WHEN** BGG returns primary name `Next Station: London`
- **THEN** runtime metadata includes that title
- **AND** public navigation continues using persisted slug `next-station-london`

#### Scenario: Title is unavailable
- **WHEN** BGG does not return a usable primary name
- **THEN** runtime metadata has no title
- **AND** no title is synthesized from slug, TypeID, or engine

#### Scenario: Preview image is available
- **WHEN** BGG returns a thumbnail or image URL
- **THEN** runtime metadata includes an image URL suitable for a preview

#### Scenario: Categories and mechanics are available
- **WHEN** BGG returns category and mechanic links
- **THEN** runtime metadata includes categories from `boardgamecategory` links
- **AND** mechanics from `boardgamemechanic` links

#### Scenario: Persisted slug is not runtime metadata
- **WHEN** runtime metadata is returned for a persisted game
- **THEN** the metadata object does not duplicate the slug
- **AND** catalog or detail data carries slug from the persisted row separately

### Requirement: Provider-derived metadata is not stable configuration
The system SHALL NOT require or persist title, preview URL, description, player counts, or other BGG-derived fields in the stable game record. Persisted slug SHALL remain a local operator-assigned identity and SHALL NOT be classified as provider-derived metadata.

#### Scenario: Persisted row has only local identities and operational fields
- **WHEN** a game row includes TypeID, slug, engine, BGG id, stage, and enabled
- **THEN** it is sufficient for D20 catalog and runtime binding
- **AND** display metadata is resolved separately at runtime
- **AND** the row contains no iframe sandbox or provider presentation fields
