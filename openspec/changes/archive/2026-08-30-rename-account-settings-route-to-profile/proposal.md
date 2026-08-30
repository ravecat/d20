## Why

Account Settings is the player's profile surface, but its current `/users/settings` route family and `/settings` Storybook label describe implementation history rather than the user-facing destination. Renaming the complete family to `/profile` gives the application and catalog one concise, consistent route identity before the unpublished Storybook organization work is released.

## What Changes

- **BREAKING** Replace `GET` and `PUT /users/settings` with `GET` and `PUT /profile` without compatibility redirects.
- **BREAKING** Move email confirmation from `/users/settings/confirm-email/:token` to `/profile/confirm-email/:token`.
- **BREAKING** Move every provider-link start route from `/users/settings/auth/:provider` to `/profile/auth/:provider`.
- Update application links, redirects, stored return destinations, Apple link-result cookie scope, tests, fixtures, and specifications to use `/profile` as the only Account Settings route family.
- Display Account Settings as `/profile` under `Pages/Authenticated` in Storybook while preserving the established `pages-settings` component ID and child story identities.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `email-account-login`: Make `/profile` and its nested confirmation/provider routes the authoritative Account Settings journey and remove the old route family.
- `storybook-component-catalog`: Rename the authenticated Account Settings route-like catalog label and rendered page URL to `/profile` while preserving story identities.

## Impact

- Phoenix router and account/provider controllers change public browser paths and redirect destinations.
- Apple link-result cookie scope changes from `/users/settings` to `/profile`; cookies scoped to the old path are intentionally not migrated.
- Svelte links, Inertia form actions, authentication return targets, Storybook fixtures, controller/frontend tests, and visual baselines change.
- Main and active OpenSpec artifacts that currently name `/users/settings*` must be reconciled under GitHub issue #260.
- No database migration, game/session contract, iframe contract, dependency, or deployment configuration change is required. Rollback requires reverting the route family and all generated links together.
