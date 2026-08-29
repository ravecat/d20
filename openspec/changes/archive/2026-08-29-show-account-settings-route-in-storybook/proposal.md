## Why

Page story groups should mirror their production routes inside the existing `Pages` hierarchy so contributors can discover routed surfaces consistently. GitHub issue [#257](https://github.com/ravecat/d20/issues/257) tracks displaying ordinary route punctuation without changing Storybook hierarchy or story IDs.

## What Changes

- Keep the home and Account Settings internal titles as `Pages/∕` and `Pages/∕settings` so Storybook creates the required hierarchy.
- Render U+2215 DIVISION SLASH as ASCII `/` in Storybook sidebar labels, producing `/` and `/settings` under `Pages`.
- Preserve the existing scenarios, generated IDs, production components, fixtures, and runtime behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `storybook-component-catalog`: Display Home and Account Settings with ordinary route labels under `Pages` while retaining Storybook-safe hierarchy metadata and stable story IDs.

## Impact

- Affects `assets/.storybook/manager.ts`, the two page story titles, and Storybook catalog navigation.
- Does not change production routes, APIs, dependencies, persistence, sessions, migrations, iframe contracts, visual story output, or application runtime behavior.
- Rollback removes the label renderer and restores the previous Storybook titles.
