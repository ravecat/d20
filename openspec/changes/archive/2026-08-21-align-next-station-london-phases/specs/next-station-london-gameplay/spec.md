## MODIFIED Requirements

### Requirement: Session creation selects optional modules through top-level fields
The system SHALL create Next Station: London with top-level `objectives` and `powers` boolean attrs, each defaulting to false, and SHALL NOT introduce a `variants` wrapper or separate `shared_objectives` and `pencil_powers` aggregate fields.

#### Scenario: Advanced modules are enabled
- **WHEN** a caller supplies `objectives: true` and `powers: true`
- **THEN** the engine initializes the enabled but unprepared fields as `objectives: []` and `powers: %{}` before the session process starts
- **AND** the first reveal replaces those empty values with exactly two objective ids and one complete color-to-power map

### Requirement: The players map is the sole frozen game roster
The system SHALL accept 1 to 4 setup players in `game.players` keyed by participant id, require the session owner to be a joined player before start, and use that map as the sole gameplay roster. The system SHALL NOT store, project, sort, or reconstruct a player-order field or encode roster readiness as a game phase.

#### Scenario: Player joins setup
- **WHEN** a new authenticated actor joins during setup and fewer than four players are present
- **THEN** the game adds exactly one entry keyed by that actor id to `game.players`
- **AND** the game remains in setup
- **AND** start readiness is derived as true when at least one player is present

#### Scenario: Duplicate player joins setup
- **WHEN** an existing player joins again during setup
- **THEN** the game returns success without duplicating that player
- **AND** the game remains in setup

#### Scenario: Fifth player joins setup
- **WHEN** a new actor joins after four setup players are present
- **THEN** the game rejects the join with `player_limit_reached`
- **AND** `game.players` remains unchanged

#### Scenario: Player leaves setup
- **WHEN** a joined player leaves during setup
- **THEN** the game removes that player
- **AND** start readiness is derived again from the remaining roster

#### Scenario: Owner starts while not joined
- **WHEN** the outer session owner sends start without being a joined game player
- **THEN** the game rejects start with `not_joined`

#### Scenario: Owner starts a valid game
- **WHEN** the joined owner starts during setup with 1 to 4 players
- **THEN** the game freezes the existing `game.players` entries
- **AND** the outer session enters in progress
- **AND** the inner game sets round 1 and enters reveal

### Requirement: Automatic pencil rotation gives every player every color once
The system SHALL automatically assign every frozen participant exactly one distinct pencil color per round and every color exactly once across four rounds. Pencil order SHALL NOT be a player-supplied start input.

#### Scenario: Solo pencil cycle is prepared
- **WHEN** a one-player game reveals its first round
- **THEN** the server commits one shuffled four-color cycle
- **AND** it commits pencil offset 0 for the sole player
- **AND** the player uses the committed cycle over rounds 1 through 4

#### Scenario: Multiplayer pencil cycle is prepared
- **WHEN** a game with 2 to 4 players reveals its first round
- **THEN** the server commits one shuffled four-color cycle
- **AND** it shuffles participant ids and commits offsets from 0 through `player_count - 1` using an explicit participant-id-to-offset assignment
- **AND** a player with offset `i` in round `r` uses cycle index `(i + r - 1) mod 4`
- **AND** no offset depends on map enumeration or implies a player order

#### Scenario: Pencil setup is invalid
- **WHEN** the first reveal omits a player id, names an unknown player id, repeats an offset, supplies an offset outside the expected `0` through `player_count - 1` set, or supplies a non-permutation color cycle
- **THEN** reveal is rejected with `invalid_system_setup`

#### Scenario: Owner starts without pencil inputs
- **WHEN** a joined owner starts an eligible setup game with 1 to 4 players
- **THEN** the start payload is empty
- **AND** the waiting projection omits declarative start-form attributes
- **AND** pencil assignments remain unset until the automatic first reveal commits them

### Requirement: Station reveal is automatic, committed once, and hidden
The system SHALL use a Next Station: London custom server to dispatch exactly one actorless reveal on each entry to the reveal phase. A reveal SHALL prepare a valid shuffled deck when a round has no committed deck, or advance the already committed deck between turns.

#### Scenario: System reveals the first instruction of a round
- **WHEN** the custom server dispatches actorless `reveal` with a valid full-deck permutation for a new round
- **THEN** the game commits that remaining deck once
- **AND** reveals the first effective instruction
- **AND** marks every entry in `game.players` pending
- **AND** enters turn

#### Scenario: System reveals the next instruction in a round
- **WHEN** the custom server dispatches actorless `reveal` with an empty payload after a completed turn and the round has a committed remaining deck
- **THEN** the game reveals the next effective instruction from that deck
- **AND** marks every entry in `game.players` pending
- **AND** enters turn

#### Scenario: Client attempts system reveal
- **WHEN** a client actor dispatches `reveal`
- **THEN** the game rejects it with `system_only`
- **AND** no random setup or instruction is committed

#### Scenario: Reveal is duplicated
- **WHEN** another `reveal` arrives after the game entered turn
- **THEN** the game rejects it with `invalid_phase`
- **AND** the committed deck and current instruction remain unchanged

#### Scenario: Generated setup is invalid
- **WHEN** the custom server generates a new-round reveal payload that the game rejects
- **THEN** the session process terminates with an observable invalid-random-setup reason
- **AND** the session does not remain silently stuck in reveal

