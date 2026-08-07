## Context

The game detail page, app header, and app footer each own a `64rem` bounded inner box. Before commit `4ba5bad`, all three applied `1.5rem` inline padding, reduced to `1rem` at the existing `48rem` breakpoint. That commit removed both declarations from `game.svelte`, inverted the layout variants, and made the new `wide` header and footer selectors set `padding-inline: 0`. It also replaced the wide layout browser fixture with zero-padding content, so the test proved that three flush edges aligned without proving that the required gutter remained.

## Goals / Non-Goals

**Goals:**

- Restore the accepted narrow and wide page-edge insets as local game detail geometry.
- Align the wide header, main content, and footer to one shared visual gutter.
- Make both responsive values observable in the existing Chromium and Firefox browser tests.
- Preserve the current zero block-start padding, panel-owned geometry, layout gaps, and activation behavior.

**Non-Goals:**

- Reintroducing a global app-shell padding custom property.
- Changing the geometry of default narrow-layout pages.
- Redesigning safe-area behavior, preview sizing, panel padding, or the `48rem` breakpoint.
- Changing header authentication behavior, routes, session creation, backend behavior, or iframe game contracts.

## Decisions

### 1. Restore component-scoped logical padding

The game detail shell will again declare `padding-inline: 1.5rem`, with the existing `max-width: 48rem` media query overriding it to `1rem`. This restores the established breakpoint contract directly where the page owns its geometry and preserves writing-mode-aware symmetry.

Using an app-shell custom property or layout variant was rejected because these are ordinary local values and would turn page-specific geometry into a shared override contract. A fluid `clamp()` value was rejected because the accepted behavior uses two exact values at the existing layout breakpoint.

### 2. Keep wide header and footer width and padding responsibilities separate

The `wide` header and footer selectors will continue to select the `64rem` maximum inner width, but will use `1.5rem` inline padding above `48rem` and an explicit `1rem` override at and below the breakpoint. The base narrow variants keep their existing `46.25rem` maximum width and `1rem` padding at all sizes. Repeating these ordinary local values follows the established component ownership from #196 and avoids recreating a global override contract.

Removing padding from the wide selectors without a replacement was rejected because it would leave wide desktop chrome at `1rem` while game content uses `1.5rem`. Changing all pages to `1rem` was rejected because it would alter the accepted game detail geometry from #166.

### 3. Extend the existing real-browser geometry tests

The focused game browser test will continue comparing the shell and preview edges at `412px` and `1280px`. The app layout browser test will render the `wide` variant at both viewports and compare the accessible D20 brand, Register action, main fixture content, and developer footer link against the same `16px` or `24px` content edges. The current preview-to-shell, panel sizing, compact header, and gap assertions remain in place to guard against adjacent regressions.

A CSS-source assertion was rejected because it would not prove the browser applies the correct box-model geometry at the breakpoint.

## Risks / Trade-offs

- [The browser test could observe a body margin instead of component spacing] -> The test setup already removes document margin globally, and the assertion measures the shell against its immediate rendered container on both sides.
- [Restoring padding reduces the preview's content width] -> This is the previously accepted geometry and is verified at both layout modes.
- [The more specific wide selector could override the mobile inset again] -> Add an equally specific mobile override and exercise the `wide` variant at a real `412px` viewport.
