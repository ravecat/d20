## Why

daisyUI generates a root `scrollbar-color` whose track is fully transparent. When the application renders in a surface with a mismatched background — the white Storybook preview iframe under a forced-dark browser is the observed case — the transparent classic scrollbar track lets the surrounding surface color bleed through. The scrollbar then reads as a light stripe over the dark theme, so the visible scrollbar no longer follows the active application theme.

Runtime controls in Brave on Linux verified the cause:

- `:root` computed `scrollbar-color` resolves to a themed thumb over a transparent track (`oklch(0.97807 0.029 256.847 / 0.35) rgba(0, 0, 0, 0)`).
- The Storybook preview iframe element has a white background.
- Giving the root an explicit theme-derived track removes the stripe.
- Changing only the iframe background, with the dark theme and transparent scrollbar untouched, also removes the stripe.

The stripe is therefore not caused by the browser selecting the dark scheme; it is a transparent track leaking the embedding context's background.

Owning issue: https://github.com/ravecat/d20/issues/245

## What Changes

- Override the daisyUI root scrollbar declaration in `assets/css/app.css` with an explicit `scrollbar-color` that derives both colors from the active theme tokens.
- The track becomes `var(--color-base-100)`; the thumb keeps the established contrast by mixing `var(--color-base-content)` at 35% with transparent.
- No user-agent inspection, browser detection, JavaScript, or environment-specific branching.

## Capabilities

### New Capabilities

- `global-scrollbar-theming`: Root scrollbar colors follow the active application theme in every rendering context, without context detection.

### Modified Capabilities

None.

## Impact

- One declaration block in `assets/css/app.css` after the daisyUI theme definitions.
- Affects the root scrollbar rendering in production pages, Storybook previews, and embedded iframe/WebView contexts on platforms that paint classic scrollbars.
- No component structure, JavaScript, public protocol, persistence, session, migration, or deployment behavior changes.
- Overlay-scrollbar platforms (macOS, mobile) are unaffected because they paint no persistent track.
- `forced-colors` accessibility overrides remain owned by the browser.
- Rollback removes the single declaration block and restores the daisyUI default.
