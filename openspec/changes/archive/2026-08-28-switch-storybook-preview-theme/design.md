# Storybook Theme Toolbar

## Context

- The Storybook setup lives in `assets/.storybook/` (`main.ts`, `preview.ts`, `manager.ts`) with stories under `assets/stories/`.
- `assets/css/app.css` defines exactly two daisyUI themes — `light` (default) and `dark` (`prefersdark: true`) — and the root scrollbar colors derive from the active theme tokens.
- `manager.ts` only configures manager UI layout; the preview iframe is where application CSS applies.
- The repository uses Storybook 10.5.x for all Storybook packages, and dev dependencies are pinned or caret-matched to that line.
- The Storybook addon essentials used by the repository (`addon-docs`, `addon-a11y`, `addon-vitest`) are registered in `main.ts`.

## Goals / Non-Goals

Goals:

- The Storybook toolbar exposes the application's supported daisyUI themes (`light`, `dark`).
- Selecting a theme applies `data-theme` inside the preview so CSS variables, `color-scheme`, root background, and root scrollbar all follow it.
- The preview theme is deterministic by default and does not depend on the browser's `prefers-color-scheme`.
- Existing Storybook configuration (viewport, controls, addons, stories) is preserved.

Non-Goals:

- Changing the manager UI's own theme.
- Adding an application-level runtime theme switcher or persisting user theme choice in the product.
- Changing how production pages select their theme.
- Adding new daisyUI themes.

## Decisions

### Use `@storybook/addon-themes` with `withThemeByDataAttribute`

It is the official, supported addon for this exact case. `withThemeByDataAttribute` sets the chosen value on the preview's story container element, and daisyUI themes already respond to `[data-theme]` selectors, so no custom decorator, matchMedia handling, or JavaScript in application code is needed.

`withThemeByDataAttribute` writes `data-theme` on `document.querySelector(parentSelector)` inside the preview iframe, and its default `parentSelector` is `html` — the preview root element itself. daisyUI theme variables, `color-scheme`, and the repository's `:root` scrollbar override therefore all follow the toolbar selection, and the `:root:not([data-theme])` automatic rule no longer matches because the attribute is always present. No custom `parentSelector` is needed.

### Default theme: `light`

`light` is the daisyUI default theme in this repository (`default: true`) and the automatic choice whenever the browser does not force dark. Making it the Storybook default removes the silent dependence on a forced browser dark preference and keeps previews reproducible across developer machines and CI. The toolbar still allows switching to `dark` at any time, and a story can pin a theme through the `theme` global when a scenario requires it.

### Addon version

`@storybook/addon-themes@^10.5.7` matches the repository's Storybook line. Version drift between Storybook core and addons is a known source of manager/preview incompatibilities, so the addon stays on the same line.

## Risks / Trade-offs

- Visual regression captures taken under a forced-dark browser now render light by default. Any baseline whose pixels include theme-driven colors must be regenerated once; this is a one-time deterministic improvement.
- The Storybook `theme` global persists in the toolbar per session; stories that assume automatic theme selection should pin their theme explicitly rather than rely on the browser preference.
- If daisyUI gains additional themes, the toolbar map must be extended; the mapping is intentionally explicit instead of generated.

## Migration Plan

1. Add the dev dependency and register the addon.
2. Add the decorator and initial theme global to the preview config.
3. Verify both themes through the toolbar in a real browser under a forced-dark browser preference.
4. Regenerate visual baselines if any reference depends on the previously automatic theme.

## Open Questions

None.
