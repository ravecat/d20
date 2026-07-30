## 1. Early State-Model Gate

- [x] 1.1 Add the authoritative state model as the first required discovery artifact in `SKILL.md`.
- [x] 1.2 Require named states, transition tables, command coverage, aggregate facts, and projections to derive from the reviewed model before implementation.

## 2. Architecture Guidance

- [x] 2.1 Add an authoritative state-model template covering dimensions, reachable combinations, invariants, facts, stimuli, effects, next states, and rejections.
- [x] 2.2 Document the distinction between modeled composite states, runtime phase atoms, committed aggregate facts, and derived projection values.

## 3. Validation Gates

- [x] 3.1 Extend the implementation checklist with state-model discovery, traceability, transition-coverage, and unresolved-gap checks.
- [x] 3.2 Extend the completion gate so every command and projected field traces to the state model and every reachable state has explicit behavior.

## 4. Skill Validation

- [x] 4.1 Run the skill validator and inspect the focused documentation diff for consistency and unnecessary duplication.
