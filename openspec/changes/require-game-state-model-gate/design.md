## Context

`implement-playable-game` currently asks for initial state, phases, transitions, commands, predicates, and visibility before implementation. Those concerns are recorded in separate artifacts, so there is no single gate proving that all reachable state combinations and their invariants have been discovered before `Command`, `Rules`, or `Game` code is written.

The desired model must be complete for state-machine reasoning but must not encourage a maximal aggregate. D20 still requires the committed aggregate to contain only authoritative facts that cannot be derived from immutable rules, caller and session context, or other committed facts.

## Goals / Non-Goals

**Goals:**

- Make authoritative state modeling an explicit early discovery gate.
- Derive named states, the transition table, command coverage, and aggregate facts from one reviewed model.
- Cover nested Session and Game phases, participant statuses, selections or other substates, actor-owned and server-owned stimuli, invariants, rejections, and terminal behavior.
- Block implementation while a reachable combination, transition, or projected field lacks an authoritative source.

**Non-Goals:**

- Require every theoretical cross-product of state dimensions to become a runtime phase.
- Store derived projections, permissions, legal options, timers, or transient UI state in the aggregate.
- Change an existing game engine, runtime contract, or public event.
- Prescribe one diagramming notation for every game.

## Decisions

### Add an authoritative state model before the existing discovery artifacts

The skill will require a state model as the first working artifact. It will identify state dimensions, enumerate reachable combinations, name meaningful states, record invariants and authoritative facts, and map every allowed stimulus to its atomic effects, next state, and stable rejection behavior.

The existing transition table, command table, predicate catalog, and visibility matrix will be derived from and cross-checked against this model. This makes the state model the discovery source rather than a diagram reconstructed after implementation.

Alternative considered: strengthen only the transition table. A transition table does not by itself expose state dimensions, invariants, unreachable combinations, or facts that must persist across transitions.

### Model complete behavior without requiring a maximal aggregate

"Complete" applies to reachable behavior and traceability. The model must include every authoritative fact needed for future transitions and projections, but it must label derived values and exclude them from committed state.

Alternative considered: require a full snapshot schema containing every public field. That would conflate the aggregate with caller-specific projections and encourage cached derived state.

### Gate implementation on traceability and consistency

The workflow and checklist will prevent implementation until:

- every command starts in a reachable modeled state;
- every accepted command has one atomic effect and resulting state;
- every rejection preserves the modeled state;
- every projected field traces to authoritative state, immutable rules, or explicit caller and session context;
- nested Session and Game lifecycle combinations are consistent.

Alternative considered: rely on tests to discover missing combinations. Tests are necessary validation, but discovering the model during implementation makes command and public-contract design unnecessarily expensive to revise.

## Risks / Trade-offs

- [The state model becomes too large for complex games] -> Model orthogonal dimensions and only enumerate reachable combinations that affect behavior, legality, persistence, or visibility.
- [Authors confuse modeled states with runtime phase atoms] -> Explicitly distinguish composite modeled states from the smaller set of `Game.phase` values.
- [The new artifact duplicates the transition table] -> Keep the state model focused on dimensions, combinations, facts, and invariants, then require the transition table to reference those state identifiers.
- [Existing game changes gain planning overhead] -> Apply the gate to new playable games and substantial gameplay extensions, matching the existing skill trigger.

## Migration Plan

1. Add the early state-model gate and fifth working artifact to `SKILL.md`.
2. Add a reusable state-model template and derivation rules to `references/architecture.md`.
3. Extend discovery, state-machine, test, and completion checks in `references/checklist.md`.
4. Validate the skill folder and review the documentation diff.

Rollback consists of reverting the three skill documentation files. No runtime or public protocol migration is required.

## Open Questions

None.
