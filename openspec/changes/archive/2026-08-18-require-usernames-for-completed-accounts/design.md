## Context

The username registration-completion change preserved an Account Settings state for confirmed users without usernames because older production data might have existed. D20 now has no production users. Magic Link, Google, Discord, and Apple registration all require a valid unique username before they authenticate a new account.

This change is tracked by GitHub issue #216 and supersedes the legacy-account compatibility criteria from #192. Unconfirmed email registrations still need a temporary row containing an email and no username until the email owner completes registration. Provider registration keeps pending provider data outside the user table until completion.

## Goals / Non-Goals

**Goals:**

- Model only account states reachable through current registration and authentication flows.
- Preserve the temporary unconfirmed email-registration state without a username.
- Remove the authenticated username claim surface and email-as-display-name compatibility behavior.
- Keep username format, case-insensitive uniqueness, immutability, and registration-completion behavior unchanged.

**Non-Goals:**

- Add username changes, generation, reservation before email proof, or migration-time backfill.
- Add database constraints or duplicated authentication checks for malformed states current product flows cannot create.
- Change email, password, Magic Link, or provider authentication choices.
- Migrate production account data, because no production users exist.

## Decisions

### Treat registration completion as the lifecycle boundary

Email registration may insert an unconfirmed user without a username. Opening the valid Magic Link renders the registration-completion page, and submitting that page validates and assigns username while confirming the same user in one transaction. No session is created before that transaction succeeds.

Provider authentication keeps pending registration state in the server session or signed provider flow state. It inserts the user, username, confirmation time, and provider identity atomically only after the completion form succeeds.

These are the only supported account-creation paths. Tests will cover these reachable transitions instead of constructing confirmed users without usernames.

### Do not encode unreachable compatibility states at every boundary

No relational check constraint will connect `confirmed_at` and `username`. Authentication queries and session token functions will not repeat username-presence guards solely for a state current registration controllers cannot produce. Username remains nullable because the incomplete email-registration row is real.

This deliberately favors the smallest implementation over defense against direct SQL, manually constructed structs, or hypothetical future flows. A future registration method must preserve the existing completion-before-authentication lifecycle and add its own flow tests.

### Remove compatibility instead of hiding it

Remove `Accounts.claim_username/2`, the Account Settings controller action and form, the nullable Svelte prop, the public profile email fallback, and legacy fixtures and tests. Account Settings receives and displays one required immutable username. Storybook keeps provider-state coverage but removes the missing-username story.

The reusable username changeset remains the validation boundary for Magic Link and provider registration. Username format and database-backed case-insensitive uniqueness remain unchanged.

### Reconcile the active Apple Storybook artifacts

The active Apple change introduced the current Account Settings story and still says username claiming must be inspectable. Its Storybook delta and design will describe only the established username plus provider availability and linking states.

## Risks / Trade-offs

- [A future backend flow confirms or authenticates before assigning username] -> That flow could create an unsupported state because no relational constraint catches it; its implementation must reuse registration completion and add lifecycle tests.
- [Removing the claim operation breaks an unknown client] -> Account Settings is the only current caller, and there are no production users or documented external clients for this private form action.
- [Malformed development data is inserted directly] -> It is outside supported product flows and may fail when projected as an authenticated profile.

## Migration Plan

1. Remove the experimental username check migration and its Ecto mapping.
2. Remove duplicated authentication hardening added for confirmed users without usernames.
3. Keep the claim API, settings state, profile fallback, fixtures, tests, and story removed.
4. Run focused backend and frontend tests, static checks, Storybook build, and `just check`.
5. No production data migration or database rollback is required.

## Open Questions

None. The absence of production users and the registration-before-authentication username requirement are explicit product constraints for issue #216.
