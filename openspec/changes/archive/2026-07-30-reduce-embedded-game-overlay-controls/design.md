## Context

`assets/js/components/dialog.svelte` owns the shell overlay that presents Compact, Theater, Enter fullscreen, and Exit fullscreen actions above every embedded game. The current control surface is `2.5rem` square with `0.5rem` padding; the group uses a `0.375rem` gap and a `0.5rem` block-start and inline-end offset. Those values are unchanged by the existing `34rem` narrow-viewport branch, so the controls retain their desktop footprint when the game field is most constrained.

The iframe game does not render these controls and cannot size them safely across the cross-origin boundary. The change therefore belongs entirely to the D20 shell and must preserve the existing dialog modes, fullscreen state, safe-area placement, accessible names, and stable iframe node.

Current and intended visible geometry:

| Property | Current | Intended | Ratio |
| --- | ---: | ---: | ---: |
| Control inline and block size | `2.5rem` | `2rem` | `0.8` |
| Control padding | `0.5rem` | `0.4rem` | `0.8` |
| Two-control gap | `0.375rem` | `0.3rem` | `0.8` |
| Group edge offset | `0.5rem` | `0.4rem` | `0.8` |
| SVG content box with fixed `1px` border | `calc(1.5rem - 2px)` | `calc(1.2rem - 2px)` | approximately `0.8` |

## Goals / Non-Goals

**Goals:**

- Reduce the control surfaces and complete group geometry by exactly 20% on desktop and mobile viewports.
- Keep icon, padding, spacing, and placement proportions aligned instead of shrinking only the SVG.
- Apply identical geometry to all mode and fullscreen actions and states.
- Preserve existing interaction, accessibility, focus visibility, safe-area behavior, and iframe continuity.

**Non-Goals:**

- Change Theater, Compact, or fullscreen transitions.
- Move, hide, auto-dismiss, or reorder the controls.
- Add viewport-specific controls, labels, tooltips, drag behavior, or persisted preferences.
- Change the iframe module, its game layout, session state, SDK bridge, or public protocol.
- Introduce a new design-system token or dependency for one local control group.

## Decisions

1. Reduce the complete control surface, not only the icon.

   The opaque button background is what covers the game field. Each button therefore changes from `2.5rem` to `2rem`, while its `0.5rem` padding changes to `0.4rem`. The control explicitly uses `border-box`, so those dimensions remain the complete visible surface. Because the SVG already fills the content box and the crisp `1px` border remains fixed, the rendered icon box changes from `calc(1.5rem - 2px)` to `calc(1.2rem - 2px)` without changing SVG markup or stroke geometry.

   Alternative considered: reduce only `.dialog__control svg`. The button would continue covering and intercepting the same area, so it would not solve the reported obstruction.

2. Use the same `0.8` ratio at every supported viewport width.

   The base rules will define the reduced dimensions and the existing narrow media query will continue to adjust only the Theater and Compact player bounds. Mobile therefore receives the same 20% reduction as desktop and cannot fall back to the current `2.5rem` control size.

   Alternative considered: add a second, smaller mobile-only control size. The request specifies a 20% reduction and proportional mobile behavior, but not a separate mobile percentage. Another breakpoint would introduce an unreviewed size and a visible jump without additional product guidance.

3. Scale group spacing and inset with the controls.

   The gap changes from `0.375rem` to `0.3rem`, and the block-start and inline-end offset changes from `0.5rem` to `0.4rem`. A two-button group consequently changes from `5.375rem` to `4.3rem` wide, exactly 80% of its current width, while retaining the same logical top-end placement and safe-area behavior owned by the player.

   Alternative considered: keep existing gap and inset. Fixed spacing would consume a larger share of the reduced group and make the controls look detached from their original composition.

4. Keep crisp state indicators outside the scale contract.

   The `1px` border, `2px` focus outline, color, opacity, cursor, and SVG stroke width stay unchanged. These details communicate boundary, focus, state, and icon shape and do not materially determine the overlay footprint. The fixed border means the SVG content box differs slightly from an exact `0.8` ratio at the default root font size. Explicit dimension changes are preferred over `transform: scale(0.8)`, which would also scale focus and border rendering and make computed layout assertions less direct.

   Alternative considered: transform the whole group. It would visually scale every pixel but couple the hit-tested and painted box to transformed geometry, reduce focus-indicator thickness, and leave less transparent computed sizing for tests.

5. Verify observable geometry at the shell boundary.

   Focused component coverage will query the semantic display buttons and assert their shared computed dimensions, padding, group gap, and inset. Vitest replaces CSS with empty strings by default, so `assets/vite.config.mjs` will process only the `dialog.svelte` scoped stylesheet for this test boundary. Existing tests remain responsible for control names, mode transitions, fullscreen failure handling, iframe identity, and single SDK bridge initialization. Because jsdom does not evaluate viewport media queries or layout, desktop and narrow responsive branches will still be checked in a real browser instead of adding a new test dependency for this CSS-only refinement.

   Alternative considered: snapshot the component markup. A markup snapshot would not prove that the CSS footprint is smaller or that mobile receives the reduced values.

## Risks / Trade-offs

- [Risk] A `2rem` control is a smaller touch target than the current `2.5rem` surface. - Mitigation: preserve semantic native buttons, spacing, focus visibility, and keyboard access, then perform real-device or touch-emulated verification at `320px` and `390px` widths; do not reduce below the specified 20% without a separate accessibility decision.
- [Risk] Browser or user root-font scaling changes absolute pixel dimensions. - Mitigation: retain `rem` units so user scaling applies consistently; verify the normative `0.8` relationship and default computed values rather than hard-coding device pixels.
- [Risk] A later narrow-viewport override could restore larger controls. - Mitigation: keep control geometry in the base rule and include the narrow branch in the required real-browser verification.
- [Trade-off] The border and focus outline do not shrink by 20%. - They remain legible and contribute negligible area compared with the button surface.

## Migration Plan

1. Enable focused `dialog.svelte` CSS processing in Vitest and add computed-style coverage for the shared control geometry.
2. Update the control surface, padding, gap, and group offset in `dialog.svelte`.
3. Run focused frontend tests and lint or type checks, then inspect Theater, Compact, and fullscreen controls at desktop, `390px`, and `320px` widths.
4. Roll back by restoring the four current CSS dimensions. No data, backend, iframe, or deployment-order migration is required.

## Open Questions

- None. The 20% ratio applies uniformly to the existing desktop and mobile control geometry; any additional mobile-only reduction requires a separate product decision.
