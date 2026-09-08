## Why

Tracking issue: [#272](https://github.com/ravecat/d20/issues/272).

The catalog operations should use consistent names for the collections they return: `list_playable/1` and `list_browsable/1`. This bounded naming step continues the current discovery work; the completed stage-configuration step is already archived and provider discovery remains unresolved.

## What Changes

- **BREAKING**: Rename `D20.Games.list_browse/1` to `list_browsable/1` without a compatibility alias.
- Update the home controller, existing tests, and the authoritative catalog contract.
- Preserve `list_playable/1`, shared `list/1`, local selection, configured visibility, exclusions, ordering, limits, metadata enrichment, and return shapes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-catalog`: Use `list_browsable/1` for the existing home browse collection.

## Impact

Touches `lib/d20/games.ex`, `lib/d20_web/controllers/page_controller.ex`, existing catalog tests, and catalog specification artifacts. No database migration, dependency, frontend response, session/runtime, or iframe contract change is required. Rollback restores the function name and its call sites together. Provider discovery and transfer/publication remain outside this step.
