## RENAMED Requirements

- FROM: `Koala field lenses do not duplicate schema metadata`
- TO: `Koala paths do not duplicate schema metadata`
- FROM: `Command application is expressed as lens-based aggregate mutation`
- TO: `Command application is expressed as path-based aggregate mutation`
- FROM: `Automatic completed-turn transitions use lens-based aggregate mutation`
- TO: `Automatic completed-turn transitions use path-based aggregate mutation`
- FROM: `The lens experiment preserves external behavior`
- TO: `The path refactor preserves external behavior`

## MODIFIED Requirements

### Requirement: Koala paths do not duplicate schema metadata
`D20.KoalaRescueClub.Game` SHALL use Pathex `path/1` supplied by `use D20.Game` directly for aggregate field references. The shared path configuration SHALL address map fields without maintaining a second enumeration of embedded-schema fields or depending on Ecto's internal compile-time field attributes.

#### Scenario: Reducer addresses a declared aggregate field
- **WHEN** reducer code creates a path for a declared Koala aggregate field
- **THEN** the path addresses that field on the `Game` struct
- **AND** Koala does not define or import a duplicate field-path DSL
- **AND** the generated traversal is compatible with struct and map values

#### Scenario: Reducer executes an invalid internal field path
- **WHEN** reducer code executes a bang operation with a field absent from the aggregate
- **THEN** the traversal fails as a programmer defect
- **AND** the failure does not become a new domain error or dispatch result

### Requirement: Command application is expressed as path-based aggregate mutation
Every accepted state-changing public Koala command SHALL reach an `apply_command` reducer clause after its external payload and state-dependent legality have been checked. Each `apply_command` clause SHALL read and update aggregate fields through direct Pathex field or collection paths and SHALL NOT delegate aggregate mutation to a command-specific helper. When Rules derives data required by a transition, command dispatch MUST pass that accepted result to the reducer without repeating rule resolution.

#### Scenario: A new player joins setup
- **WHEN** a valid participant joins a setup or ready game without an existing player entry
- **THEN** the reducer inserts one fully initialized player under that participant id through the players path
- **AND** the player's sheet is initialized from the aggregate's selected rulesheet
- **AND** the phase is set from `Rules.ready_to_start?/1` after insertion

#### Scenario: An existing player rejoins
- **WHEN** a valid participant joins and `game.players` already contains that participant id
- **THEN** the players-path mutation preserves the complete existing player value
- **AND** no sheet, status, turns, rounds, badges, or other committed player fact is reset
- **AND** the aggregate phase is still refreshed from the unchanged roster

#### Scenario: A participant leaves before start
- **WHEN** a `left` command is accepted in setup or ready phase
- **THEN** dispatch passes the command to an `apply_command` reducer clause
- **AND** the reducer removes the actor id through Pathex paths when it is present
- **AND** a missing actor id leaves the players map unchanged
- **AND** the phase path stores the result of `Rules.ready_to_start?/1` evaluated after the roster mutation

#### Scenario: A participant leaves after start
- **WHEN** a `left` command is received in roll or submit phase
- **THEN** the aggregate remains unchanged without invoking an `apply_command` reducer clause
- **AND** the caller receives the existing successful no-op result

#### Scenario: A ready game starts
- **WHEN** a valid `start` command is applied to a ready game
- **THEN** field paths set phase to `:roll`, derive mode from the accepted players map, and initialize round and turn to `1`
- **AND** a collection path resets every player to status `:ready` with empty rounds, badges, and turns
- **AND** every player remains keyed by the same actor id

#### Scenario: A shared roll is applied
- **WHEN** a valid server-owned `roll` command is applied
- **THEN** field paths set phase to `:submit` and store the rolled value
- **AND** a collection path sets every accepted player status to `:pending`
- **AND** all other player state remains unchanged

#### Scenario: A pending player submits a legal turn
- **WHEN** command validation and Rules accept a pending player's complete `submit` command
- **THEN** dispatch passes the command and the resolved player to an `apply_command` reducer clause
- **AND** Rules resolves the turn exactly once
- **AND** Pathex paths append the accepted die value and commit the resolved player under the same actor id
- **AND** the existing shared turn completion transition runs after the player commit

#### Scenario: A pending player submits an illegal turn
- **WHEN** command validation or Rules rejects a `submit` command
- **THEN** no `apply_command` reducer clause runs
- **AND** the complete source aggregate remains unchanged
- **AND** the caller receives the existing changeset or stable rule error

### Requirement: Automatic completed-turn transitions use path-based aggregate mutation
After a Koala turn is complete, the aggregate SHALL read its current turn and update final or next-turn state through direct Pathex field and collection paths. Automatic completion SHALL NOT delegate player status mutation to a map-rebuild helper, and all score and round derivation SHALL retain the existing rules.

#### Scenario: A non-final completed turn advances
- **WHEN** every accepted player has completed a turn that is not final
- **THEN** the aggregate derives the next turn and round from the current turn
- **AND** field paths set phase to `:roll`, store the next round and turn, and clear the shared roll
- **AND** a collection path sets every accepted player status to `:ready`
- **AND** all other aggregate and player facts remain unchanged

#### Scenario: The final completed turn finishes the game
- **WHEN** every accepted player has completed the final turn
- **THEN** the aggregate derives scores from the complete post-turn state using the existing scoring rules
- **AND** field paths set phase to `:finished` and store the derived scores
- **AND** no next-turn reset is applied
- **AND** the existing caller-specific score and rank results remain unchanged

### Requirement: The path refactor preserves external behavior
The Pathex path refactor SHALL preserve existing Koala command results, validation, aggregate shape, public projection, protocol schema, and session runtime behavior.

#### Scenario: A caller dispatches join
- **WHEN** a caller dispatches a valid or invalid `join` command
- **THEN** the caller observes the same success aggregate or stable error reason as before the path refactor
- **AND** no new public field, command payload, or failure shape is introduced
