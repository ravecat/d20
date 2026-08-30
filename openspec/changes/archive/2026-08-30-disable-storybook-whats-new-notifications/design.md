## Context

The catalog already defines Storybook core options in `assets/.storybook/main.ts`, including telemetry and onboarding behavior. Storybook's What's New toast has its own supported core option and is independent from telemetry, so browser-local dismissal does not provide a repository-wide result.

## Goals / Non-Goals

**Goals:**

- Suppress the built-in What's New toast for every contributor using the maintained catalog.
- Use Storybook's typed supported configuration and preserve all existing catalog behavior.

**Non-Goals:**

- Hide application or addon notifications.
- Change telemetry, onboarding, manager layout, addons, stories, or runtime application behavior.
- Add custom manager code, CSS, or browser-storage manipulation.

## Decisions

### Use the Storybook core notification option

Set `core.disableWhatsNewNotifications` to `true` beside the existing `core.disableTelemetry` option. Storybook reads this option before scheduling the development-only What's New notification, so the behavior is consistent across browsers and does not depend on local dismissal state.

Changing `manager.ts`, hiding the toast with CSS, or writing Storybook's internal cache was rejected because those approaches depend on internal presentation or storage details and would leave the notification machinery active.

### Validate through the typed configuration and static build

Run frontend formatting and the static Storybook build. The typed `StorybookConfig` object and build exercise the supported option without introducing a custom test for third-party Storybook internals.

## Risks / Trade-offs

- [Risk] Contributors no longer receive Storybook release announcements in the catalog -> Mitigation: dependency updates and release notes remain available through the normal maintenance workflow.
- [Risk] A future Storybook release removes or renames the option -> Mitigation: TypeScript checks and the required static catalog build fail during the dependency update.

## Migration Plan

No migration or deployment sequencing is required. Apply the configuration setting and rebuild Storybook. Rollback removes the setting and restores Storybook's default notification behavior.

## Open Questions

None.
