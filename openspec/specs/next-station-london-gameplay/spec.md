# next-station-london-gameplay Specification

## Purpose
TBD - created by archiving change implement-next-station-london-rules. Update Purpose after archive.
## Requirements
### Requirement: Session creation selects optional modules through top-level fields
The system SHALL create Next Station: London with top-level `objectives` and `powers` boolean attrs, each defaulting to false, and SHALL NOT introduce a `variants` wrapper or separate `shared_objectives` and `pencil_powers` aggregate fields.

#### Scenario: Base session is created
- **WHEN** a caller creates Next Station: London without module attrs
- **THEN** the engine initializes in setup with `objectives: nil` and `powers: nil`

#### Scenario: Advanced modules are enabled
- **WHEN** a caller supplies `objectives: true` and `powers: true`
- **THEN** the engine initializes the enabled but unprepared fields as `objectives: []` and `powers: %{}` before the session process starts
- **AND** first-round preparation replaces those empty values with exactly two objective ids and one complete color-to-power map

#### Scenario: Creation attrs are malformed
- **WHEN** either module attr is not a boolean
- **THEN** session creation fails with invalid creation attrs
- **AND** no session process starts

### Requirement: The players map is the sole frozen game roster
The system SHALL accept 1 to 4 setup players in `game.players` keyed by participant id, require the session owner to be a joined player before start, and use that map as the sole gameplay roster. The system SHALL NOT store, project, sort, or reconstruct a player-order field.

#### Scenario: Player joins setup
- **WHEN** a new authenticated actor joins before start and fewer than four players are present
- **THEN** the game adds exactly one entry keyed by that actor id to `game.players`
- **AND** the game becomes ready when at least one player is present

#### Scenario: Duplicate player joins setup
- **WHEN** an existing player joins again before start
- **THEN** the game returns success without duplicating that player

#### Scenario: Fifth player joins setup
- **WHEN** a new actor joins after four setup players are present
- **THEN** the game rejects the join with `player_limit_reached`
- **AND** `game.players` remains unchanged

#### Scenario: Player leaves setup
- **WHEN** a joined player leaves before start
- **THEN** the game removes that player and recomputes readiness

#### Scenario: Owner starts while not joined
- **WHEN** the outer session owner sends start without being a joined game player
- **THEN** the game rejects start with `not_joined`

#### Scenario: Owner starts a valid game
- **WHEN** the joined owner starts with 1 to 4 players
- **THEN** the game freezes the existing `game.players` entries by entering round preparation
- **AND** the outer session enters in progress
- **AND** the inner game enters round preparation for round 1

### Requirement: Automatic pencil rotation gives every player every color once
The system SHALL automatically assign every frozen participant exactly one distinct pencil color per round and every color exactly once across four rounds. Pencil order SHALL NOT be a player-supplied start input.

#### Scenario: Solo pencil cycle is prepared
- **WHEN** a one-player game prepares round 1
- **THEN** the server commits one shuffled four-color cycle
- **AND** it commits pencil offset 0 for the sole player
- **AND** the player uses the committed cycle over rounds 1 through 4

#### Scenario: Multiplayer pencil cycle is prepared
- **WHEN** a game with 2 to 4 players prepares round 1
- **THEN** the server commits one shuffled four-color cycle
- **AND** it shuffles participant ids and commits offsets from 0 through `player_count - 1` using an explicit participant-id-to-offset assignment
- **AND** a player with offset `i` in round `r` uses cycle index `(i + r - 1) mod 4`
- **AND** no offset depends on map enumeration or implies a player order

#### Scenario: Pencil setup is invalid
- **WHEN** round-one preparation omits a player id, names an unknown player id, repeats an offset, supplies an offset outside the expected `0` through `player_count - 1` set, or supplies a non-permutation color cycle
- **THEN** preparation is rejected with `invalid_system_setup`

#### Scenario: Owner starts without pencil inputs
- **WHEN** a joined owner starts a ready game with 1 to 4 players
- **THEN** the start payload is empty
- **AND** the waiting projection omits declarative start-form attributes
- **AND** pencil assignments remain unset until automatic round-one preparation commits them

### Requirement: In-progress membership does not change game players
The system SHALL use the keys of the frozen start-time `game.players` map for every submission and completion predicate.

#### Scenario: Frozen player disconnects
- **WHEN** a frozen participant leaves during an in-progress game
- **THEN** outer session membership is updated
- **AND** the game retains that participant, network, pending status, and completion obligation

#### Scenario: Frozen player reconnects
- **WHEN** the same actor joins again during the game
- **THEN** the actor regains access to the existing player slot
- **AND** no player or line state is reset

#### Scenario: New actor joins after start
- **WHEN** an actor whose id is not a key in the frozen players map joins during the game
- **THEN** the actor is a spectator
- **AND** the actor cannot draw, pass, or delay instruction completion

### Requirement: Round preparation is automatic, committed once, and hidden
The system SHALL use a Next Station: London custom server to prepare exactly one valid shuffled deck on entry to each round preparation phase.

