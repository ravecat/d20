## Why

The Inertia client captures the CSRF token from the initial HTML document and reuses it for every later visit. When the browser restores a page whose session has changed, state-changing requests can send an obsolete token, receive a non-Inertia `403 Forbidden` response, and surface it as Inertia's blank-looking error dialog instead of launching a game.

## What Changes

- Configure Inertia's HTTP client to read the current `XSRF-TOKEN` cookie for every request and send it through Phoenix's expected `x-csrf-token` header.
- Remove the custom visit hook that injects the initial document token into every Inertia request.
- Keep the initial document token for the independent LiveView socket bootstrap.
- Validate the supported frontend configuration and the existing frontend suite without weakening Phoenix CSRF protection.

## Capabilities

### New Capabilities

- `inertia-csrf-requests`: Defines how Inertia state-changing requests obtain and submit the current Phoenix CSRF token across long-lived and restored pages.

### Modified Capabilities

None.

## Impact

- Affected code: `assets/js/app.js` and focused frontend validation.
- Dependencies: uses the existing Inertia 3 HTTP client and the `XSRF-TOKEN` cookie already emitted by the Phoenix Inertia adapter; no dependency changes.
- Compatibility: public routes, request payloads, Phoenix session behavior, game sessions, and iframe module contracts remain unchanged.
- Migrations: none.
- Rollback: restore the previous Inertia visit hook, with the known risk of reintroducing stale CSRF headers on restored pages.
