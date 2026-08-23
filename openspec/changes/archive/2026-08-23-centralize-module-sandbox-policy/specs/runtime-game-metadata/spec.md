## MODIFIED Requirements

### Requirement: Provider-derived metadata is not stable configuration
The system SHALL NOT require title, preview URL, description, player counts, or other BGG-derived fields in the stable game registry.

#### Scenario: Registry has only stable fields
- **WHEN** a playable game registry entry includes its `engine`, `bgg_id`, and availability `status`
- **THEN** the entry is sufficient for playable game declaration without iframe sandbox policy
- **AND** display metadata is resolved separately at runtime
