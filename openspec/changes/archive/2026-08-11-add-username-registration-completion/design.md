## Context

Email registration currently inserts an unconfirmed passwordless `users` row, renders a GET confirmation page from the magic-link token, and confirms the email plus creates the first session on a subsequent POST. Users have no username, password login accepts only email, and the shared actor profile uses email as `display_name`. Existing production-shaped data can therefore contain confirmed users with passwords or external identities but no username.

The confirmation GET must remain non-mutating so mail scanners cannot confirm an account or reserve a username. Username reservation also has a race at the database boundary and must not leave a confirmed user without the requested username.

## Goals / Non-Goals

**Goals:**

- Establish one normalized, stable username for every newly completed registration.
- Preserve all current login methods for existing users while giving them a safe one-time username claim path.
- Support password login by username or email without revealing which identifier exists.
- Make username assignment, email confirmation, token consumption, and first-session eligibility consistent under validation failures and concurrent claims.

**Non-Goals:**

- Provider OAuth/OIDC authorization, provider-specific profile import, or automatic username generation.
- Changing email magic-link requests to accept usernames.
- Renaming an assigned username.
- Backfilling synthetic usernames for existing accounts.
- Changing game, iframe, actor-token, or session-runtime contracts.

## Decisions

### Store a nullable normalized username with database uniqueness

Add nullable `users.username` as PostgreSQL `citext` with a named unique index. The Svelte username inputs immediately trim surrounding whitespace and lowercase their values so users see the canonical handle before submission. The server accepts only 3-32 canonical lowercase ASCII characters matching `^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$` and rejects non-canonical direct payloads. This permits memorable handles while preventing whitespace, Unicode-confusable policy ambiguity, and leading or trailing separators without duplicating normalization across client and server.

The column remains nullable for unconfirmed registrations and accounts created before this migration. PostgreSQL unique semantics allow multiple `NULL` values, while the unique index arbitrates concurrent non-null claims. Ecto validation supplies normal field errors and `unique_constraint/3` converts the losing race into a controlled changeset.

Alternatives considered:

- A separate username identity table would generalize identifiers but adds an unnecessary join and lifecycle model for one immutable local attribute.
- Mandatory migration-time backfill would invent public identities for existing users and create collision and communication problems.
- Case-preserving storage would require a separate normalized field or less predictable display behavior. Storing the canonical lowercase form makes lookup and display consistent.

### Complete new registration on the existing confirmation POST

The valid confirmation GET renders the current confirmation page and includes a required username form field only for an unconfirmed user without a password. It performs no username claim, confirmation, or authentication. The POST passes the username into Accounts, which uses one `Ecto.Multi` transaction to validate and assign username, set `confirmed_at`, and delete authentication tokens. Only the successful result is passed to the existing session rotation boundary.

The Inertia confirmation view renders directly as page content inside the existing application `main` landmark and aligns with the standard narrow shell width. It does not wrap the content in a bordered, elevated, or rounded card surface because registration completion is a route-level page rather than an overlay or dialog.

Validation or uniqueness failure returns the username changeset, retains the unconfirmed account and token, and re-renders the form through the existing redirect/error flow. A confirmed account consuming an ordinary login magic link continues to authenticate without a username requirement.

Alternatives considered:

- Collecting username in the initial email dialog reserves names for people who never prove email ownership and complicates retries.
- Assigning username after session creation temporarily authenticates an incomplete account and weakens the registration invariant.
- Mutating on GET makes link previews and mail scanners capable of completing registration.

### Let legacy accounts claim exactly once in account settings

Account settings displays a dedicated username form only while the authenticated user has no username. The Accounts context rejects assignment after a username exists and applies the same changeset and unique constraint used by registration completion. Existing users remain authenticated and may continue email, password, magic-link, and linked-provider authentication before and after claiming.

This is preferable to forced sign-out or a blocking global prompt because old accounts already satisfy the authentication rules that existed when they were created. The one-time claim provides migration without silently changing their public identity.

### Treat password input as an identifier, but keep magic links email-only

Password login accepts `identifier` and compares it directly with the case-insensitive PostgreSQL `citext` email and username columns before performing the existing password verification. The application does not guard, trim, or change the case of the identifier. Unknown identifiers, wrong passwords, and passwordless accounts return the same generic credentials error. The password form uses a required text input with `autocomplete="username"`; the magic-link form remains an email input because delivery still requires an email address.

The actor profile uses `username || email` for `display_name`. This exposes the selected public handle while retaining a non-null compatibility value for legacy users.

## Risks / Trade-offs

- [Username squatting during confirmation] -> Names are claimed only after email ownership is proven by possession of a valid confirmation token, and the database resolves concurrent claims.
- [Enumeration through validation] -> Availability errors are shown only inside a valid email-confirmation or authenticated settings flow; password login remains generic.
- [Legacy account never claims a username] -> Email display and all existing authentication paths remain available; provider work can explicitly route incomplete new accounts through the same claim operation later.
- [Lowercase ASCII policy is restrictive] -> The policy is predictable across providers, URLs, fonts, and case-insensitive lookup; broader Unicode policy can be a separately specified migration.
- [Rollback loses claimed usernames] -> Rollback is schema-destructive for the new column and index. Before rollback, operations must accept the loss of username login and display data; email login remains the recovery path.

## Migration Plan

1. Add nullable `users.username` and its unique index without rewriting existing rows.
2. Deploy schema, Accounts changesets and transactions, controller handling, and Svelte forms together.
3. Verify new registration completion, duplicate-race handling, legacy email login, username login, and one-time settings claims.
4. Monitor unique-constraint and confirmation failures through existing application logging.
5. To roll back, deploy code that no longer reads username first, then reverse the migration. Claimed usernames are not recoverable after the column is dropped.

## Open Questions

None. The username syntax, completion point, compatibility behavior, and one-time assignment semantics are fixed by this change.
