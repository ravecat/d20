## Context

Phoenix-generated Accounts code already persists an unconfirmed user with a case-insensitively unique email, inserts a login token, sends confirmation instructions, and confirms and authenticates the user when the magic link is consumed. The current controller exposes that behavior only through `/users/register`, rendered with the server-side authentication layout. The Inertia/Svelte application header contains only the D20 brand, so the main product shell has no registration entry point.

The existing controller assumes delivery always succeeds with `{:ok, _}` after the user is inserted. A mailer error therefore raises after the account and login token may already exist. Production provider selection, asynchronous jobs, retries, and telemetry are intentionally tracked by GitHub issue #38 and are not safe to infer in this change.

## Goals / Non-Goals

**Goals:**

- Expose email account creation from the shared Svelte header without replacing the Phoenix Accounts system.
- Keep dialog validation, submission, success, and recoverable delivery-failure states in place.
- Preserve the email-only registration security model: no password is set before the email owner confirms through a magic link.
- Preserve one account for case-insensitively equivalent email submissions under database concurrency.
- Keep the existing direct registration URL usable through an Inertia page and make its delivery failure controlled.
- Verify accessible keyboard, focus, responsive, and disabled-provider behavior.

**Non-Goals:**

- Configure a production mail provider, add a job queue, retry delivery, or add delivery telemetry.
- Add password registration, username selection, username login, or provider authentication.
- Merge a guest identity or its active sessions into the new user identity.
- Change the users schema, magic-link lifetime, session rotation, or public game contracts.
- Reproduce Board Game Arena branding or surrounding promotional content.

## Decisions

### Use the existing registration route through an Inertia form

The shared account dialog submits registration through `@inertiajs/svelte` `<Form>` to the existing Phoenix registration POST route. `Inertia.Plug`, redirect-carried errors, flash, and a registration-specific error bag keep validation and delivery feedback in the dialog without a custom JSON response contract. The response never exposes a user id, confirmation token, or mail-provider detail.

The existing direct GET and POST journey remains available through the Inertia application and reuses the same account surface as the shared dialog. A separate JSON route was rejected because it duplicates CSRF, submission state, redirect, and validation conventions already supplied by Inertia. The coordinated login change owns migration of token confirmation, settings, and authenticated sudo reauthentication to Svelte.

### Share only minimal account-flow state with the Inertia shell

The Inertia pipeline will expose one shared boolean prop indicating whether the request has an authenticated user. The header uses it to render Register only for guests. Email and other account details are not required by this capability and will not be added to page props.

The account flow may also expose whether the local development mailbox is available. That value is true only when development routes are enabled and `Swoosh.Adapters.Local` is the configured mail adapter, so the UI cannot link to a mailbox route that was not compiled into the router.

Always rendering Register and relying on the authenticated redirect was rejected because it exposes an action that cannot succeed and gives stale shell behavior after authentication.

### Keep registration orchestration in Accounts

Add one Accounts function that composes the existing user insert and confirmation-instruction delivery. The Inertia controller action calls this application boundary so persistence and delivery semantics stay independent from presentation state.

The database `citext` unique index remains the concurrency authority. Changeset validation provides normal feedback, while `unique_constraint/3` converts a concurrent uniqueness conflict into the same controlled changeset result. No application-level lock or preflight-only uniqueness decision is introduced.

### Persist the account when delivery reports failure

If mail delivery returns an error after account and token insertion, keep the account and token, return a typed application-level delivery failure, and provide the player a link to the existing email login journey where they can request another magic link. Do not automatically retry within the request.

Rolling the account back was rejected because a provider can accept a message and still return an ambiguous transport failure; deleting the account would make a potentially delivered confirmation link invalid. Automatic request-time retry was rejected because it can produce duplicate messages and belongs to #38.

### Use the Register mode of one native account dialog

Implement registration as the initial mode of the shared Svelte 5 account dialog around native `<dialog>.showModal()`. Inertia form slot state and a small local result state cover processing, success, validation error, and delivery failure. Native modality supplies the inert background, focus containment, and Escape behavior; the component restores its initial state after close and preserves visible focus treatment without adding a manual Tab trap.

The highlighted account panel in the supplied BGA screenshot is a composition reference only. The implementation uses existing D20 color, radius, typography, and responsive conventions. An `or` separator distinguishes email registration from the disabled provider group. Google, Facebook, Apple, and Discord are native disabled buttons with visible `Coming soon` text and cannot submit or navigate. The existing-user action switches to the dialog's Login mode without navigation while preserving the entered email.

Keep routine shell and registration-entry insets as literal component-scoped values. Repeating the same padding in a few components does not make it a shared design contract, so this flow must not introduce a globally overridable custom property solely for those local dimensions.

### Keep duplicate feedback useful but non-specific

Server validation can distinguish malformed input from a unique conflict, but the account surface maps the unique-conflict message to a neutral account-creation failure with a login action. This avoids adding a stronger email-enumeration signal than necessary while still giving the player a next step.

## Risks / Trade-offs

- [A created account can remain unconfirmed after a delivery failure] -> Preserve the token, show a recovery action, and let the existing login journey issue a replacement magic link.
- [The synchronous mail call still adds provider latency] -> Keep the UI in a submitting state and leave bounded asynchronous delivery to #38.
- [A public registration endpoint can be abused for mail volume] -> Send at most one message for the successful insert, never auto-retry, and address queue idempotency and operational controls in #38.
- [The direct page and dialog can drift] -> Render the same account surface in both presentation contexts and keep one controller contract.
- [Mailbox adapter and development-route configuration can drift] -> Derive the mailbox hint from both settings and cover both false branches.
- [The shared header is present in overlay mode] -> Give its actions explicit pointer-event behavior and verify the modal from representative layouts.
- [The worktree contains unrelated in-progress changes] -> Limit edits to account, web-auth, shared-header, focused tests, and this change directory.

## Migration Plan

1. Add the OpenSpec contract and focused backend tests.
2. Add Accounts orchestration and controlled Inertia controller responses.
3. Route direct and modal registration through the Inertia auth routes and expose the guest authentication prop.
4. Add the shared Svelte account dialog, header action, and browser tests.
5. Run targeted backend and frontend checks, then the repository-wide check.

No data migration or coordinated iframe release is required. Rollback restores the former HEEx presentation; existing accounts and confirmation links remain valid.

## Open Questions

None. Production delivery and retries remain explicitly tracked by GitHub issue #38.
