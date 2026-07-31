## Context

Issue #166 reproduces on `/games/koala-rescue-club` at narrow and wide viewports. The standard header is followed by another 24px of shell padding before the preview. The activation panel has a viewport-derived minimum block size, and its flex body grows to fill that minimum. At a `1024x1210` viewport this produces a 608px activation column even though its content needs about 226px, leaving roughly 382px below `Play`. On narrow screens, the previous responsive override reduces but does not address the shared root cause.

The description needs bounded overflow on wide viewports because prose can be long. The activation panel does not: its controls need intrinsic normal flow. The main scroll container additionally uses `scrollbar-gutter: stable`, which reserves scrollbar space on the inline end only and makes physical page insets asymmetric. Routes, Inertia props, form behavior, session state, and embedded modules are outside this CSS defect.

## Goals / Non-Goals

**Goals:**

- Remove the gap between the shell header and preview at every viewport.
- Let the activation panel use intrinsic content height in stacked and split layouts.
- Keep the existing inter-section gap, panel padding, inline page padding, and bottom edge protection.
- Preserve the wide split layout, bounded description overflow, and all activation behavior.
- Keep physical inline page insets symmetric.
- Verify computed layout in a real browser at narrow and wide widths.

**Non-Goals:**

- Redesigning the standard header.
- Changing preview sizing, metadata wrapping, setup controls, or description typography.
- Changing routes, session creation, Inertia props, lobby behavior, or workspace overlays.

## Decisions

1. Use intrinsic activation sizing as the shared base behavior.

   Remove the activation panel's viewport-derived minimum and the body flex growth that expands empty space. The grid already uses `align-items: start`, so the activation and description can have independent content-driven heights while retaining their two-column placement.

   Adding another breakpoint override or compensating negative margins was rejected because both would preserve the wrong base sizing.

2. Remove only the shell's block-start padding.

   The shell retains its inline padding and block-end padding for edge protection. This applies at every viewport because the header-to-preview gap is not part of either layout composition.

3. Reserve scrollbar gutters symmetrically in the shared main scroll container.

   Change `.layout__content` from `scrollbar-gutter: stable` to `stable both-edges`. A classic scrollbar consumes inline space even when no explicit gutter is reserved, so removing the declaration would still leave the long game page asymmetric. Reserving both edges preserves layout stability and makes the physical content area symmetric. The game shell retains its existing responsive inline padding inside that area.

4. Add browser layout regression tests.

   The game page test will render the real Svelte component and assert bounding boxes at `412px` and `1280px`. Both widths verify zero shell-to-preview offset and content-sized activation. The wide case also verifies two-column placement and bounded description overflow. The layout test verifies that the main scroll container no longer reserves a one-sided gutter.

## Risks / Trade-offs

- [A future narrow-page design may want a small header-to-preview inset] - Mitigation: the requirement is scoped to the game detail page and can be changed independently of the shared header.
- [Dynamic activation content can be taller than one viewport] - Mitigation: intrinsic height keeps all controls in normal page flow inside the existing main scroller.
- [Symmetric gutters reserve scrollbar-width space on the inline start] - Mitigation: the space is small, keeps the existing responsive shell padding intact, and prevents both asymmetry and scrollbar-driven layout shift.
- [Browser measurements can become brittle if they assert unrelated dimensions] - Mitigation: assert only the changed offsets, breakpoint behavior, and relative panel placement.

## Migration Plan

Apply the shared intrinsic sizing, shell padding, scrollbar gutter, and focused browser tests without data or deployment migration. Roll back by restoring those declarations and their matching assertions.

## Open Questions

None.