#### Scenario: Projection is rendered during a round
- **WHEN** any participant or spectator receives a projection
- **THEN** previously revealed cards are visible
- **AND** the active current instruction is visible only during turn
- **AND** the remaining deck and future reveal order are absent

### Requirement: Station instructions resolve simultaneously
The system SHALL give every frozen player-map entry one optional construction action during each shared turn and SHALL enter reveal only after all `game.players` entries have submitted.

#### Scenario: Participant draws for current instruction
- **WHEN** a pending participant submits a valid `draw` action during turn
- **THEN** the complete one-or-more-section action is committed to that player's current colored line
- **AND** the player becomes submitted for this instruction

#### Scenario: Participant passes
- **WHEN** a pending participant submits `pass` during turn
- **THEN** no section is added
- **AND** the player becomes submitted for this instruction

#### Scenario: Participant submits twice
- **WHEN** a submitted participant draws or passes again for the same instruction
- **THEN** the command is rejected with `already_submitted`
- **AND** the network remains unchanged

#### Scenario: Some participants are still pending
- **WHEN** an accepted action leaves at least one `game.players` entry pending
- **THEN** the game remains in turn
- **AND** the current instruction remains active
- **AND** no future card is revealed

#### Scenario: All participants submit before round end
- **WHEN** the last pending participant submits and fewer than five Underground cards have been revealed
- **THEN** the game enters reveal
- **AND** the next instruction is not exposed until the actorless reveal is accepted

#### Scenario: Disconnected player remains pending
- **WHEN** a frozen disconnected participant has not submitted
- **THEN** the engine does not automatically pass, reveal, score, or remove that player

#### Scenario: Known action is sent outside its phase
- **WHEN** `start`, `reveal`, `draw`, or `pass` is dispatched outside its allowed non-terminal phase
- **THEN** the command is rejected with `invalid_phase`
- **AND** the game remains unchanged

### Requirement: Each round scores one colored line
The system SHALL score the current colored line after every participant resolves the turn containing the fifth Underground card.

#### Scenario: Line score is calculated
- **WHEN** a colored line is scored
- **THEN** its score is the number of districts containing at least one line station multiplied by the largest count of that line's stations in one district
- **AND** 2 points are added for each used section flagged as crossing the Thames

#### Scenario: Line has no sections
- **WHEN** a player passed every instruction for one color
- **THEN** that color's departure station still counts as one line station in its district
- **AND** it can contribute that color to later interchange and whole-network objective calculations

#### Scenario: District geometry is crossed without a station
- **WHEN** a section passes through a district but the line contains no station assigned to that district
- **THEN** that district is not counted for line scoring

#### Scenario: Tourist visits are recorded
- **WHEN** the colored line contains tourist sites
- **THEN** each distinct tourist station on that line adds one tourist mark
- **AND** cumulative marks are capped at 10 with excess marks ignored

#### Scenario: Round 1 through 3 ends
- **WHEN** all players finish the final turn of round 1, 2, or 3
- **THEN** current line scores and tourist marks are committed
- **AND** round increments
- **AND** round-only deck and instruction state are cleared
- **AND** the game enters reveal for the next pencil color

### Requirement: Projection and permissions are caller-specific and explicit
The system SHALL render Next Station: London through a dedicated projection and SHALL NOT expose a raw Session or raw game aggregate.

#### Scenario: Pending participant receives turn projection
- **WHEN** a frozen pending participant receives a projection during turn
- **THEN** it includes the standard session envelope, caller id, top-level objectives, top-level powers, round, current instruction, reveal history, public pencil assignments, the participant-id-keyed players map, committed networks, statuses, scores, and permissions
- **AND** it contains no variants or player-order field
- **AND** it includes caller-only legal section and power options derived from Rules

#### Scenario: Reveal projection is rendered
- **WHEN** any caller receives a projection during reveal
- **THEN** `current_instruction` is null and caller-only legal options are empty
- **AND** `can_draw` and `can_pass` are false
- **AND** completed public reveal history remains visible

#### Scenario: Submitted participant receives turn projection
- **WHEN** a submitted participant receives a projection for the current instruction
- **THEN** legal options are empty
- **AND** `can_draw` and `can_pass` are false

#### Scenario: Spectator receives projection
- **WHEN** a non-participant receives an in-progress projection
- **THEN** public committed game facts are visible
- **AND** participant-only legal options are empty
- **AND** all gameplay mutation permissions are false

#### Scenario: Finished projection is rendered
- **WHEN** any existing caller receives a finished projection
- **THEN** complete public score and outcome data is present
- **AND** all mutation permissions are false

#### Scenario: Future cards remain private
- **WHEN** any setup, reveal, turn, or finished projection is rendered
- **THEN** remaining deck, full prepared permutation, and future instruction fields are absent

### Requirement: Playable runtime and public contract are integrated together
The system SHALL expose the existing `next-station-london` registry entry as an in-progress preview only when engine, projection, permissions, contract, and integration coverage are present.

#### Scenario: Public contract is requested
- **WHEN** a developer requests the Next Station: London contract
- **THEN** `priv/specs/next-station-london.yaml` is served and indexed
- **AND** it documents creation attrs, commands, replies, stable errors, permissions, projections, automatic reveals, and hidden future cards
