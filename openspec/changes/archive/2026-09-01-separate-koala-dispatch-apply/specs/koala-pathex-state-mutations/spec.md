## MODIFIED Requirements

### Requirement: Command application is expressed as path-based aggregate mutation
Public `dispatch/2` SHALL be a thin adapter that calls private `execute/2`, propagates its errors, and reduces its successful ordered transition list through private `apply/2`. Every accepted state-changing public Koala command SHALL be validated and resolved by `execute/2` into private, data-only internal transition facts before authoritative aggregate mutation. Private `apply/2` SHALL be the single seam that accepts a `Game.t()` and returns a transformed `Game.t()`. Every `apply/2` clause SHALL update aggregate fields through direct Pathex field, keyed-player, or collection paths and SHALL NOT delegate aggregate mutation to another helper. One-use command decisions and transition sequencing SHALL remain inline in their matching `execute/2` clauses. Retained calculation helpers MAY derive players or scores, but SHALL be meaningful leaf functions that do not call other local helpers and SHALL NOT return a transformed `Game.t()`. When Rules derives data required by a transition, execute MUST pass that accepted result to the application seam without repeating rule resolution.

#### Scenario: A new player joins setup
- **WHEN** command validation and Rules accept a participant joining a setup or ready game without an existing player entry
- **THEN** execute resolves one fully initialized player from the aggregate's selected rulesheet
- **AND** execute resolves the resulting players map and setup phase before aggregate application
- **AND** the player-joined `apply/2` clause stores those resolved facts through Pathex paths

#### Scenario: An existing player rejoins
- **WHEN** a valid participant joins and `game.players` already contains that participant id
- **THEN** execute resolves the players map with the complete existing player value unchanged
- **AND** no sheet, status, turns, rounds, badges, or other committed player fact is reset
- **AND** the player-joined `apply/2` clause refreshes only the already-resolved roster and setup phase

#### Scenario: A participant leaves before start
- **WHEN** a `left` command is accepted in setup or ready phase
- **THEN** execute resolves a players map without that actor id and resolves readiness from the resulting roster
- **AND** a missing actor id leaves the resolved players map unchanged
- **AND** the player-left `apply/2` clause stores the resolved players and phase through Pathex paths

#### Scenario: A participant leaves after start
- **WHEN** a `left` command is received in roll or submit phase
- **THEN** the aggregate remains unchanged without creating or applying an internal transition
- **AND** the caller receives the existing successful no-op result

#### Scenario: A ready game starts
- **WHEN** command validation and Rules accept `start` for a ready game
- **THEN** execute resolves mode from the accepted players map before application
- **AND** the game-started `apply/2` clause sets phase to `:roll`, stores the resolved mode, and initializes round and turn to `1`
- **AND** Pathex collection paths reset every player to status `:ready` with empty rounds, badges, and turns while preserving actor-id keys

#### Scenario: A shared roll is applied
- **WHEN** command validation and Rules accept the server-owned `roll` command
- **THEN** execute resolves exactly one die value before aggregate application
- **AND** the die-rolled `apply/2` clause sets phase to `:submit`, stores that value, and sets every accepted player status to `:pending` through Pathex paths
- **AND** all other player state remains unchanged

#### Scenario: A pending player submits a legal turn
- **WHEN** command validation and Rules accept a pending player's complete `submit` command
- **THEN** execute calls Rules turn resolution exactly once and appends the accepted adjusted die value to that resolved player
- **AND** execute includes the actor id and resolved player in a private turn-submitted transition
- **AND** the turn-submitted `apply/2` clause commits that player under the same actor id through a Pathex path

#### Scenario: A pending player submits an illegal turn
- **WHEN** command validation or Rules rejects a `submit` command
- **THEN** no internal transition is created or applied
- **AND** the complete source aggregate remains unchanged
- **AND** the caller receives the existing changeset or stable rule error

