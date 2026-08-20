## Why

Google, Facebook, Apple, and Discord authentication all need the same durable mapping from an external provider identity to the D20 user that owns it. Establishing that provider-independent boundary first keeps Ueberauth callback data out of the account model and lets provider-specific work build on database-enforced ownership rules.

## What Changes

- Add durable external identity records for the supported providers without storing provider tokens, raw claims, email, or profile data.
- Add `D20.Accounts` operations to link an identity to an existing user, list a user's identities, and resolve a user from a provider identity.
- Enforce that a provider identity has one D20 owner and that a D20 user has at most one identity for each provider.
- Delete identity records when their owning user is deleted.
- Add focused schema, context, constraint, and lifecycle tests.
- Keep Ueberauth dependencies, callback handling, D20 session creation, provider-based registration, unlinking, and UI behavior outside this change.

## Capabilities

### New Capabilities

- `external-provider-identity-foundation`: Provider-independent persistence and account-context behavior for linking and resolving external identities.

### Modified Capabilities

None.

## Impact

- Database: adds a `user_identities` table, indexes, constraints, and a cascading foreign key to `users`.
- Backend: adds `D20.Accounts.UserIdentity`, a `User` association, and public functions in `D20.Accounts`.
- Dependencies and web behavior: unchanged. No provider SDK, Ueberauth strategy, route, controller, session, or frontend behavior is introduced.
- Runtime compatibility: existing email registration, password and magic-link login, sessions, and iframe game contracts remain unchanged.
- Rollback: the migration can drop the new table without modifying existing user rows, but any identity links created after deployment would be lost.
