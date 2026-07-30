## Why

The playable-game workflow requires transition, command, predicate, and visibility artifacts, but it does not require one explicit authoritative state model before implementation. This can leave reachable state combinations, invariants, and asymmetric event paths implicit until code or client integration exposes them.

## What Changes

- Add an early discovery gate that models state dimensions, reachable combinations, invariants, authoritative facts, allowed stimuli, rejection behavior, atomic effects, and resulting states.
- Require transition tables, command tables, aggregate types, and state-machine phases to be derived from that state model.
- Require unresolved or contradictory state combinations to block implementation instead of being inferred during coding.
- Extend the implementation checklist and completion gate so every command and projected field traces back to the authoritative state model.

## Capabilities

### New Capabilities

- `playable-game-state-modeling`: Requires a complete authoritative state model before implementing a playable game state machine.

### Modified Capabilities

None.

## Impact

- Updates `.agents/skills/implement-playable-game/SKILL.md` and its architecture and checklist references.
- Changes the planning and validation workflow for future playable-game implementations without changing runtime code or public game contracts.
- Tracked by GitHub issue [#83](https://github.com/ravecat/d20/issues/83).
