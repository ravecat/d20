## MODIFIED Requirements

### Requirement: Games declare session creation attrs
The system SHALL allow each game engine to declare the attrs required to create a session for that game through its Ecto changeset.

#### Scenario: Game declares creation attrs
- **WHEN** the shell renders `/games/:slug` before a launchable session exists
- **THEN** the shell obtains the creation attrs changeset from the resolved game engine
- **AND** the shell includes a `schema` prop containing JSON Schema generated from that changeset
- **AND** the schema root contains the declared creation defaults derived from the changeset data

#### Scenario: Game has no creation attrs
- **WHEN** a launchable game engine returns a changeset with no fields
- **THEN** the shell provides an object JSON Schema with no properties and an empty object default
- **AND** the shell does not render game-specific creation controls

#### Scenario: Launch is unavailable
- **WHEN** the resolved game cannot launch a session
- **THEN** the shell provides `schema: null`
- **AND** the client does not initialize an SJSF form

#### Scenario: Registry does not own creation attrs
- **WHEN** the shell resolves a game from the registry
- **THEN** the registry provides game identity and runtime bindings such as slug, engine, BGG id, and availability status
- **AND** the registry provides neither game-specific creation attrs nor iframe sandbox policy
- **AND** the registry does not provide game-specific creation validation rules
