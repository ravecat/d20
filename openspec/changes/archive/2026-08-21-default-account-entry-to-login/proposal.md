## Why

The guest header currently presents `Register` as D20's primary account action and opens the shared dialog in Register mode. Returning players therefore encounter registration language before login, which also makes the existing provider sign-in and unknown-identity registration transition harder to understand.

The uncommitted Account Settings provider-props refactor belongs to this same account-entry feature and remains part of its delivery scope.

## What Changes

- **BREAKING** Replace the guest header's `Register` action with `Log in`.
- Make a clean shared account-dialog opening start in Login mode, including the main and overlay header variants.
- Keep Register mode reachable through the existing `Create account` switch inside Login mode without navigation.
- Preserve server-prompted login and reauthentication behavior, authenticated header actions, provider availability, provider callback semantics, and account security boundaries.
- Retain the completed Account Settings refactor that replaces provider-specific page props with one ordered server-shaped provider collection containing stable identifiers, names, availability, durable linked state, and Phoenix-verified link URLs.
- Update auth-store and browser coverage for the login-first account entry, then revalidate the combined delivery.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Make Login the default guest account entry from the shared header while retaining explicit in-dialog switching to Register mode.
- `account-settings-provider-management`: Define one ordered server-shaped provider collection as the Account Settings presentation contract while preserving existing visibility and interaction behavior.

## Impact

- Tracks [GitHub issue #218](https://github.com/ravecat/d20/issues/218), reclassified as the owning Feature.
- Frontend account entry: changes the shared auth store default state, guest header action and styling names, and focused store and browser tests.
- Backend and Account Settings frontend: retains the already implemented provider collection contract, verified routes, local icon mapping, tests, and Storybook fixtures.
- Compatibility: changes guest-visible default account entry but does not change authentication endpoints, provider callback behavior, credentials, identity ownership, sessions, database schemas, public game contracts, iframe contracts, channels, or AsyncAPI.
- Dependencies and migrations: none.
- Rollback: restore Register as the header action and the auth-store registration default together; restore provider-specific Account Settings props only if the supporting refactor is also rolled back.
