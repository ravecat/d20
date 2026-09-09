## Why

The Playable and lower Games carousels need a centered middle card with symmetrically clipped neighbors, and their current 0.6-second movement feels abrupt. Continue [issue #272](https://github.com/ravecat/d20/issues/272) by combining the delivered centering with a softer transition in the same local completion commit.

## What Changes

- Center the middle visible card in both multi-item compact rows at each settled position, including their initial and reduced-motion presentation.
- Give every moving home carousel row a 5-second stationary dwell followed by a 1.1-second `ease-in-out` transition.
- Preserve responsive card sizing, hero and singleton geometry, server order, CSS-only looping, shared Games timing, hover pause, reduced motion, and canonical keyboard access.
- Verify the actual page served from `master` after integration, as well as existing focused component and static presentation checks.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `home-game-discovery`: Require centered compact-row composition with equally clipped neighboring cards and the shared softer motion cadence.

## Impact

The implementation is confined to `assets/js/pages/home/ui/home.svelte`, with the existing centering test expectations and screenshot baselines retained in the combined delivery. The motion follow-up needs no new tests or baselines. No backend sampling, lane partitioning, Phoenix behavior, APIs, dependencies, persistence, session runtime, or iframe contracts change. Rollback consists of reverting the scoped frontend delivery; this follow-up can also restore the previous timing values alone.
