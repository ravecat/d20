## Context

Issue https://github.com/ravecat/d20/issues/286 requests fluid workspace controls. Shared CSS currently fixes buttons at 30px, icons at 15px, and button padding at 4px with a 16px root font. Both owning specifications repeat those fixed dimensions.

## Goals / Non-Goals

**Goals:** Reduce button dimensions by a factor of 1.5 on narrow viewports, retain current maximum dimensions, and interpolate continuously across Compact, Theater, and fullscreen.

**Non-Goals:** Change status badge or bar dimensions, control order, semantics, session behavior, iframe lifecycle, contracts, or persistence. The persisted-entity gate is inapplicable because this change adds no persisted entity.

## Decisions

Use local CSS literals in the existing control selectors:

| Property | Value |
| --- | --- |
| Button inline/block size | `clamp(1.25rem, 0.9375rem + 1.25vw, 1.875rem)` |
| Icon inline/block size | `clamp(0.75rem, 0.65625rem + 0.375vw, 0.9375rem)` |
| Button padding | `clamp(0.125rem, 0.0625rem + 0.25vw, 0.25rem)` |

At a 16px root, all three reach their minimum at 400px and maximum at 1200px. At 800px, they produce 25px buttons, 13.5px icons, and 3px padding. Separate icon and padding curves preserve legibility and content fit; proportional scaling would reduce the icons to 10px. CSS handles live viewport changes without resize listeners or breakpoint jumps.

Retain the 1.875rem status badge, 0.5rem Compact chrome padding, 0.3rem control gap, and 0.4rem Theater offsets. Update the full affected requirement in each existing specification through deltas.

Use existing workspace stories and add one deterministic story ending in fullscreen, so the shared screenshot hook captures all affected modes. Review affected theme/viewport images before accepting scoped baseline changes. Browser verification must use the D20 target; the unrelated game Storybook currently exposed at localhost:6006 is not valid evidence.

## Risks / Trade-offs

- Smaller pointer targets require checking visible focus and neighboring controls at the minimum size; retain the existing gaps and native semantics.
- Pixel examples assume a 16px root. Verify larger root text without clipping rather than hardcoding pixel geometry.
- The existing visual runner can report a process-shutdown timeout after passing with exit code 0. Record it separately from test results.

## Migration Plan

Deploy the CSS and reviewed story references together. Rollback restores their previous versions; no database or runtime migration is required.

## Open Questions

None. The coordinating task fixes the clamp values and scope.
