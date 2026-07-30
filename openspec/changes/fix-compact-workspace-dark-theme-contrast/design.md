## Context

The Compact workspace deliberately inverts the daisyUI base theme tokens: its outer surface uses `--color-base-content` and its foreground uses `--color-base-100`. The status badge instead hard-codes a white background and the session label hard-codes white text. Those values contrast in the light theme but collide with the inverted light surface produced by the dark theme.

The browser policy is `baseline widely available with downstream`, excluding Firefox below 128. The correction must use existing stable theme tokens and must not depend on `light-dark()`, browser user-agent colors, or a new theme signal.

## Goals / Non-Goals

**Goals:**

- Keep Compact status and session labels readable for either ordering of the existing base theme tokens.
- Lock both theme variants into the existing real-browser component suite.
- Keep current Compact, Theater, fullscreen, focus, control order, and iframe lifecycle behavior.

**Non-Goals:**

- Redesigning the Compact workspace or changing its inverse-surface visual language.
- Adding a theme toggle or changing global daisyUI theme configuration.
- Adding new browser projects or screenshot infrastructure.
- Changing backend, channel, or iframe module contracts.

## Decisions

### Pair the status badge with existing inverse theme tokens

Use `--color-base-100` for the Compact status background and retain `--color-base-content` for its foreground. This produces the same inverse pair as the Compact controls in either theme.

Alternative considered: keep `white` and branch under a dark-theme selector. That duplicates global theme selection in a leaf component and does not cover future daisyUI theme palettes.

### Let the session label inherit the Compact surface foreground

Remove the fixed white label color so the label inherits the `--color-base-100` foreground already assigned to the Compact dialog surface.

Alternative considered: repeat `--color-base-100` on the label. Inheritance keeps one authoritative foreground assignment at the surface boundary and reduces drift.

### Exercise both token orderings in the browser component test

Retain the existing light-theme assertions and add a focused dark-theme case that swaps the base token values, then asserts computed status, session-label, and control colors. Computed styles prove the browser cascade rather than only matching source text.

Alternative considered: add screenshot snapshots or cross-browser projects. The repository currently has neither visual baselines nor multiple configured browser projects, so that would broaden a two-rule regression into testing infrastructure work.

## Risks / Trade-offs

- [Theme palettes could provide base tokens with weak intrinsic contrast] -> Reuse daisyUI's paired `base-100` and `base-content` semantics and verify the project's representative light and dark values.
- [A global style could later override a child foreground] -> Assert computed colors at the user-visible badge, label, and controls in a real browser.
- [Changing the badge background alters its dark-theme appearance] -> The change intentionally restores the same inverse relationship already used by the Compact controls.

## Migration Plan

Ship the CSS and browser regression test together. No data migration, protocol rollout, or dependency update is required. Rollback reverts the two presentation rules and the focused regression case.

## Open Questions

None.
