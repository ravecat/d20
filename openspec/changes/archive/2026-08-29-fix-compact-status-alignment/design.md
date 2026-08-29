## Context

Compact workspace chrome is a single flex row containing a non-shrinking status badge, a flexible clipped session-title lane, and non-shrinking controls. The badge currently has only a 5.25rem minimum inline size, so its intrinsic width grows for `Reconnecting` and moves the title lane. Existing block-axis centering is already owned by the row and badge flex alignment.

## Goals / Non-Goals

**Goals:**

- Keep the title lane at one stable inline position for every supported Compact status.
- Keep the badge contents and title vertically centered in the existing row.
- Retain complete visible status text, responsive shrinking of the title lane, and reachable controls.

**Non-Goals:**

- Change status derivation, labels, colors, animation, typography, controls, or session behavior.
- Add JavaScript layout measurement or a reusable sizing abstraction.
- Change Theater or fullscreen presentation.

## Decisions

1. The status badge will use one fixed 9rem inline size, matching the space already required by the longest supported label, `Reconnecting`.

   A fixed flex item keeps the following title lane at one coordinate while preserving the existing `align-items: center` and `justify-content: center` behavior. Because the longest current status already grows to this size, reconnecting-state narrow-viewport behavior does not become wider than it is today.

   Alternative considered: keep intrinsic sizing and add status-specific padding. That still couples title position to label geometry and can drift with font rendering.

   Alternative considered: measure the widest label in JavaScript. Static labels do not justify runtime measurement or client state.

2. Existing Storybook status variants and viewport screenshots will own visual regression coverage.

   The ready fixture already renders Live and Finished together. Reconnecting and Failed fixtures will also expose Compact chrome so references compare the same row structure and reveal title movement or clipping directly.

   Alternative considered: assert computed geometry in component tests. Repository web-testing policy reserves presentation contracts for real-browser screenshots rather than brittle geometry assertions.

## Risks / Trade-offs

- [Risk] Short labels reserve more space and leave less room for the session title. -> The title lane already shrinks and pans overflow, while 9rem matches the existing worst-case Reconnecting layout.
- [Risk] A future status label exceeds 9rem. -> Update the shared status width and visual references when introducing that label rather than allowing runtime layout shift.
- [Risk] Narrow viewports could crowd controls. -> Retain the current flexible zero-minimum title lane and verify mobile visual references and viewport overflow.
