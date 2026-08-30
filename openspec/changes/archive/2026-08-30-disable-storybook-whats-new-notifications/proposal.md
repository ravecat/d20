## Why

Storybook's built-in What's New notification reappears during catalog reloads, obscures the sidebar, and interrupts routine component review. The catalog should opt out through Storybook's supported project configuration instead of depending on each browser's dismissal state.

## What Changes

- Disable Storybook What's New notifications for the maintained catalog.
- Preserve the existing telemetry, onboarding, manager layout, addons, stories, and build behavior.
- Validate the configuration through frontend formatting and the static Storybook build.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `storybook-component-catalog`: Require the interactive catalog to suppress Storybook's built-in What's New notifications during contributor workflows.

## Impact

- `assets/.storybook/main.ts` gains the supported `core.disableWhatsNewNotifications` setting.
- No application runtime, public API, route, persistence, session, iframe module contract, dependency, or migration changes are required.
- Rollback removes the setting and restores Storybook's default notification behavior.
- Tracks [GitHub issue #262](https://github.com/ravecat/d20/issues/262).
