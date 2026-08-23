## MODIFIED Requirements

### Requirement: Implemented games are declared in a game registry
The system SHALL declare configured games in a game registry keyed by internal game slug. Each game registry entry SHALL contain stable game identity and runtime bindings only: `bgg_id`, optional `engine`, and optional `status`. A game registry entry SHALL NOT contain iframe sandbox policy.

#### Scenario: Registry entry declares a playable game
- **WHEN** the application loads a playable registry entry keyed by `qwinto`
- **THEN** the entry exposes `qwinto` as the internal game slug
- **AND** the entry includes an engine module
- **AND** the entry includes a BGG id
- **AND** the entry does not include an iframe sandbox policy

#### Scenario: Registry entry excludes provider-derived metadata
- **WHEN** the application loads a registry entry
- **THEN** title, preview URL, description, player counts, and other BGG-derived display fields are not required stable registry fields

## REMOVED Requirements

### Requirement: Iframe sandbox policy uses the game registry
**Reason**: Iframe capability grants are shell framing policy owned by `D20Web.Module`, not game identity or runtime bindings.

**Migration**: Remove `sandbox` from every registry entry and consume the shared `D20Web.Module` sandbox configuration when constructing module descriptors. Unknown games remain rejected by registry lookup before descriptor construction.
