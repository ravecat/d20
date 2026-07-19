## ADDED Requirements

### Requirement: Players can start Koala Rescue Club with a selected map
The system SHALL allow a Koala Rescue Club session owner to start a session on a supported map after at least one player has joined.

#### Scenario: Player joins before start
- **WHEN** a player joins a Koala Rescue Club session before the game starts
- **THEN** the system adds the player to the game order
- **AND** the player receives an empty sheet for the eventual selected map

#### Scenario: Owner starts a supported map
- **WHEN** the session owner starts Koala Rescue Club with map `dharug` or `yugambeh`
- **THEN** the system initializes every joined player with the selected map state
- **AND** the system gives each player the map's initial volunteers
- **AND** the game enters the roll phase for turn 1

#### Scenario: Selected map controls later rules
- **WHEN** Koala Rescue Club has started with a selected map
- **THEN** every later placement, accessibility, bonus, hospital, badge, solo rating, round scoring, and final scoring decision uses that selected map's structure

#### Scenario: Unsupported map cannot start
- **WHEN** the session owner starts Koala Rescue Club with an unsupported map
- **THEN** the system rejects the command with an invalid-map result

### Requirement: Turns use one shared roll and simultaneous submissions
The system SHALL run Koala Rescue Club as 30 simultaneous turns split into two 15-turn rounds.

#### Scenario: Shared die is rolled
- **WHEN** a joined player rolls during the roll phase
- **THEN** the system records one raw die value from 1 through 6 for the current turn
- **AND** every joined player becomes pending for that turn
- **AND** the game enters the submit phase

#### Scenario: Roll cannot be repeated for the same turn
- **WHEN** a raw die value already exists for the current turn
- **THEN** the system rejects another roll for that turn

#### Scenario: Turn advances after all submissions
- **WHEN** every pending player has submitted a valid turn resolution
- **THEN** the system records the raw die result in each submitted player's turn log
- **AND** the system advances to the next turn's roll phase unless the completed turn requires round scoring or finishes the game

### Requirement: Player turn submissions validate die adjustment and action choice
The system SHALL validate each player's submitted turn resolution against the shared die result, available volunteers, selected map, and current sheet state.

#### Scenario: Volunteer adjustment is legal
- **WHEN** a player submits an adjusted die value
- **THEN** the system verifies that the declared volunteers spent can transform the raw die value into the adjusted value with 1-to-6 wraparound
- **AND** the system subtracts spent volunteers from that player's available volunteers

#### Scenario: Shape action places one complete shape
- **WHEN** a player submits a `plant_trees` or `rehome_koalas` event
- **THEN** the system verifies that all target cells match the adjusted die shape under an allowed rotation or flip
- **AND** all target cells are in one accessible area
- **AND** the action uses the entire shape

#### Scenario: Tree action cannot reuse trees
- **WHEN** a player submits a `plant_trees` event
- **THEN** the system rejects any target cell that already has a circled tree

#### Scenario: Koala action requires circled trees
- **WHEN** a player submits a `rehome_koalas` event
- **THEN** the system rejects any target cell without a circled tree
- **AND** the system rejects any target cell whose koala is already circled

#### Scenario: Fallback single-circle action is allowed
- **WHEN** a player submits a `circle_tree` or `circle_koala` event
- **THEN** the system validates exactly one target cell in an accessible area
- **AND** the system applies tree or koala prerequisites for that target

#### Scenario: Mixed primary action is rejected
- **WHEN** a player submits a turn that mixes tree and koala targets in one primary action
- **THEN** the system rejects the command with a mixed-action result

### Requirement: Bonus actions resolve within the turn that completes koala lines
The system SHALL unlock row and column bonuses only when an action completes every koala in the associated row or column, SHALL accept actions only for bonuses opened during the submitted turn, and SHALL resolve omitted bonuses without applying their effects.

#### Scenario: Bonus is claimed in the same turn
- **WHEN** a submitted turn completes a bonus-bearing row or column of koalas
- **THEN** the player may claim that bonus during the same turn resolution
- **AND** the system marks the bonus as claimed

#### Scenario: Multiple bonuses use submitted order
- **WHEN** one turn unlocks multiple bonuses
- **THEN** the system resolves the submitted bonus actions in the order provided by the player

#### Scenario: Invalid bonus is lost or rejected
- **WHEN** a player attempts a bonus action that is not currently unlocked or has already been claimed
- **THEN** the system rejects the bonus action with an invalid-bonus result

