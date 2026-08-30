## 1. Storybook Configuration

- [x] 1.1 Enable `core.disableWhatsNewNotifications` in the maintained Storybook configuration without changing existing core or manager behavior.

## 2. Validation

- [x] 2.1 Run frontend formatting, type checking, and the static Storybook build.
- [x] 2.2 Verify that the loaded Storybook configuration disables What's New notifications, preserves telemetry suppression, and starts the existing development catalog successfully.

## 3. Completion

- [x] 3.1 Validate the change and all OpenSpec artifacts strictly, reconcile the specification and issue evidence, and archive the completed change.

## Validation Evidence

- `mix assets.format.check`, `mix typecheck`, and `mix assets.storybook` passed.
- A Bun configuration assertion loaded `disableTelemetry: true` and `disableWhatsNewNotifications: true` from `.storybook/main.ts`.
- The development catalog started successfully and served HTTP on port 6006 before its task-owned process was stopped. No separate manual browser inspection was required for the supported Storybook core option.
