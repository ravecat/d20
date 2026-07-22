## Context

`assets/js/components/dialog.svelte` owns the shell presentation around every embedded iframe game. Theater currently uses a centered `min(96dvw, 72rem)` by `min(90dvh, 42rem)` surface on wider viewports and a separate `100dvw - 1rem` by `100dvh - 1rem` rule at or below `34rem`. This makes mobile Theater nearly viewport-filling but leaves unused space on desktop and encodes landscape-oriented maximum dimensions into a shared shell that must host games of different formats.

The player wrapper already occupies `100%` of the dialog in both axes, and mode changes preserve the iframe and SDK bridge. The change can therefore stay inside the Theater CSS boundary. Compact geometry, fullscreen behavior, modal lifecycle, controls, session state, and iframe contracts do not need to change.

## Goals / Non-Goals

**Goals:**

- Give every embedded game nearly the complete safe dynamic viewport in Theater mode on desktop and mobile.
- Use one format-neutral Theater sizing rule at every viewport width.
- Keep a consistent `0.5rem` minimum separation from each viewport edge while respecting larger safe-area insets independently.
- Preserve the existing player, mode transitions, fullscreen behavior, controls, iframe node, and SDK bridge.

**Non-Goals:**

- Infer dialog dimensions or aspect ratio from embedded game content.
- Make the shell scale, center, letterbox, or otherwise lay out a game's internal UI.
- Change Compact dimensions or position.
- Change code inside a separately deployed iframe game.
- Add resizing, dragging, persisted dimensions, a new display mode, or a new configuration prop.

## Decisions

1. Size Theater from four viewport edges instead of width and height caps.

   Theater will set each logical viewport inset to the larger of `0.5rem` and its corresponding physical safe-area environment value, then use automatic inline and block sizes with zero margin. Because the dialog is fixed in the top layer, definite opposing insets and automatic dimensions fill the remaining dynamic viewport rectangle. This removes the `72rem` and `42rem` caps without duplicating width and height calculations.

   Alternative considered: use `calc(100dvw - ...)` and `calc(100dvh - ...)`. That repeats edge arithmetic, is harder to keep correct for asymmetric safe areas, and adds no benefit when fixed positioning already resolves the remaining rectangle.

2. Use one Theater rule across viewport widths.

   The narrow media query will stop overriding `.dialog--theater`; it will continue to own only Compact refinements. Desktop, mobile, portrait, landscape, and resized windows will consequently share the same Theater contract and respond continuously to the dynamic viewport.

   Alternative considered: retain separate desktop and mobile rules with larger desktop percentages. Separate rules preserve an arbitrary breakpoint distinction and can drift again even though the desired behavior is identical.

3. Keep the shell format-neutral and let games consume the canvas.

   `.dialog__fullscreen` will continue to fill `100%` of the dialog. Theater will not receive an aspect ratio, intrinsic-content measurement, per-game prop, or iframe messaging protocol. Each embedded game decides whether to stretch, center, constrain, or letterbox its own content inside the available surface.

   Alternative considered: pass a preferred aspect ratio from every game. That makes the shell aware of game presentation, adds a module contract, and still cannot represent games whose layout changes with player count or viewport shape.

4. Keep simulated-DOM tests focused on observable behavior.

   Component coverage will retain the existing mode-transition, fullscreen, control-accessibility, iframe-identity, and bridge-initialization assertions. It will not assert computed CSS values, CSS class names, or presentation-only DOM structure because jsdom does not perform viewport layout and those assertions couple tests to implementation details. Real-browser inspection will cover wide and narrow dynamic viewports plus safe-area or device emulation.

   Alternative considered: add screenshot regression infrastructure for this CSS-only change. The repository does not currently configure a browser or visual test runner, so adding one would exceed the scope of the layout refinement.

## Risks / Trade-offs

- [Risk] The smaller outer gap leaves less backdrop area for pointer light dismiss. - Mitigation: preserve the explicit Compact control and Escape close-request behavior; the viewport-filling canvas is the requested priority.
- [Risk] A game can still display unused space if its own iframe layout has fixed dimensions or an incompatible aspect ratio. - Mitigation: define the shell contract as available canvas only and leave internal responsive layout with the game module that owns it.
- [Risk] Safe-area environment values are physical while the component uses logical inset properties. - Mitigation: map top, right, bottom, and left values explicitly to the application's horizontal writing mode and verify asymmetric device emulation.
- [Trade-off] Wide desktop displays may produce a very large player surface. - This is intentional: the shell stops selecting an optimal game size and exposes the available canvas to the game.

## Migration Plan

1. Retain behavioral component coverage without asserting computed styles, CSS classes, or presentation-only DOM structure.
2. Replace the current centered size caps with four safe-area-aware minimum insets and automatic dimensions.
3. Remove the narrow-viewport Theater override while leaving Compact rules unchanged.
4. Run focused frontend tests, formatting, linting, and type checks, then inspect Theater on representative wide, narrow, portrait, and landscape viewports.
5. Roll back by restoring the current base Theater dimensions, centered margin, and narrow Theater override. No backend, data, protocol, or deployment-order rollback is required.

## Open Questions

- None. The shell provides the largest safe Theater canvas, and each game remains responsible for using it.
