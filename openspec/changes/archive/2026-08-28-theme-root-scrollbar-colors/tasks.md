## 1. Implementation

- [x] 1.1 Override the root `scrollbar-color` in `assets/css/app.css` with `color-mix(in oklch, var(--color-base-content) 35%, transparent) var(--color-base-100)` after the daisyUI theme definitions.

## 2. Validation

- [x] 2.1 Verify in a real browser that the dark theme inside a light embedding surface renders a themed scrollbar track with no embedding background visible through it.
- [x] 2.2 Verify in a real browser that the light theme and explicit `data-theme` overrides resolve both scrollbar colors from the active theme tokens.
- [x] 2.3 Run frontend formatting, lint, typecheck, and tests for the touched stylesheet area and update visual references if any capture root scrollbar pixels.
- [x] 2.4 Run strict OpenSpec validation for the change and all repository artifacts.
