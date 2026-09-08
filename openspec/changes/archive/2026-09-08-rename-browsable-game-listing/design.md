## Context

`D20.Games.list_playable/1` selects enabled local games with visible stages and implemented engines. `list_browse/1` selects visible local games excluding supplied IDs. Both delegate query execution and BGG enrichment to `list/1`. Home selects eight playable entries first and excludes their IDs from the browse collection. The baseline catalog/controller suite passes 79 tests.

## Goals / Non-Goals

**Goals:** Expose the existing browse operation as `list_browsable/1` consistently in code, tests, and the authoritative catalog specification.

**Non-Goals:** Change selection, ordering, limits, return shapes, provider discovery, session policy, or the existing `list_playable/1` and `list/1` APIs.

## Decisions

- Rename the existing function and its typespec, controller call, and test references in one change. Retaining an alias would preserve an unnecessary second name; the user requested the rename and no compatibility requirement exists.
- Reuse the current `worktree/api-game-discovery` and issue #272. Use a bounded OpenSpec change because the configuration step is archived and provider discovery has unresolved requirements. Historical archives remain historical.
- Preserve the existing query implementation and assertions. Validate through the existing catalog/controller tests and touched-file formatting; no frontend or database changes are involved.

## Risks / Trade-offs

- A missed caller would fail with an undefined function. Search live code and tests for the old name and run the focused controller/catalog suite.
- The term browsable does not imply provider discovery: this operation still returns persisted local rows, including disabled games, engine-less games, and playable overflow.

## Migration Plan

Update the function and all callers together. Roll back the same semantic commit if needed; no data migration or deployment verification is required for this naming-only step.

## Open Questions

None for this step. Provider source selection remains outside its acceptance boundary under #272.
