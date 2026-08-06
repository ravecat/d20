## Why

The local mailbox link is currently visible only in Login mode, so developers testing registration must already know the hidden development route. The shared account dialog should expose the available local delivery destination consistently in every mode.

## What Changes

- Show the local mailbox guidance whenever the server reports that the development mailbox is available, regardless of the current authentication mode or form state.
- Preserve the existing rule that no mailbox guidance is rendered when local delivery is unavailable.
- Cover the Register and Login presentations with focused browser tests.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-registration`: Require local mailbox guidance to remain visible throughout the shared account dialog instead of only in Login mode.

## Impact

- Shared Svelte authentication dialog and focused browser coverage.
- Email account registration specification and GitHub issue #193 acceptance criteria.
- No backend, route, session, persistence, dependency, migration, deployment, iframe contract, or production email-delivery change.
- Rollback restores the Login-only rendering condition; no data rollback is required.
