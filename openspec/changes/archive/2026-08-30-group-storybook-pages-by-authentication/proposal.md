## Why

Complete page stories currently share one flat `Pages` hierarchy even though D20 exposes distinct public and authenticated application surfaces. The catalog should make that access boundary visible and avoid grouping impossible public and authenticated states under the same page metadata.

## What Changes

- Group complete page stories under `Pages/Public` or `Pages/Authenticated` according to the authentication state required to display them.
- Split Home and Magic Link confirmation metadata so their public and authenticated scenarios appear in the correct hierarchy without duplicating production components.
- Keep sign-in, sign-up, signed-out confirmation, and registration completion states public-only.
- Keep Account Settings and reauthentication states authenticated-only.
- Preserve deterministic application-shell rendering, route labels, existing public story IDs where one metadata group can retain them, and isolated shared/widget stories.
- Update focused metadata coverage and visual references affected by the story-file split.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `storybook-component-catalog`: Organize complete page stories by public or authenticated application surface.
- `storybook-page-shell`: Keep split public and authenticated page metadata on the production shell with matching deterministic authentication context.

## Impact

- Tracks [GitHub issue #260](https://github.com/ravecat/d20/issues/260).
- Affects Storybook page sources, focused frontend metadata tests, and visual-regression references under `assets/`.
- Adds no dependency and changes no production route, runtime behavior, public API, persistence, session contract, migration, or iframe module contract.
- Rollback restores the previous flat `Pages` metadata and matching visual-reference paths.
