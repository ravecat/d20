## Why

Full-page Storybook stories currently omit the persistent application shell, so contributors cannot review routed surfaces with the same header, content boundary, and footer that Inertia users see. Page-story review should represent complete pages without changing the isolation of component and widget stories.

## What Changes

- Render every full-page Storybook story inside the production Svelte application layout.
- Display complete routed page story groups under `Pages` using their production route labels while preserving stable Storybook IDs.
- Provide deterministic Storybook-owned Inertia page context required by the shared header, footer, authentication, and workspace boundaries.
- Represent the dedicated `/users/log-in/:token` page with separate Confirmation and Reauthentication scenarios whose layout context matches the route and authentication state.
- Use the complete Home Sign In and Sign Up stories as the sole initial authentication scenarios instead of retaining duplicate standalone Login Methods and Registration Methods stories.
- Move the Magic Link Sent outcome into the complete Home page as `Sign In Sent Magic Link` instead of retaining a standalone dialog story.
- Move email-backed reauthentication into the complete Home page as `Confirmation With Magic Link`.
- Remove the remaining standalone Provider Only Reauthentication story and the now-empty Sign In authentication-dialog group.
- Move Confirmation Email Sent into the complete Home page as `Sign Up With Email` and remove the now-empty Sign Up authentication-dialog group.
- Let authentication dialogs opened from complete Home stories grow with their content and scroll as one modal surface instead of introducing a nested content scrollbar.
- Keep low-level component and widget stories outside the application layout.
- Add focused regression coverage and update the affected full-page visual references.

## Capabilities

### New Capabilities

- `storybook-page-shell`: Defines how routed page stories reuse and display the complete production application shell.

### Modified Capabilities

- `storybook-component-catalog`: Consolidates sign-in and sign-up dialog coverage in complete Home stories without detached authentication-dialog groups.

## Impact

- Tracks [GitHub issue #258](https://github.com/ravecat/d20/issues/258).
- Affects Storybook manager configuration, full-page story metadata, the shared authentication dialog, Storybook mocks, focused frontend tests, and page-story screenshot references under `assets/`.
- Reuses existing Svelte and Inertia dependencies; adds no dependency, backend behavior, migration, session/runtime contract, or iframe module contract change.
- Rollback consists of removing the shared page-story decorator and its explicit registrations from routed page stories.
