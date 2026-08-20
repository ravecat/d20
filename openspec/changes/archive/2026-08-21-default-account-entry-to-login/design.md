## Context

The shared guest header currently renders a `Register` button and calls `auth.trigger.open()` without an event payload. The auth store initializes, closes, resets, and opens without a server prompt in `register` mode. Login is available only after the guest switches modes inside the dialog or after a server-owned authentication prompt opens it.

This makes account creation the product's default entry even though returning-player login is the more general account action. It also contributes to confusion when provider authentication started from Login mode legitimately transitions an unknown provider identity into registration completion.

The same uncommitted delivery already consolidates Account Settings provider props into one ordered server-shaped collection. GitHub issue #218 owns both the user-visible login-first entry and that supporting provider refactor.

## Goals / Non-Goals

**Goals:**

- Present `Log in` as the guest header account action on the main and overlay headers.
- Open a clean shared account-dialog session directly in Login mode.
- Keep account creation available through the existing in-dialog `Create account` transition.
- Preserve prompt-driven login, reauthentication, closing, state reset, focus, and authenticated-header behavior.
- Retain the server-shaped Account Settings provider contract and its existing behavior.

**Non-Goals:**

- Distinguishing provider Register and Login actions at provider request or callback boundaries.
- Preventing an unknown provider identity from entering registration completion.
- Automatically merging identities by email.
- Changing auth routes, forms, provider credentials, callback validation, sessions, or persistence.

## Decisions

### Make Login the auth-store default

The auth store will use `login` for its initial, clean-open, close, and reset mode. A server prompt already opens Login mode and remains unchanged. The header can continue to call the narrow `open()` event without introducing a caller-selected mode payload.

Adding `mode` to the open event only for the header was considered but rejected because it would preserve a contradictory registration default below the product's single account-entry boundary. Register-only Storybook setup already switches explicitly to its requested mode after opening and remains deterministic.

### Rename the guest header action and internal styling vocabulary

The guest header button text becomes `Log in`. Its local CSS class and compact-scroll animation name will use `login` rather than `register` so implementation terminology matches the visible behavior. Both normal and overlay variants reuse the same header component and therefore receive the behavior together.

Keeping the old CSS names was considered but rejected because those names would misdescribe the only account action and make future account-entry work harder to navigate.

### Keep registration as an explicit mode switch

Login mode retains the existing `Create account` button. Activating it preserves entered email, switches to Register mode without navigation, and moves focus through the existing shared mode-switch handler. No direct Register action remains in the shared header.

Removing registration or introducing a separate registration route was rejected because it would change account capability and duplicate the shared dialog.

### Keep provider authentication semantics unchanged

`Sign in with <provider>` and `Sign up with <provider>` continue to use the same authentication request route. Existing linked provider identities log in; unknown identities may enter registration completion; matching email alone never merges accounts. The login-first header changes initial presentation, not identity ownership rules.

Passing provider intent through this feature was rejected because it is a separate product decision with security and registration acceptance implications.

### Retain the server-shaped Account Settings provider contract

The completed controller, Svelte, test, and Storybook changes remain part of this feature. Phoenix owns provider order, names, availability, linked state, and verified link URLs; Svelte owns trusted build-time icons and filters unavailable entries.

## Risks / Trade-offs

- [Registration is one interaction deeper] -> Keep the visible `Create account` action in Login mode and browser-test the switch and focus behavior.
- [Existing tests assume Register is the header entry] -> Update shared helpers and branch-driving assertions without weakening registration, provider, responsive, or authenticated-state coverage.
- [Provider sign-in may still lead an unknown identity to registration] -> Keep this behavior explicit in specifications and out of scope rather than implying the header-label change alters callback semantics.
- [Elixir and TypeScript provider identifiers can drift] -> Retain exact controller contract coverage and frontend typecheck from the supporting refactor.

## Migration Plan

1. Extend the owning issue and OpenSpec artifacts before implementation.
2. Change the auth-store clean default and guest header label and local CSS vocabulary.
3. Update focused auth-store and browser tests, preserving registration and provider matrices through explicit mode switching.
4. Validate the guest and authenticated states in the existing browser, run focused and full repository checks, sync both delta specifications, and archive the combined change.
5. Roll back the store and header behavior together if login-first entry must be reverted; no data migration is required.

## Open Questions

None.
