## MODIFIED Requirements

### Requirement: Game engines receive a shared private lens DSL
`use D20.Game` SHALL configure Pathex map paths, import the supported `all/0` collection lens, and define a private runtime `lens/1` helper for arbitrary aggregate fields. The helper SHALL define the generic field path once per consuming module instead of macro-expanding a complete path closure at every call site. The DSL SHALL NOT expose a new exported runtime API or import reducer-specific helpers unrelated to path addressing.

#### Scenario: A game engine addresses arbitrary aggregate fields
- **WHEN** a module using `D20.Game` applies `lens/1` to fields selected by its reducer
- **THEN** the returned Pathex paths address those fields on map and struct aggregates
- **AND** the helper requires no field registry or Ecto schema metadata
- **AND** the helper remains private to the consuming module
- **AND** invalid bang traversals remain programmer errors

#### Scenario: A game engine updates every collection value
- **WHEN** a module using `D20.Game` composes an aggregate field lens with `all/0` and a nested map path
- **THEN** the Pathex operation updates every focused value
- **AND** map keys and unrelated nested facts remain unchanged

#### Scenario: A game engine does not use lenses
- **WHEN** an existing module uses `D20.Game` only for behaviour callbacks and server selection
- **THEN** it compiles without adding local Pathex declarations
- **AND** its callbacks, default preview, overridable functions, and server selection remain unchanged

#### Scenario: Koala consumes the shared DSL
- **WHEN** `D20.KoalaRescueClub.Game` compiles its existing lens-based transitions
- **THEN** it receives Pathex setup, `all/0`, and the private `lens/1` helper from `D20.Game`
- **AND** it does not repeat those declarations locally
- **AND** its command and automatic transition results remain unchanged
