## Why

Storybook previews inherit the browser's `prefers-color-scheme` because the daisyUI themes select automatically and the preview root carries no explicit `data-theme`. A browser that forces a dark preference — the observed case is Brave with `browser.theme.color_scheme` set to Dark — silently renders every story in the dark theme. The only way to inspect the light theme is to change the browser's own appearance setting, which is outside the Storybook workflow and affects unrelated tabs.

daisyUI already supports explicit theme selection through `data-theme`, and the repository's global scrollbar theming follows whatever theme is active. What is missing is a Storybook-side control that drives that attribute inside the preview iframe.

Owning issue: https://github.com/ravecat/d20/issues/246

## What Changes

- Add the official `@storybook/addon-themes` at the repository's Storybook version and register it in Storybook configuration.
- Configure `withThemeByDataAttribute` in the preview to expose the existing daisyUI theme names `light` and `dark` on `data-theme` through the Storybook toolbar.
- Make the preview default deterministic (`light`) so a forced browser dark preference no longer decides how stories render.

## Capabilities

### New Capabilities

- `storybook-theme-toolbar`: The Storybook toolbar switches the preview between the application's supported themes and the preview theme is deterministic by default.

### Modified Capabilities

None.

## Impact

- `assets/package.json` and the lockfile gain the `@storybook/addon-themes` dev dependency.
- `assets/.storybook/main.ts` registers the addon.
- `assets/.storybook/preview.ts` adds the decorator and an explicit initial theme global; existing viewport options, viewport `initialGlobals`, controls, stories, and addons are unchanged.
- Production pages, game modules, channels, projections, and persistence are unaffected.
- Visual regression captures that depend on the automatic theme may need regeneration where the preview default changes from automatic to light.