#### Scenario: System prepares a round
- **WHEN** the custom server dispatches actorless `prepare_round` with a valid full-deck permutation
- **THEN** the game commits that remaining deck once
- **AND** reveals the first effective instruction
- **AND** marks every entry in `game.players` pending
- **AND** enters build

#### Scenario: Client attempts system preparation
- **WHEN** a client actor dispatches `prepare_round`
- **THEN** the game rejects it with `system_only`
- **AND** no random setup is committed

#### Scenario: Preparation is duplicated
- **WHEN** another `prepare_round` arrives after the game entered build
- **THEN** the game rejects it with `invalid_phase`
- **AND** the committed deck and current instruction remain unchanged

#### Scenario: Generated setup is invalid
- **WHEN** the custom server generates a payload that the game rejects
- **THEN** the session process terminates with an observable invalid-random-setup reason
- **AND** the session does not remain silently stuck in round preparation

#### Scenario: Projection is rendered during a round
- **WHEN** any participant or spectator receives a projection
- **THEN** current and previously revealed cards are visible
- **AND** the remaining deck and future reveal order are absent

### Requirement: Station instructions resolve simultaneously
The system SHALL give every frozen player-map entry one optional construction action for each effective shared instruction and SHALL expose the next instruction only after all `game.players` entries have submitted.

#### Scenario: Participant draws for current instruction
- **WHEN** a pending participant submits a valid `draw_sections` action
- **THEN** the complete action is committed to that player's current colored line
- **AND** the player becomes submitted for this instruction

#### Scenario: Participant passes
- **WHEN** a pending participant submits `pass`
- **THEN** no section is added
- **AND** the player becomes submitted for this instruction

#### Scenario: Participant submits twice
- **WHEN** a submitted participant draws or passes again for the same instruction
- **THEN** the command is rejected with `already_submitted`
- **AND** the network remains unchanged

#### Scenario: Some participants are still pending
- **WHEN** an accepted action leaves at least one `game.players` entry pending
- **THEN** the current instruction remains active
- **AND** no future card is revealed

#### Scenario: All participants submit before round end
- **WHEN** the last pending participant submits and fewer than five Underground cards have been revealed
- **THEN** the engine reveals the next effective instruction from the already committed deck
- **AND** all `game.players` entries become pending again

#### Scenario: Disconnected player remains pending
- **WHEN** a frozen disconnected participant has not submitted
- **THEN** the engine does not automatically pass, reveal, score, or remove that player

### Requirement: Sections follow printed construction geometry
The system SHALL accept only static potential sections and SHALL validate the candidate against the complete committed player network.

#### Scenario: Colored line is initialized
- **WHEN** a round begins for one pencil color
- **THEN** that color's departure station is the first node of the line before any section is drawn
- **AND** the node remains part of the colored line even if the player passes every instruction

#### Scenario: First section is drawn
- **WHEN** a player draws the first section of a colored line
- **THEN** its origin is that color's departure station
- **AND** its target is a station on one static potential section from that departure

#### Scenario: Ordinary later section is drawn
- **WHEN** a player draws a later section without an effective switch
- **THEN** its origin is a degree-one endpoint of the current colored line

#### Scenario: Target revisits the same colored line
- **WHEN** a candidate target station already belongs to the current colored line
- **THEN** the action is rejected with `station_revisited`

#### Scenario: Section is not printed on the map
- **WHEN** the submitted endpoints are not one static potential section
- **THEN** the action is rejected with `invalid_section`

#### Scenario: Section is reused by another color
- **WHEN** the same undirected section already belongs to any colored line in the player's network
- **THEN** the action is rejected with `section_reused`

#### Scenario: Section crosses an existing section
- **WHEN** a candidate segment intersects an existing segment anywhere other than a station that is an endpoint of both
- **THEN** the action is rejected with `section_crossing`

#### Scenario: Different lines share a station
- **WHEN** a candidate section ends at a station already used by another color without crossing or reusing a section
- **THEN** the section is legal with respect to intersection rules
- **AND** the station can become an interchange

### Requirement: Destination symbols are authoritative
The system SHALL require every drawn section target to match the current effective destination while treating the central wild station as a match for every ordinary symbol.

#### Scenario: Ordinary symbol matches
- **WHEN** the effective destination is circle, square, triangle, or pentagon
- **THEN** an ordinary target with the same symbol is accepted if all other section rules pass

#### Scenario: Ordinary symbol differs
- **WHEN** the effective destination is an ordinary symbol and the target has another ordinary symbol
- **THEN** the action is rejected with `invalid_destination`

#### Scenario: Central station is targeted
- **WHEN** a section targets central wild station `r3c5`
- **THEN** the station satisfies any ordinary or Joker destination

### Requirement: Joker and Railroad Switch cards follow special construction rules
The system SHALL combine special Station cards with the ordinary construction predicates without weakening unrelated geometry or occupancy rules.

#### Scenario: Joker is revealed
- **WHEN** the effective destination card is either Joker
- **THEN** each participant may choose any ordinary destination symbol for that instruction

