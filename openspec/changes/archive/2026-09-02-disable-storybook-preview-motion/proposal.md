## Why

Storybook waits its full five-second animation timeout before applying a theme toolbar change because the production header exposes scroll-driven animations that remain running on an idle scroll timeline. Isolated review and visual testing do not need production motion, so the preview should render deterministic final states without delaying contributor feedback.

## What Changes

- Disable CSS animations and transitions throughout the Storybook preview while leaving production application rendering unchanged.
- Force preview scrolling to use immediate behavior so interaction and visual checks do not depend on smooth-scroll timing.
- Preserve dedicated real-browser coverage for production animation behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `storybook-component-catalog`: Require Storybook previews to suppress motion so toolbar globals, interaction completion, accessibility inspection, and visual snapshots do not wait for production animation timelines.

## Impact

- Affects Storybook preview configuration and Storybook-only CSS under `assets/.storybook/`.
- Does not change production CSS, routes, public APIs, dependencies, persistence, session runtime behavior, migrations, or iframe module contracts.
- Rollback removes the Storybook-only stylesheet import and restores production motion inside previews, including the existing five-second theme-switch delay.
