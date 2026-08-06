## Context

The current uncommitted implementation publishes one nested `auth` Shared Prop and gives Header and AuthDialog a global Inertia type. Header still owns dialog visibility and initial mode, while AuthDialog owns mutable email and completion flags. AuthDialog must freeze whether its initial `mode` came from a server prompt so later mode switches do not discard prompt message, reauthentication, or return-path semantics. That split ownership is expressed through props, local runes, and `untrack`, making coordinated resets difficult to evaluate.

The implementation is part of the unfinished email login and registration delivery tracked by GitHub issues #21 and #193. It overlaps a mixed staged and unstaged auth worktree, so changes must stay limited to the shared-prop regions and preserve existing prompt, route, form, and session behavior.

## Goals / Non-Goals

**Goals:**

- Publish one complete authentication object on every Inertia response.
- Give the object a single global TypeScript contract used by reactive Page consumers.
- Remove the mailbox flag from the Header-to-AuthDialog component API.
- Give Header and AuthDialog one event-driven owner for the account-dialog workflow without forwarding initialization props.
- Preserve one-time prompt consumption and every existing account-flow state.

**Non-Goals:**

- Replace Inertia Page as the source of `authenticated` or local-mailbox availability.
- Introduce a full XState machine for a workflow that only needs event-driven context transitions.
- Change prompt fields, session keys, safe-return behavior, account routes, or Accounts operations.
- Preserve the old flat shared props.

## Decisions

### Publish the complete object from one UserAuth plug

`put_auth_prop/2` will read the session prompt, assign `auth: %{authenticated: boolean, local: boolean, prompt: map | nil}` through Inertia, and then remove the stored prompt when present. The router will call this single plug after `Inertia.Plug`.

This keeps the three auth values on one request boundary and preserves the existing ordering in which the prompt value is captured for the response before its session entry is deleted. Keeping two plugs was rejected because it would split construction of one object or require one plug to rewrite data assigned by another.

### Make all three nested keys required

`authenticated` and `local` are booleans. `prompt` is always present and is `null` when no server prompt exists. Required keys avoid optional chaining and client defaults that could hide an incomplete server response.

The shorter `local` name is intentionally scoped by its `auth` parent and means the local development mailbox is available. A longer nested name was rejected because the parent already supplies the missing context.

### Configure Inertia shared props globally in TypeScript

`assets/js/global.d.ts` will define `Auth`, `AuthPrompt`, and `InertiaConfig.sharedPageProps`. Header and AuthDialog will use plain `usePage()` so the library-provided reactive Page value carries the shared server contract everywhere.

A store that mirrors `authenticated`, `local`, or the current Page object was rejected because it would duplicate Inertia's source of truth and add synchronization work. The selected UI store instead owns only interaction state and one prompt snapshot for an active dialog session. Component-local generic Page declarations were rejected because each consumer could drift independently.

### Model account-dialog workflow in one directly imported store

A singleton named `auth` under the shared stores boundary will use the existing `@xstate/store` model and the official `@xstate/store-svelte` selector binding. Its serializable context will own dialog visibility, current mode, mutable email, the prompt snapshot for a server-requested opening, registration and magic-link completion, and password visibility. Transition contexts will be defined inline. Events will include `open`, `openPrompt`, `switchMode`, `updateEmail`, completion events, password visibility, `close`, and `reset`.

Header will continue reading `auth.authenticated` and the reactive `auth.prompt` from Page. A Page effect will send a non-null prompt to `openPrompt`, while the Register action will send `open`. Header will render AuthDialog while the store is open. AuthDialog will directly import the same singleton, select its snapshot, send interaction events, and continue reading `auth.local` plus the current Page URL directly. No authentication value or dialog state will be forwarded through component props.

The prompt is copied only when `openPrompt` begins a dialog session. This is an intentional interaction snapshot that keeps the server message, reauthentication flag, email, and safe return destination stable while the user switches modes. It does not replace Page as the server-auth source of truth.

A direct ES-module singleton was chosen over Svelte context because this application has one client-only shell and SSR is disabled. The store exposes `reset` for deterministic test isolation. A hand-written Page wrapper was rejected because Page is already reactive and mirroring it would add synchronization without modeling transitions.

### Remove flat props without aliases

The change will update all source, test, and durable-spec references in one delivery. Compatibility aliases were rejected because the requirements explicitly favor the smallest current contract and no external client consumes these internal Inertia props.

## Risks / Trade-offs

- [A missed flat-prop consumer fails at runtime] -> Make the shared TypeScript shape required, search all auth prop names, and run typecheck plus focused browser tests.
- [Combining plugs consumes the prompt too early] -> Capture the prompt in the assigned map before deleting the session key and retain the two-request consumption test.
- [Global typing conflicts with page-specific props] -> Use Inertia's supported `InertiaConfig.sharedPageProps` extension and keep page-specific props composed through the existing helper.
- [Direct page-component tests omit required shared props] -> Give each direct Inertia page render the same complete guest auth fixture used by the application test Page.
- [AuthDialog becomes coupled to Page] -> Accept the coupling because it already imports Inertia Form and represents only the Inertia account journey.
- [Singleton state survives component remounts and test cases] -> Reset the complete inline context on `close`, before focused tests, and through an explicit `reset` event.
- [A repeated Page effect reopens a dismissed one-time prompt] -> Depend only on the Page prompt identity; store transitions do not mutate Page, so closing the dialog does not retrigger the effect.
- [The store duplicates durable server auth facts] -> Keep `authenticated` and `local` exclusively in Page and retain only the prompt snapshot required by the active dialog session.
- [Mixed worktree changes are overwritten] -> Patch exact regions only and review staged and unstaged diffs after implementation.

## Migration Plan

1. Update delta specs and tests to describe the grouped contract.
2. Replace the two backend publication plugs with `put_auth_prop/2`.
3. Configure the global frontend type and update Page consumers plus mocks.
4. Add the Svelte XState Store binding and move account-dialog workflow state into the shared `auth` singleton.
5. Run targeted store, backend, and browser tests, then frontend lint/typecheck and strict OpenSpec validation.
6. Confirm the already-synced deltas and archive the completed change.

Rollback restores the two plugs, three flat shared keys, local Header Page typing, forwarded AuthDialog initialization props, component-local dialog state, and old test fixtures, then removes `@xstate/store-svelte`. There is no data, deployment, or migration rollback.

## Open Questions

None.
