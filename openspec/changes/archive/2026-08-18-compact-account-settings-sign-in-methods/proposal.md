## Why

Account Settings currently gives unavailable providers the same visual weight as usable sign-in methods and repeats linked state in a separate status line, producing a tall dead-end list. The provider management surface should match the authentication dialog's availability rule and use both wide and narrow viewports efficiently.

## What Changes

- Omit providers from Account Settings when their runtime configuration reports them unavailable.
- Present each available provider as a compact icon-and-name item.
- Replace the secondary `Linked` or `Not linked` status line with one trailing state: a `Linked` label for linked identities or a `Link` action for unlinked identities.
- Arrange available providers in a responsive layout that stays readable and operable on mobile while using horizontal space on wide screens.
- Keep each provider item between 13 rem and 20 rem wide when space permits, sharing available row space up to that maximum and wrapping only when another minimum-width item no longer fits.
- Keep every provider on its own row through the existing 34 rem mobile breakpoint, then allow two or more items to share wider rows within the same width bounds.
- Keep wrapped provider rows aligned to one shared set of equal-width columns instead of allowing the final row to grow independently.
- Fill the inline space supplied by the application shell and stretch independent account cards that share a grid row to equal heights.
- Split each provider item into a neutral identity block and a separate same-height state control: a visually distinct `Link` control before linking or a muted non-interactive `Linked` control afterward.
- Describe an established username by its player-facing purpose without claiming that it cannot be changed.
- Update focused component coverage and the Account Settings Storybook fixtures for linked, unlinked, unavailable, desktop, and mobile inspection.

## Capabilities

### New Capabilities

- `account-settings-provider-management`: Define the availability, linked-state presentation, provider identity cues, actions, and responsive behavior of external sign-in methods in Account Settings.

### Modified Capabilities

- `email-account-login`: Stop presenting unavailable Discord as an Account Settings row while preserving availability-derived linking and durable linked-state behavior.
- `username-account-identity`: Keep established-username presentation factual without exposing the current claim operation's immutability as permanent product copy.

## Impact

- Affects the Account Settings Svelte page, its scoped styling, focused component tests, and Account Settings Storybook stories.
- Preserves provider props, routes, full-document linking navigation, controller behavior, stored identities, and authentication contracts.
- Adds no dependency, migration, session change, iframe contract change, or production configuration change.
- Tracks GitHub issue [#213](https://github.com/ravecat/d20/issues/213).
