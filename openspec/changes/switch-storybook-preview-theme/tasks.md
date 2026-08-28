## 1. Implementation

- [x] 1.1 Add `@storybook/addon-themes` at the repository's Storybook version to `assets/package.json` and the lockfile.
- [x] 1.2 Register `@storybook/addon-themes` in `assets/.storybook/main.ts` while preserving the existing addons.
- [x] 1.3 Configure `withThemeByDataAttribute` in `assets/.storybook/preview.ts` for the daisyUI theme names `light` and `dark` on `data-theme`, with `light` as the default, so the selected theme reaches the preview root for CSS variables, `color-scheme`, and root scrollbar colors.

## 2. Validation

- [x] 2.1 Verify in a real browser under a forced-dark `prefers-color-scheme` that the default preview renders the light theme.
- [x] 2.2 Verify in a real browser that selecting `dark` through the toolbar switches `data-theme`, resolved theme CSS variables, `color-scheme`, root background, and root scrollbar colors without changing the browser's `prefers-color-scheme`.
- [x] 2.3 Run focused frontend formatting, lint, typecheck, and test commands and regenerate visual references if any capture depends on the previously automatic theme.
- [x] 2.4 Run strict OpenSpec validation for the change and all repository artifacts.