#### Scenario: Optional bonus is omitted
- **WHEN** a player unlocks a bonus but submits no bonus action for it
- **THEN** the system accepts the otherwise valid turn
- **AND** marks the omitted bonus resolved without applying its effect
- **AND** the bonus cannot be claimed on a later turn

#### Scenario: Optional bonus is explicitly skipped
- **WHEN** a player submits an explicit skip for a bonus opened during the current turn
- **THEN** the system resolves the skip in submitted order
- **AND** marks the bonus resolved without applying its effect

#### Scenario: Earlier-turn bonus is submitted
- **WHEN** a bonus action refers to a line that was already unlocked before the current primary action
- **THEN** the system rejects the bonus action as outside the current turn
- **AND** does not mutate the committed sheet

#### Scenario: Legacy unresolved bonus is cleaned up
- **WHEN** a sheet already contains an unresolved bonus from an earlier turn
- **AND** the player submits a later valid turn without referencing it
- **THEN** the system marks the legacy bonus resolved without applying its effect

#### Scenario: Selection bonus options use current-turn scope
- **WHEN** an incremental primary selection becomes complete
- **THEN** the projection exposes only bonuses newly unlocked by the simulated primary action

### Requirement: Round scoring follows map-specific area and hospital rules
The system SHALL score Koala Rescue Club after turn 15 and turn 30 using the selected map's scoring rules.

#### Scenario: Areas score after a round
- **WHEN** a round scoring turn is completed
- **THEN** each player scores 1 point for each area completely filled with trees
- **AND** each player scores 1 point for each area completely filled with koalas

#### Scenario: Dharug hospitals score only when complete
- **WHEN** Dharug round scoring is performed
- **THEN** each completed hospital contributes its positive roof value
- **AND** each incomplete hospital contributes 0 points

#### Scenario: Yugambeh hospitals can score negative
- **WHEN** Yugambeh round scoring is performed
- **THEN** each completed hospital contributes its positive roof value
- **AND** each started incomplete hospital contributes its negative value
- **AND** each unstarted hospital contributes 0 points

#### Scenario: Round 2 rescoring includes prior completions
- **WHEN** turn 30 scoring is performed
- **THEN** the system scores all currently complete areas and hospitals, including those already complete during round 1

### Requirement: Badges award points according to player count and timing
The system SHALL award Koala Rescue Club badge points from encoded map predicates after each submitted turn.

#### Scenario: Multiplayer first achievers receive large award
- **WHEN** one or more players first satisfy the same badge on the same turn in a multiplayer game
- **THEN** each first achiever receives the badge's large point value
- **AND** later achievers receive the badge's small point value

#### Scenario: Solo badge award depends on round
- **WHEN** a solo player satisfies a badge in round 1
- **THEN** the player receives the badge's large point value

#### Scenario: Solo round 2 badge uses small award
- **WHEN** a solo player satisfies a badge for the first time in round 2
- **THEN** the player receives the badge's small point value

### Requirement: Game finishes with final scores and tie breaker data
The system SHALL finish Koala Rescue Club after round 2 scoring and expose final scoring data for each player.

#### Scenario: Game finishes after turn 30
- **WHEN** all players have completed valid submissions for turn 30 and scoring is complete
- **THEN** the game phase becomes finished
- **AND** the session phase becomes finished

#### Scenario: Final score is calculated
- **WHEN** the game finishes
- **THEN** each player's final score equals round 1 score plus round 2 score plus badge points

#### Scenario: Tie breaker data is exposed
- **WHEN** final scores are available
- **THEN** each final score includes the player's circled koala count
- **AND** the koala count can be used to break ties

### Requirement: Koala projections expose authoritative state and permissions
The system SHALL render Koala Rescue Club session projections with authoritative game state and caller-specific permissions.

#### Scenario: Projection includes game state
- **WHEN** a Koala Rescue Club session projection is rendered
- **THEN** the projection includes selected map, turn, round, phase, current roll, players, sheets, round scores, badges, and final scores

#### Scenario: Projection includes permissions
- **WHEN** a Koala Rescue Club session projection is rendered for a caller
- **THEN** the projection includes whether that caller can start the game, roll the die, or submit a turn

#### Scenario: Unknown command is rejected
- **WHEN** a client sends an unsupported Koala Rescue Club command event
- **THEN** the system rejects the command with an unknown-command result
