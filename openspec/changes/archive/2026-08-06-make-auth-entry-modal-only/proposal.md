## Why

D20 now has a shared Inertia account dialog, but registration and login are still duplicated as standalone pages. Keeping two presentation paths increases maintenance and lets server redirects bypass the product's intended modal account experience.

## What Changes

- Make the shared `AuthDialog` the only presentation for account registration, magic-link requests, password login, and sudo reauthentication.
- **BREAKING** Remove the standalone `GET /users/register` and `GET /users/log-in` routes and the superseded Inertia auth page.
- Preserve the existing registration and login POST endpoints, Phoenix Accounts behavior, session rotation, remember-me behavior, and safe post-authentication return paths.
- Redirect unauthenticated and sudo-gated requests to the home Inertia page with a one-time server prompt that opens Login mode, including an understandable error after an invalid or expired magic link.
- Keep magic-link confirmation and account settings as standalone Inertia pages.
- Treat the existing magic-link request as account recovery; do not add a separate password-reset token or page.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-registration`: Remove the direct registration page and require registration presentation through the shared account dialog.
- `email-account-login`: Remove the direct login page, define server-prompted modal login and sudo reauthentication, and retain standalone magic-link confirmation and account settings.

## Impact

- Phoenix auth routes, `D20Web.UserAuth`, session and registration controllers, and Inertia shared props.
- The shared Svelte header and account dialog plus removal of the `pages/auth` slice.
- Controller, UserAuth, shared-header, layout, and page-resolution tests.
- No database migration, Accounts schema change, token format change, new dependency, or iframe contract change.
- Rollback restores the two GET routes and the standalone Inertia auth page while leaving persisted users, tokens, and sessions unchanged.
