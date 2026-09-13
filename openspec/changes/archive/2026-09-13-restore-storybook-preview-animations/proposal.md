## Why

Storybook's shared motion suppression and Workspace cancellation prevent contributors from inspecting real animated behavior. Home's four-entry default fixture also produces only one hero card, which correctly disables hero cycling even after suppression is removed. Restore motion and provide enough default Home data to demonstrate it while retaining stable state screenshots through the existing Storybook, Vitest, and Playwright test pipeline.

Tracking: [D20 #284](https://github.com/ravecat/d20/issues/284), under [#158](https://github.com/ravecat/d20/issues/158).

## What Changes

- Remove the shared preview stylesheet that disables animations, transitions, and smooth scrolling, together with its import.
- Remove the four document-wide animation cancellation loops from Workspace stories while preserving their state setup and interaction assertions.
- Use the existing 32-entry `homeBrowseGames` fixture for public and authenticated Home defaults so their hero can cycle; retain explicit small-data, empty, and favorites scenarios.
- Keep the existing screenshot hook, font readiness, timeout, visual matrix, and provider defaults.
- Replace the catalog's no-motion requirement with interactive production motion and standard automated screenshot stabilization; document the distinction and the installed Storybook theme/completion waiting limitation.
- Review visual differences before updating any affected screenshot baselines.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `storybook-component-catalog`: Preserve production CSS motion during interactive story browsing, demonstrate Home hero cycling with representative default data, and use the existing test pipeline for stable screenshots of configured story states.

## Impact

- Frontend catalog: `assets/.storybook/preview.ts`, removal of `assets/.storybook/preview.css`, `assets/stories/widgets/workspace.stories.ts`, and both public and authenticated `assets/stories/pages/*/home.stories.ts` files.
- Contributor guidance: the relevant Storybook documentation; existing visual baselines only if reviewed differences require updates.
- No production stylesheet, dependency, backend, persistence, session, route, or iframe contract changes. No migration or deployment is required.
- This intentionally reverses the preview suppression introduced for #266. Storybook 10.5.7 may again wait for its animation completion fallback on finite scroll timelines, including during theme changes. Eliminating that upstream wait is outside this change.
- Rollback is a revert of this delivery and any associated baseline changes.
