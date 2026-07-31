## MODIFIED Requirements

### Requirement: Koala field lenses do not duplicate schema metadata
`D20.KoalaRescueClub.Game` SHALL consume the private Pathex field lens supplied by `use D20.Game` for aggregate field references. The shared lens mechanism SHALL inline map paths without maintaining a second enumeration of embedded-schema fields or depending on Ecto's internal compile-time field attributes.

#### Scenario: Reducer addresses a declared aggregate field
- **WHEN** reducer code requests a lens for a declared Koala aggregate field
- **THEN** the lens addresses that field on the `Game` struct
- **AND** Koala does not define or import a duplicate field-lens DSL
- **AND** the generated traversal is compatible with struct and map values

#### Scenario: Reducer executes an invalid internal field path
- **WHEN** reducer code executes a bang operation with a lens field absent from the aggregate
- **THEN** the traversal fails as a programmer defect
- **AND** the failure does not become a new domain error or dispatch result
