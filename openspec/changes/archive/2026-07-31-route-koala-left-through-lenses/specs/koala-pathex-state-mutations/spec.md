## MODIFIED Requirements

### Requirement: Command application is expressed as lens-based aggregate mutation
Every accepted state-changing public Koala command SHALL reach an `apply_command` reducer clause after its external payload and state-dependent legality have been checked. Each `apply_command` clause SHALL read and update aggregate fields through Pathex field or collection paths and SHALL NOT delegate aggregate mutation to a command-specific helper. When Rules derives data required by a transition, command dispatch MUST pass that accepted result to the reducer without repeating rule resolution.

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

#### Scenario: A participant leaves before start
- **WHEN** a `left` command is accepted in setup or ready phase
- **THEN** dispatch passes the command to an `apply_command` reducer clause
- **AND** the reducer removes the actor id through Pathex paths when it is present
- **AND** a missing actor id leaves the players map unchanged
- **AND** the phase lens stores the result of `Rules.ready_to_start?/1` evaluated after the roster mutation

#### Scenario: A participant leaves after start
- **WHEN** a `left` command is received in roll or submit phase
- **THEN** the aggregate remains unchanged without invoking an `apply_command` reducer clause
- **AND** the caller receives the existing successful no-op result

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