#### Scenario: Railroad Switch is revealed
- **WHEN** the Railroad Switch is the next card in the committed deck
- **THEN** the engine immediately consumes the following card as the destination card for the same instruction
- **AND** the Switch and destination cards remain visible in reveal history

#### Scenario: Switch occurs on instruction 1 or 2
- **WHEN** Railroad Switch is paired on either of the first two construction instructions
- **THEN** its branch privilege is disabled
- **AND** the paired destination still resolves as an ordinary endpoint instruction

#### Scenario: Switch occurs after instruction 2
- **WHEN** Railroad Switch is paired after the second instruction
- **THEN** a player may originate the submitted section at any station already on the current colored line
- **AND** later ordinary sections may extend from any degree-one endpoint created by the branch

#### Scenario: Switch is paired with the fifth Underground card
- **WHEN** the paired destination becomes the fifth revealed Underground card
- **THEN** that combined instruction is the final instruction of the round

### Requirement: Rejected actions are atomic and do not publish
The system SHALL validate a complete draw or pass candidate before mutating the game.

#### Scenario: One part of a compound action is invalid
- **WHEN** any submitted section, power modifier, or cross-field constraint fails
- **THEN** no submitted section or power use is committed
- **AND** the player remains pending
- **AND** the server does not broadcast an updated session

#### Scenario: Complete action is valid
- **WHEN** every structural and state-dependent predicate succeeds
- **THEN** the server stores one updated session
- **AND** broadcasts one caller-rendered update through the existing session publication path

### Requirement: Each round scores one colored line
The system SHALL score the current colored line after every participant resolves the instruction containing the fifth Underground card.

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
- **WHEN** all players finish the final instruction of round 1, 2, or 3
- **THEN** current line scores and tourist marks are committed
- **AND** round increments
- **AND** the game enters preparation for the next pencil color

### Requirement: Final scoring determines complete outcomes
The system SHALL finish after round 4 and expose line, tourist, interchange, objective, total, winner, tie-breaker, and solo result data as applicable.

#### Scenario: Interchanges are scored
- **WHEN** final scoring evaluates a station used by 2, 3, or 4 distinct colored lines
- **THEN** that station scores 2, 5, or 9 points respectively
- **AND** repeated sections within one color cannot increase its distinct-line count

#### Scenario: Multiplayer total is calculated
- **WHEN** a multiplayer game finishes
- **THEN** each total equals four colored-line scores plus tourist score plus interchange score plus achieved Shared Objective points

#### Scenario: Multiplayer winner is determined
- **WHEN** final totals differ
- **THEN** every player with the highest total is identified as the winning candidate

#### Scenario: Total score is tied
- **WHEN** players tie on final total
- **THEN** the player with the highest single colored-line score wins
- **AND** a remaining tie is recorded as shared victory

#### Scenario: Solo result is determined
- **WHEN** a solo game finishes
- **THEN** the engine applies enabled-module penalties to the final score for rating purposes
- **AND** returns the matching continuous solo band

#### Scenario: Game reaches terminal state
- **WHEN** final scoring completes
- **THEN** the inner phase becomes finished
- **AND** `D20.Game.finished?/1` returns true
- **AND** the outer session phase becomes finished

### Requirement: Projection and permissions are caller-specific and explicit
The system SHALL render Next Station: London through a dedicated projection and SHALL NOT expose a raw Session or raw game aggregate.

#### Scenario: Pending participant receives projection
- **WHEN** a frozen pending participant receives a projection during build
- **THEN** it includes the standard session envelope, caller id, top-level objectives, top-level powers, round, current instruction, reveal history, public pencil assignments, the participant-id-keyed players map, committed networks, statuses, scores, and permissions
- **AND** it contains no variants or player-order field
- **AND** it includes caller-only legal section and power options derived from Rules

#### Scenario: Submitted participant receives projection
- **WHEN** a submitted participant receives a projection for the current instruction
- **THEN** legal options are empty
- **AND** `can_draw_sections` and `can_pass` are false

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
- **WHEN** any setup, build, or finished projection is rendered
- **THEN** remaining deck, full prepared permutation, and future instruction fields are absent

### Requirement: Playable runtime and public contract are integrated together
The system SHALL expose the existing `next-station-london` registry entry as an in-progress preview only when engine, projection, permissions, contract, and integration coverage are present.

#### Scenario: Registry entry is a development preview
- **WHEN** the implementation is complete
- **THEN** slug `next-station-london` retains engine `D20.NextStationLondon.Game`, BGG id `353545`, and existing iframe sandbox values
- **AND** its status is `in_progress` and the catalog presents it as `Soon`
- **AND** session launch is available outside production and unavailable in production through the shared in-progress launch gate

#### Scenario: Public contract is requested
- **WHEN** a developer requests the Next Station: London contract
- **THEN** `priv/specs/next-station-london.yaml` is served and indexed
- **AND** it documents creation attrs, commands, replies, stable errors, permissions, projections, automatic preparation, and hidden future cards
