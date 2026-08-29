## Why

The production home page is absent from Storybook, so its game-catalog layout and lifecycle states cannot be reviewed in isolation or covered by the existing story-driven visual checks. GitHub issue [#255](https://github.com/ravecat/d20/issues/255) tracks this delivery.

## What Changes

- Add a typed deterministic Storybook story for the production Svelte home page.
- Identify the story group with the route-like title `∕`, using the Unicode division slash because Storybook reserves `/` as a hierarchy separator.
- Represent released, in-development, and planned catalog entries without a live Phoenix boundary.
- Add the visual baselines required by the repository's automatic Storybook regression checks.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `storybook-component-catalog`: Require the home page to be inspectable through a deterministic route-titled story.

## Impact

- Affects Storybook sources and generated visual-regression baselines under `assets/`.
- Does not change production routes, runtime behavior, public APIs, persistence, sessions, migrations, iframe contracts, or dependencies.
- Rollback consists of removing the story and its matching baselines.
