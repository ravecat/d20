## Why

The current uncommitted implementation groups authentication facts under one global Inertia `auth` prop, but account-dialog workflow state is split between Header props and AuthDialog-local runes. This overloads `mode` as both an opening source and a mutable view choice, requires an intentionally untracked snapshot, and makes resets implicit. One small event-driven store can own the dialog session while Page remains authoritative for server authentication facts.

## What Changes

- **BREAKING** Replace the internal flat `authenticated`, `authPrompt`, and `localMailboxAvailable` Inertia props with one required `auth` object.
- Require `auth` to contain boolean `authenticated`, nullable `prompt`, and boolean `local` fields on every Inertia page.
- Configure the shared Inertia TypeScript contract globally so Svelte consumers use `usePage()` without component-local auth prop declarations.
- Let the account dialog read `auth.local` directly instead of receiving a forwarded mailbox-availability prop.
- Centralize the shared account-dialog workflow in one directly imported `auth` XState Store singleton, with the server prompt bridged from the reactive Inertia Page and captured for the lifetime of the requested dialog.
- Preserve one-time prompt consumption, prompt payloads, local-mailbox availability rules, routes, account actions, and session behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Define the grouped global Inertia auth object and use its nested authentication and prompt values for login and sudo dialog behavior.
- `email-account-registration`: Derive shared-header guest state and local-mailbox guidance from the grouped global auth object.

## Impact

- Phoenix Inertia pipeline and `D20Web.UserAuth` shared-prop publication.
- Global frontend Inertia typing, App header, shared account dialog, auth UI store, Inertia test mock, and focused backend, store, and browser coverage.
- Add the official `@xstate/store-svelte` binding for reactive selection from the existing XState Store model.
- Internal Inertia page prop names change without a compatibility alias; no external HTTP route, form payload, Accounts contract, session key, persistence schema, dependency, migration, deployment procedure, or iframe module contract changes.
- Rollback restores the former flat props and mailbox prop forwarding; no data rollback is required.
