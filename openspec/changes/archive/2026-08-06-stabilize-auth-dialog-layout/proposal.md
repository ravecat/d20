## Why

Registration success currently replaces the email form together with the provider alternatives, causing the account dialog to collapse after submission. The dialog surface also distributes horizontal insets across several child blocks, which produces visibly inconsistent alignment between the title, description, notices, forms, and result state.

## What Changes

- Keep the Register mode structure after successful email submission and replace only the email registration form with the check-email result.
- Make the native account dialog own its surface and common responsive content inset.
- Remove independently accumulated horizontal padding from the dialog's child regions so primary content shares one inline alignment.
- Preserve native dialog focus behavior, viewport constraints, internal scrolling, form contracts, and provider availability.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-registration`: Registration success keeps the provider alternatives and mode switch available while replacing only the completed email form.
- `email-account-login`: The shared account dialog owns a consistent responsive content inset while retaining its common inline size and viewport accessibility.

## Impact

- Affects the shared Svelte account dialog, account panel layout styles, and focused browser tests.
- Does not change Phoenix routes, controllers, session behavior, account persistence, public APIs, dependencies, database schemas, or iframe contracts.
- Rollback restores the previous component structure and scoped styles without data or migration work.
