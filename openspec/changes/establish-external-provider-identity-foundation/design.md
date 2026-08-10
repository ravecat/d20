## Context

D20 currently identifies registered users with `D20.Accounts.User` and authenticates them through email/password or magic-link flows. The `users` table has no durable representation of a Google, Facebook, Apple, or Discord account, so provider callbacks cannot resolve a stable D20 identity without coupling provider data directly to `User`.

The provider issues require D20 Accounts to remain the system of record. This slice precedes Ueberauth integration: it creates only the persistence and context boundary that a later callback adapter will call. D20 entity identifiers use TypeID string primary keys with entity-specific prefixes.

Provider-based registration is not possible in this slice because `User.email` remains required. Account creation and email policy depend on #192 and provider-specific decisions.

## Goals / Non-Goals

**Goals:**

- Persist the minimum stable mapping from a supported provider identity to one existing D20 user.
- Keep provider and Ueberauth structs outside the Accounts boundary.
- Enforce identity ownership and per-user provider cardinality in PostgreSQL so concurrent writes cannot bypass the rules.
- Provide small public APIs for later sign-in and account-linking flows.
- Preserve every existing account and session behavior.

**Non-Goals:**

- Installing or configuring Ueberauth or provider strategies.
- Adding provider request/callback routes, controllers, session creation, or enabled UI controls.
- Creating a D20 user from provider claims or merging users by email.
- Persisting provider access tokens, refresh tokens, raw claims, email, display name, or avatar.
- Unlinking identities or defining account recovery policy.

## Decisions

### Store external identities in a separate table

Add `user_identities` with an `identity`-prefixed TypeID string primary key, a TypeID string `user_id` foreign key, an enumerated `provider`, a `provider_uid`, and UTC timestamps. `D20.Accounts.UserIdentity` belongs to `User`; `User` exposes a `has_many :user_identities` association.

`UserIdentity` sets Ecto's `@foreign_key_type` to `TypeID`, but does not repeat `prefix: "user"` on `belongs_to`. The parameterized TypeID field derives that prefix through the association metadata from the `User.id` primary key, keeping the user schema as the single source of the prefix.

This keeps provider credentials separate from the account and supports multiple providers without nullable columns on `users`. A JSON map on `users` was rejected because it weakens referential integrity and makes concurrent uniqueness enforcement harder. Provider-specific columns on `users` were rejected because each new provider would expand the core account schema.

The identity row uses the same prefixed TypeID convention as other D20 entities. The `identity` prefix distinguishes D20 identity-record IDs from `user` IDs and from the provider-owned opaque `provider_uid`.

### Persist a closed provider allowlist and an opaque provider UID

The supported provider values are `google`, `facebook`, `apple`, and `discord`. The Ecto schema uses `Ecto.Enum`, persisted as strings, and the migration adds a matching check constraint. Adding another provider therefore requires an intentional schema and migration update.

`provider_uid` is an opaque, case-sensitive string of at most 255 characters. The later callback adapter is responsible for mapping the provider's stable account identifier to this field. D20 does not derive identity from email because provider email availability and verification differ and email-based merging can attach an attacker-controlled identity to an existing account.

An unconstrained provider string was rejected because misspellings and unconfigured strategies would otherwise create durable but unusable identity records.

### Enforce both ownership invariants in PostgreSQL

A unique index on `(provider, provider_uid)` guarantees that one external identity cannot belong to two D20 users. A second unique index on `(user_id, provider)` guarantees that a D20 user has at most one identity for a provider, while still allowing identities from multiple providers. The changeset maps both constraints to controlled validation errors.

Application-only checks were rejected because concurrent account-link attempts could pass them and create conflicting ownership.

The foreign key uses `on_delete: :delete_all`, so deleting a user also removes identifiers that can no longer resolve to an account.

### Keep the public Accounts API library-neutral

Add these operations to `D20.Accounts`:

- `link_user_identity/3` accepts an existing `%User{}`, a supported provider atom, and the opaque provider UID, returning the inserted identity or an Ecto changeset error.
- `list_user_identities/1` returns the identity records owned by an existing user.
- `get_user_by_identity/2` accepts the typed provider/UID primitives and returns the user for an exact pair or `nil` when that valid pair is unknown.

The context constructs the changeset with `user_id` from the supplied user. It does not accept caller-controlled ownership fields. A later web adapter will normalize `Ueberauth.Auth` into these primitives, discard credentials and raw claims, and invoke the context.

Embedding `Ueberauth.Auth` in the schema or context API was rejected because it would couple account persistence to a web-boundary library and make provider payloads easier to retain or log accidentally.

The lookup does not duplicate changeset validation with guards or fallback clauses. Unsupported providers and non-string UIDs are calling-code errors that Ecto surfaces during query casting. Empty strings need no special read behavior because the write path and database constraints prevent them from being persisted, so an empty lookup naturally has no match.

### Do not change login or registration semantics

This change only links identities to existing users and resolves them. It does not generate D20 session tokens, rotate sessions, confirm email addresses, or create accounts. Those behaviors belong in later provider flows and must call existing Accounts and `D20Web.UserAuth` boundaries explicitly.

## Risks / Trade-offs

- [A provider changes the identifier it returns] -> Treat the stored UID as opaque and validate the stable identifier contract during each provider implementation before enabling it.
- [A provider is added later] -> Update both the Ecto enum and database check constraint in a reviewed migration; the closed list deliberately favors fail-closed behavior.
- [Two links race] -> Rely on unique indexes and return a changeset error from the losing insert.
- [A future product wants multiple accounts from the same provider linked to one user] -> The `(user_id, provider)` invariant would need a deliberate migration and account-settings UX change.
- [Deleting a user destroys identity links] -> This is intentional because an identity row has no meaning without its owner; normal database backup and restore remain the recovery mechanism.

## Migration Plan

1. Deploy the additive `user_identities` migration with no backfill. Existing user rows and authentication paths are unchanged.
2. Deploy the schema and context APIs with provider entry points still disabled.
3. Validate constraints and cascading deletion through the Accounts tests.
4. Implement provider-specific adapters and flows in later tracked changes.

Rollback drops only `user_identities`. This is safe before provider flows write rows. After provider linking is enabled, rollback would discard those links and must be preceded by a data backup or provider rollback plan.

## Open Questions

The following decisions are deferred to provider integration and do not block this persistence slice:

- Which reauthentication proof is required before linking an additional identity.
- Whether and how a provider-only user can create the required D20 account email after #192.
- Which recovery checks are required before unlinking an identity.
