## Context

The native account dialog now owns one responsive padding, and the dialog-mode panel removes its own horizontal padding. However, `.auth-panel__content` still declares `scrollbar-gutter: stable`. On platforms with classic scrollbars, that declaration permanently reserves scrollbar width at the inline end even when Register mode does not overflow. Full-width fields and actions therefore start at the dialog content edge but stop roughly one scrollbar width before the matching edge on the right.

The current browser test verifies the inline start only, so it does not detect this asymmetric usable width.

## Goals / Non-Goals

**Goals:**

- Make non-scrolling account methods use the full dialog content width with equal inline insets.
- Retain `overflow-y: auto`, viewport constraints, and narrow Login mode reachability.
- Cover both inline edges in Chromium and Firefox browser tests.

**Non-Goals:**

- Hide, overlay, restyle, or replace a scrollbar when content actually overflows.
- Change dialog width, responsive padding, focus rings, form behavior, or auth semantics.
- Add a compensating child padding or browser-specific scrollbar calculation.

## Decisions

### Remove the permanent scrollbar gutter from the internal content scroller

The panel will keep `overflow-y: auto` and `overscroll-behavior: contain` but remove `scrollbar-gutter: stable`. This lets non-overflowing content fill the complete width established by the dialog padding.

Adding equal reserved gutters on both sides was rejected because it would make the insets numerically symmetric by narrowing every account method, recreating unnecessary nested spacing instead of using the dialog-owned content width.

Moving scrolling to the entire dialog was rejected because the existing internal scroller keeps the title and close action available on short viewports.

### Verify distances from both dialog content edges

The desktop browser test will derive the dialog content boundaries from its border and padding, then compare both boundaries with the email input rectangle. This geometry assertion is appropriate because equal visual insets are the explicit regression contract. Existing role and label locators remain the primary way to find the dialog and input.

## Risks / Trade-offs

- [A classic scrollbar consumes inline-end width when content actually overflows] - Accept the system scrollbar only in the overflowing state and keep all controls reachable through the existing scroller.
- [Switching between non-overflowing and overflowing modes can change the internal usable width] - Preserve the fixed outer dialog width and prefer correct equal insets in the common non-scrolling state over permanent empty space.
- [Browser scrollbar behavior differs] - Run the focused browser test in both configured Chromium and Firefox instances.

## Migration Plan

1. Remove the permanent gutter declaration.
2. Extend the desktop geometry assertion to cover the input inline end.
3. Re-run focused browser, lint, typecheck, formatting, and strict OpenSpec validation.

Rollback restores the single CSS declaration and the previous inline-start-only assertion. No data, deployment, or runtime migration is required.

## Open Questions

None.
