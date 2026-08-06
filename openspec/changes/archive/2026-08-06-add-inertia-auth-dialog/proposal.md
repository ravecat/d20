## Why

D20 already supports email magic-link and password sign-in through Phoenix-generated server-rendered pages, while account registration now opens from the shared Inertia shell. Players need one consistent account dialog that can switch between registration and sign-in without leaving the current game or catalog page, while preserving Phoenix Accounts and session security as the system of record.

## What Changes

- Replace the registration-only shell dialog with a shared account dialog that switches between Register and Log in modes without navigation.
- Add an Inertia form for requesting an email magic link and a separate Inertia form for email-and-password sign-in, with isolated processing, success, and error states.
- Return successful password sign-in to the current safe Inertia page and preserve the existing Phoenix session rotation and remember-me behavior.
- Keep Google, Facebook, Apple, and Discord visible as unavailable future sign-in methods without initiating provider authorization.
- Render direct registration, login, magic-link confirmation, account-settings, and sudo reauthentication journeys through Inertia/Svelte instead of maintaining parallel HEEx authentication pages.
- Coordinate the existing `add-email-account-registration` change to replace its internal JSON registration transport with the same Inertia form and redirect conventions.

## Capabilities

### New Capabilities

- `email-account-login`: Defines the shared-shell login entry point, dialog mode switching, magic-link request, password sign-in, scoped errors, current-page return, remember-me choice, and unavailable provider states.

### Modified Capabilities

None. The still-active `email-account-registration` capability is revised in its owning change before archival so its registration action participates in the shared dialog and uses Inertia form delivery.

## Impact

- Phoenix Inertia routing around every account journey, the registration, session, and settings controllers, plus `D20Web.UserAuth` return-path handling.
- The shared Svelte header and registration dialog, which becomes a switchable account dialog whose account forms are also reused by direct Inertia pages.
- Focused controller and frontend tests for registration, magic-link login and confirmation, password login, account settings, sudo reauthentication, mode switching, focus restoration, and disabled providers.
- No database migration, new dependency, account-schema change, iframe protocol change, or provider implementation is required.
- Rollback restores the removed HEEx presentation and browser auth pipeline while leaving Phoenix Accounts, user sessions, and credentials intact.