### Requirement: Automatic completed-turn transitions use path-based aggregate mutation
After resolving a submitted player, the submit execute clause SHALL decide the complete ordered internal transition sequence inline from prospective player, game-mode, round, turn, and rulesheet facts before dispatch applies any transition in that sequence. The sequence SHALL preserve existing badge, round, final-score, and turn-advance rules. Badge, round, turn-advance, and finish aggregate changes SHALL each occur in their matching Pathex `apply/2` clause, and no automatic-transition helper SHALL accept and return a modified `Game.t()`.

#### Scenario: Other players remain pending
- **WHEN** one player's resolved submission leaves at least one accepted player pending
- **THEN** execute resolves only the turn-submitted transition
- **AND** applying it commits that player's resolved state without awarding badges, scoring a round, advancing, or finishing

#### Scenario: A completed turn awards badges before progression
- **WHEN** the prospective players map shows every accepted player submitted
- **THEN** execute derives post-award players with the existing solo or multiplayer badge rules
- **AND** the transition sequence applies turn submission before badge award
- **AND** the badges-awarded `apply/2` clause stores the derived players through a Pathex path

#### Scenario: A non-round-ending completed turn advances
- **WHEN** every accepted player has completed a turn that neither ends a round nor finishes the game
- **THEN** execute resolves the badge transition followed by the next turn and round
- **AND** the turn-advanced `apply/2` clause sets phase to `:roll`, stores the resolved round and turn, clears the shared roll, and sets every player status to `:ready` through Pathex paths
- **AND** all other aggregate and player facts remain unchanged

#### Scenario: The first round is scored before turn advance
- **WHEN** every accepted player completes turn 15
- **THEN** execute derives post-award players and then derives each player's round score from those players
- **AND** the transition sequence applies turn submission, badge award, round score, and turn advance in that order
- **AND** the round-scored `apply/2` clause stores the derived players before the turn-advanced clause starts turn 16 in round 2

#### Scenario: The final completed turn scores and finishes
- **WHEN** every accepted player completes the final turn
- **THEN** execute derives post-award players, appends the final round score, and derives final scores from that post-round state
- **AND** the transition sequence applies turn submission, badge award, round score, and finish in that order
- **AND** the game-finished `apply/2` clause sets phase to `:finished` and stores the resolved scores through Pathex paths
- **AND** no next-turn reset is applied

### Requirement: The path refactor preserves external behavior
The transition-application refactor SHALL preserve existing Koala command results, validation order, aggregate shape, public projection, protocol schema, Session and server processing, channel behavior, errors, and gameplay outcomes. Public commands SHALL remain string-named `D20.Command` values at the existing `D20.Game.dispatch/2` interface. Private `execute/2`, internal transitions, and private `apply/2` SHALL NOT be published, persisted, serialized, or exposed as a new interface.

#### Scenario: Dispatch adapts command execution to the existing game interface
- **WHEN** Session calls `D20.KoalaRescueClub.Game.dispatch/2` with a command
- **THEN** dispatch calls private execute with the source aggregate and command
- **AND** an execute error is returned unchanged without applying a transition
- **AND** successful transitions are applied in order before dispatch returns the existing `{:ok, game}` result

#### Scenario: Rules looks up a player
- **WHEN** Koala rules need the player associated with an actor id
- **THEN** Rules uses `Map.fetch/2` directly against the aggregate's players map
- **AND** `Game` does not expose a non-callback `fetch_player/2` proxy
- **AND** existing missing-player and rejoin behavior remains unchanged

#### Scenario: A caller dispatches join
- **WHEN** a caller dispatches a valid or invalid `join` command
- **THEN** the caller observes the same success aggregate or stable error reason as before the refactor
- **AND** no new public field, command payload, or failure shape is introduced

#### Scenario: A caller dispatches an existing Koala command
- **WHEN** a caller or the Koala server dispatches any existing string-named command
- **THEN** the same command-validation, phase, authorization, no-op, success, and error behavior applies
- **AND** only the existing `{:ok, game}` or `{:error, reason}` result crosses the `D20.Game.dispatch/2` interface

#### Scenario: An accepted transition reaches the runtime
- **WHEN** dispatch returns an updated game to the existing Session and Koala server runtime
- **THEN** Session storage, publication, channel replies, caller-specific projections, and finished-state handling remain unchanged
- **AND** no internal transition data reaches the runtime or public protocol
