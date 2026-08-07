## Context

`AuthDialog` is a native modal whose element owns the visible surface, common padding, and a nested content scroller. Its first mobile implementation made the surface edge-to-edge. The expanded workspace game window instead keeps a half-rem safe-area-aware inset, which preserves a visible relationship between the floating surface and the page behind it. The auth title row currently centers the close action on the row's cross axis, so a two-line title pushes the action below the title's top edge.

The frontend browser policy is Baseline Widely Available. Dynamic viewport units and `env(safe-area-inset-*)` therefore fit the existing support boundary without a script-based viewport measurement fallback.

## Goals / Non-Goals

**Goals:**

- Fill most of the available mobile dynamic viewport while preserving a small visible outer inset.
- Keep the dialog surface outside device safe areas and preserve the existing one-rem mobile content inset.
- Keep long Register and Login content reachable through the existing internal scroller.
- Keep the close action aligned with the top of the title when the title spans multiple lines.
- Preserve the centered, content-sized desktop dialog without changing markup, focus, or auth state.

**Non-Goals:**

- Invoke the Fullscreen API or hide browser navigation UI.
- Change the mobile breakpoint, account content, focus lifecycle, light dismissal, or form behavior.
- Add JavaScript viewport measurements, resize listeners, or a second scrolling surface.

## Decisions

### Match the expanded game window's outer inset contract

At `max-width: 34rem`, position each dialog edge with the greater of `0.5rem` and its corresponding `safe-area-inset-*` value. With all four logical insets resolved, automatic inline and block sizes fill the remaining dynamic viewport. Retain the base border, radius, and shadow so the backdrop remains visible around a clearly bounded dialog surface.

The alternative was a second mobile wrapper or conditional component branch. That would duplicate surface and accessibility ownership for a layout change that CSS can express directly.

### Keep content padding separate from viewport safety

The dialog's outer fixed insets own safe-area avoidance. Its existing one-rem mobile padding remains a local content inset, avoiding doubled safe-area spacing inside the surface.

The alternative was keeping safe-area values in content padding. That protects controls but leaves the dialog surface itself under a notch and does not guarantee the requested visible outer reveal.

### Top-align the title row

Change the title row's cross-axis alignment from centered to flex-start. The close button remains at the inline end through `justify-content: space-between`, but its top edge now stays aligned with the first line of a one-line or wrapping title.

The alternative was a mobile-only offset on the close button. That would encode one observed title height instead of fixing the flex alignment that causes the drift.

### Retain the existing nested content scroller

The title, description, notices, and close action stay in the non-scrolling panel header area while `.auth-panel__content` remains the single `overflow-y: auto` region for mode-specific actions. The dialog and panel flex constraints already allow that region to shrink within a definite viewport block size.

The alternative was scrolling the native dialog element. That would move the title and close action out of view and introduce a second responsive scrolling contract.

## Risks / Trade-offs

- [A mobile virtual keyboard reduces the visible viewport] - `100dvb` follows the dynamic viewport and the existing content scroller keeps obscured controls reachable.
- [A notch or home indicator overlaps the surface] - each outer edge uses the greater of the half-rem visual inset and the corresponding device safe area.
- [The full-height surface can look sparse in short Register states] - content remains top-aligned by design, matching a mobile page surface rather than vertically stretching controls.
- [Desktop layout regresses through cascade changes] - keep all new overrides inside the existing `34rem` media query and retain the current desktop browser assertions.
