## MODIFIED Requirements

### Requirement: Game engines receive a shared Pathex path DSL
`use D20.Game` SHALL configure Pathex map paths and import the supported `all/0` collection lens so game engines can use Pathex `path/1` directly for aggregate fields. The DSL SHALL NOT define a project-specific private `lens/1` helper or expose a new exported runtime API, and it SHALL NOT import reducer-specific helpers unrelated to path addressing.

#### Scenario: A game engine addresses arbitrary aggregate fields
- **WHEN** a module using `D20.Game` applies `path/1` to fields selected by its reducer
- **THEN** the returned Pathex paths address those fields on map and struct aggregates
- **AND** the paths require no field registry or Ecto schema metadata
- **AND** the module defines no private `lens/1` proxy
- **AND** invalid bang traversals remain programmer errors

#### Scenario: A game engine updates every collection value
- **WHEN** a module using `D20.Game` composes an aggregate field path with `all/0` and a nested map path
- **THEN** the Pathex operation updates every focused value
- **AND** map keys and unrelated nested facts remain unchanged

#### Scenario: A game engine does not use paths
- **WHEN** an existing module uses `D20.Game` only for behaviour callbacks and server selection
- **THEN** it compiles without adding local Pathex declarations
- **AND** its existing two-element dispatch outcomes remain supported
- **AND** server selection remains the only generated overridable function
- **AND** no default preview callback is generated

#### Scenario: Games consume the shared path surface
- **WHEN** Koala Rescue Club or Next Station: London compiles path-based aggregate transitions
- **THEN** the game receives Pathex setup and `all/0` from `D20.Game`
- **AND** it uses `path/1` directly without defining or receiving a private `lens/1` helper
- **AND** its command and automatic transition results remain unchanged
