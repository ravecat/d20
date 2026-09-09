## Why

The Games hero and compact rows repeat the same games, reducing discovery variety, and their current short ease-out movement feels abrupt. Continue [issue #272](https://github.com/ravecat/d20/issues/272) with disjoint, fully navigable lanes and gentler coordinated CSS motion while retaining the completed compact centering fixes.

## What Changes

- Partition the existing flat Games response in server order: first `ceil(n / 4)` entries in the hero lane, the remainder in the compact lane; 32 games become 8/24 without loss or cross-lane overlap.
- Keep empty Games omitted; render one game as a static hero only. Treat each lane's singleton independently.
- Give every real entry in either lane one canonical internal detail link. Every visible card, including within-lane seamless-loop copies, opens its internal game detail page. Copies remain hidden from accessibility navigation and excluded from sequential keyboard focus, without blocking pointer activation.
- Simplify card accessible names in all three lanes to `aria-label` using the game title or `Open game`, removing generated card-title IDs and their `aria-labelledby` references.
- Advance each multi-item lane by one of its own cards per shared cycle, with independent logical counts and loop lengths rather than synchronized identities or total durations.
- Use a five-second dwell followed by a 1.1-second `ease-in-out` movement (6.1-second cycle). Preserve shared Games hover/focus pause, focus reveal, compact centering, reduced motion, and the existing CSS-only implementation. The shared motion styling also remains consistent for Playable; its selection and pause scope do not change.
- Make Storybook screenshots and semantic play assertions the primary Home coverage for collections, links, names and metadata. Keep separate browser tests only for native keyboard focus, clipped-card pointer activation and reduced-motion scenarios not represented by the existing Storybook harness; remove assertions about copy counts, inert markup, tabIndex values and animation internals. Retain a manual natural-playback review as application visual acceptance, not a test of the CSS engine.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `home-game-discovery`: Replace repeated decorative Games rows with disjoint accessible lanes, lane-local counts and singletons, shared gentler motion, and corresponding focus, metadata, centering, and verification requirements.

## Impact

Expected implementation is confined to `assets/js/pages/home/ui/home.svelte`, nearby Home tests, deterministic Home story fixtures/stories, and affected Home screenshots. No new component framework, carousel library, JavaScript animation machinery, dependency, API, response envelope, database migration, Session/runtime behavior, or iframe contract is needed. The Phoenix controller/context/provider already deliver at most 32 unique random Hot identities by default; backend behavior stays unchanged. No uniqueness history across requests or deduplication against Playable is introduced. Rollback reverts this scoped frontend delivery without reverting compact centering.

This new change owns the pending work in `/home/max/apps/d20/.worktrees/work3` on `worktree/work3`, based on `64f6e824457f2f9540ea3c08d32e087ac79d341e`, with implementation isolated from the primary checkout. The primary checkout has since amended centering and the same target motion cadence into `d9335ba6a81c5cda92158402b96419357b241ee7`. This delivery preserves that cadence, does not edit the older centering archive, and requires reconciliation with the target before any later integration. Issue #272's premature disjoint completion checklist has been corrected and links this follow-up; it remains Open/In Progress in the D20 Project. Implementation is now authorized, including clickable hero and compact loop copies. The latest user request authorizes final test cleanup, native specification synchronization/archive, one semantic commit and linear transfer to local master after validation. Retire work3 after integrated-target checks pass. Remote publication is outside this scope.
