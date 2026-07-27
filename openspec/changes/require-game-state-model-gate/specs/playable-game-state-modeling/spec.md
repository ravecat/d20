## ADDED Requirements

### Requirement: Playable game discovery produces an authoritative state model
The playable-game workflow SHALL require an authoritative state model before implementation begins. The model SHALL identify state dimensions, reachable combinations, meaningful state identifiers, invariants, authoritative committed facts, allowed actor or server stimuli, atomic effects, resulting states, stable rejection behavior, and terminal behavior.

#### Scenario: Rules contain orthogonal state dimensions
- **WHEN** a game specification defines lifecycle phases, participant statuses, selections, roles, timers, or other state dimensions
- **THEN** the discovery model records those dimensions and derives the combinations that are reachable under the rules
- **AND** it distinguishes unreachable combinations from states that implementation must support

#### Scenario: A modeled value is derivable
- **WHEN** a value can be recomputed from authoritative facts, immutable rules, and explicit caller and session context
- **THEN** the model marks it as derived
- **AND** the proposed committed aggregate does not store it

### Requirement: State-machine artifacts derive from the authoritative state model
The playable-game workflow SHALL derive its transition table, command table, predicate catalog, aggregate state, phase routing, and visibility matrix from the authoritative state model.

#### Scenario: A command changes state
- **WHEN** the command table includes a client-owned or server-owned stimulus
- **THEN** the command references a reachable source state from the model
- **AND** every accepted path identifies one atomic effect and resulting modeled state
- **AND** every rejected path identifies a stable error and preserves the source state

#### Scenario: Runtime phases are coarser than modeled states
- **WHEN** several modeled states share one runtime `Game.phase` but differ by participant status, selection, or another authoritative substate
- **THEN** the state model retains those meaningful distinctions
- **AND** the implementation derives explicit predicates and event routing for them without requiring a separate phase atom for every combination

### Requirement: Unresolved state-model gaps block implementation
The playable-game workflow SHALL NOT begin `Command`, `Rules`, `Game`, `Permission`, or `Projection` implementation while a material reachable state, invariant, transition, authoritative fact, or visibility source remains unresolved.

#### Scenario: A projected field has no authoritative source
- **WHEN** a required caller-visible field cannot be derived from modeled committed facts, immutable rules, and explicit caller and session context
- **THEN** discovery treats the field as evidence of a missing authoritative fact
- **AND** implementation remains blocked until the model is corrected or the requirement is clarified

#### Scenario: Event paths are asymmetric
- **WHEN** semantically related actions use different command, draft, commit, or server event paths
- **THEN** the state model makes each path and its state effects explicit
- **AND** the difference must be justified or resolved before implementation begins
