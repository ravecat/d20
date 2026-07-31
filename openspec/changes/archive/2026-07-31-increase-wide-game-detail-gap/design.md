## Context

`.game-detail-layout` is the single spacing owner between activation and description. It currently uses `gap: 1rem` for both its wide two-column and narrow stacked modes.

## Goals / Non-Goals

**Goals:**

- Increase only the wide column separation by 25%, from `1rem` to `1.25rem`.
- Preserve the `1rem` stacked separation at the existing breakpoint.
- Verify both values in real browsers.

**Non-Goals:**

- Changing shell padding, panel padding, internal form gaps, column proportions, or the breakpoint.
- Changing activation, description overflow, routes, sessions, or accessibility.

## Decisions

1. Use `1.25rem` as the base two-column gap and override it to `1rem` inside the existing `max-width: 48rem` media query.

   The base style represents the default wide grid, while the existing media query already owns the stacked transformation. This keeps each gap beside its corresponding layout mode.

2. Assert the rendered distance between the semantic activation and description regions.

   Bounding-box assertions verify the user-visible result rather than only checking a CSS declaration.

## Risks / Trade-offs

- [The additional 4px slightly reduces both grid tracks] - Mitigation: both tracks already use shrinkable `minmax(0, ...)` sizing and focused browser tests cover the supported widths.
