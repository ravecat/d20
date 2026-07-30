# koala-pathex-state-mutations Specification

## Purpose
TBD - created by archiving change evaluate-koala-pathex-lenses. Update Purpose after archive.
## Requirements
### Requirement: Koala field lenses do not duplicate schema metadata
`D20.KoalaRescueClub.Game` SHALL define one private Pathex macro that inlines map paths for aggregate field references. The lens mechanism SHALL NOT maintain a second enumeration of embedded-schema fields or depend on Ecto's internal compile-time field attributes.

#### Scenario: Reducer addresses a declared aggregate field
- **WHEN** reducer code requests a lens for a declared Koala aggregate field
- **THEN** the lens addresses that field on the `Game` struct
- **AND** the generated traversal is compatible with struct and map values

#### Scenario: Reducer executes an invalid internal field path
- **WHEN** reducer code executes a bang operation with a lens field absent from the aggregate
- **THEN** the traversal fails as a programmer defect
- **AND** the failure does not become a new domain error or dispatch result

### Requirement: Command application is expressed as lens-based aggregate mutation
Every Koala `apply_command/2` clause SHALL read and update aggregate fields through Pathex field or collection lenses. Command application SHALL NOT use direct struct updates or command-specific aggregate mutation helpers.

#### Scenario: A new player joins setup
- **WHEN** a valid participant joins a setup or ready game without an existing player entry
- **THEN** the reducer inserts one fully initialized player under that participant id through the players lens
- **AND** the player's sheet is initialized from the aggregate's selected rulesheet
- **AND** the phase is set from `Rules.ready_to_start?/1` after insertion

#### Scenario: An existing player rejoins
- **WHEN** a valid participant joins and `game.players` already contains that participant id
- **THEN** the players-lens mutation preserves the complete existing player value
- **AND** no sheet, status, turns, rounds, badges, or other committed player fact is reset
- **AND** the aggregate phase is still refreshed from the unchanged roster

#### Scenario: A ready game starts
- **WHEN** a valid `start` command is applied to a ready game
- **THEN** field lenses set phase to `:roll`, derive mode from the accepted players map, and initialize round and turn to `1`
- **AND** a collection lens resets every player to status `:ready` with empty rounds, badges, and turns
- **AND** every player remains keyed by the same actor id

#### Scenario: A shared roll is applied
- **WHEN** a valid server-owned `roll` command is applied
- **THEN** field lenses set phase to `:submit` and store the rolled value
- **AND** a collection lens sets every accepted player status to `:pending`
- **AND** all other player state remains unchanged

### Requirement: The lens experiment preserves external behavior
The Pathex experiment SHALL preserve existing Koala command results, validation, aggregate shape, public projection, protocol schema, and session runtime behavior.

#### Scenario: A caller dispatches join
- **WHEN** a caller dispatches a valid or invalid `join` command
- **THEN** the caller observes the same success aggregate or stable error reason as before the lens refactor
- **AND** no new public field, command payload, or failure shape is introduced
