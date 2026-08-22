# next-station-london-pathex-state-mutations Specification

## Purpose
Define behavior-preserving Next Station: London aggregate mutation through direct Pathex field, keyed-player, and collection paths.

## Requirements

### Requirement: Next Station commands commit aggregate changes through Pathex paths
After command payload and state-dependent legality are accepted, `D20.NextStationLondon.Game` SHALL commit authoritative game state through direct Pathex field, keyed-player, or collection paths. Rules SHALL continue deriving accepted player values without owning aggregate commits.

#### Scenario: A setup player joins
- **WHEN** a valid new participant joins setup
- **THEN** the aggregate inserts one initialized player through the keyed players path
- **AND** an existing participant value remains unchanged on duplicate join

#### Scenario: A setup player leaves
- **WHEN** a valid participant leaves setup
- **THEN** the aggregate removes that actor key through the players path
- **AND** an absent actor key leaves all other players unchanged

#### Scenario: An eligible game starts
- **WHEN** a valid owner starts the setup game
- **THEN** field paths set phase to reveal, round to one, and clear round state
- **AND** collection paths reset every frozen player's status and pencil offset
- **AND** player ids and line state remain unchanged

#### Scenario: The system reveals an instruction
- **WHEN** a valid actorless reveal is accepted
- **THEN** field and collection paths commit any required round setup, consume the effective instruction, append reveal history, set every player pending, and enter turn
- **AND** existing deck, draw, and random-setup rules remain unchanged

#### Scenario: A player action is committed
- **WHEN** Rules accepts a player's draw or pass result
- **THEN** the aggregate stores the submitted player through that actor's keyed path
- **AND** the existing completion predicate decides whether the aggregate remains in turn or advances

### Requirement: Next Station automatic transitions use Pathex paths
Next Station automatic instruction, round, and finish transitions SHALL update aggregate fields and uniform player status through Pathex paths rather than direct game struct updates, `put_in/2`, full player-map rebuild helpers, or `Map.put/3` pipelines.

#### Scenario: A shared turn remains incomplete
- **WHEN** an accepted player action leaves another frozen player pending
- **THEN** only the submitting player path changes
- **AND** phase, round, deck, and draw history remain unchanged

#### Scenario: A shared turn advances within a round
- **WHEN** the final pending player submits before the round-ending instruction
- **THEN** the phase path enters reveal
- **AND** the committed remaining deck and draw history remain available for the next reveal

#### Scenario: A round advances
- **WHEN** the final pending player completes the round-ending instruction before round four
- **THEN** field paths enter reveal, increment round, and clear remaining deck and draw history
- **AND** a collection path sets every frozen player ready without changing line state or pencil assignments

#### Scenario: The game finishes
- **WHEN** the final pending player completes the round-ending instruction in round four
- **THEN** field paths enter finished and clear the remaining deck
- **AND** no next-round reset occurs

### Requirement: The Next Station path refactor preserves observable behavior
The Pathex mutation refactor SHALL preserve the rule-aligned setup, reveal, turn, and finished state machine, command results, errors, aggregate shape, projections, permissions, AsyncAPI, session runtime, and separate client contract.

#### Scenario: Existing transition coverage runs after the refactor
- **WHEN** focused aggregate, rules, server, permission, projection, session, and channel tests exercise Next Station workflows
- **THEN** they observe the same accepted states and stable errors as before the mutation refactor
- **AND** no new public field, command, permission, payload, or failure shape is introduced
