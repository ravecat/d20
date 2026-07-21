## Context

Phoenix protects the Inertia routes with `protect_from_forgery`, and the Inertia adapter emits the current masked CSRF token in the readable `XSRF-TOKEN` cookie. The client currently reads the initial `<meta name="csrf-token">` value once and injects that value through `defaults.visitOptions` for the lifetime of the JavaScript application.

A restored or otherwise long-lived document can outlive the CSRF state represented by its initial HTML. In that state, the next Inertia form submission sends the stale header, Phoenix correctly returns `403 Forbidden`, and Inertia presents the non-Inertia response in its generic error dialog. The fix belongs in the Inertia client bootstrap, not in Phoenix CSRF enforcement, the game session flow, or the embedded module.

## Goals / Non-Goals

**Goals:**

- Make every Inertia request use the CSRF token currently stored in the adapter-managed cookie.
- Use the supported Inertia 3 HTTP client configuration for Phoenix's header name.
- Preserve the existing LiveSocket bootstrap and all server-side CSRF checks.
- Keep the change limited to application bootstrap configuration.

**Non-Goals:**

- Changing CSRF token lifetime, cookie attributes, or Phoenix forgery-protection behavior.
- Adding automatic retries for rejected state-changing requests.
- Changing actor tokens, module tokens, game session commands, or iframe loading.
- Redesigning Inertia's generic error dialog.

## Decisions

### Configure the Inertia HTTP client

Set `http.xsrfHeaderName` to `x-csrf-token` in `createInertiaApp`. Inertia's XHR client already reads its configured `XSRF-TOKEN` cookie immediately before each request; specifying the Phoenix-compatible header name connects that built-in behavior to `Plug.CSRFProtection`.

The alternative of continuing to use `defaults.visitOptions` was rejected because any value captured by the application bootstrap can become stale. Re-reading the meta element in the hook was also rejected because an Inertia response can refresh the cookie without replacing the root HTML meta element.

### Retain Inertia's default cookie name

Do not set `xsrfCookieName`. The Phoenix Inertia adapter already emits `XSRF-TOKEN`, which is the Inertia client's default. Configuring only the differing header name minimizes duplicated framework defaults.

### Keep the initial token for LiveSocket only

Retain the existing `csrfToken` value for `LiveSocket` connection params. That transport has a separate bootstrap lifecycle and is outside the failing Inertia HTTP request path.

### Validate configuration instead of duplicating dependency internals

Do not add a test that reimplements Inertia's cookie-reading behavior. Validate the repository-owned configuration through formatting, linting, type checking, the frontend test suite, and an asset build. The installed Inertia adapter template and client types provide the contract for `http.xsrfHeaderName`.

## Risks / Trade-offs

- [The `XSRF-TOKEN` cookie is absent] - Inertia sends no CSRF header and Phoenix continues to reject the request; the client does not invent or bypass a token.
- [A future adapter changes its cookie name] - Keep the client dependency and Phoenix adapter aligned; configure `xsrfCookieName` only if their shared default changes.
- [LiveSocket still uses the initial meta token] - This change intentionally does not alter a separate transport that is not responsible for the failing `Play` request.
- [A non-CSRF server or proxy error still opens Inertia's generic dialog] - This change removes the identified stale-header cause but does not hide unrelated HTTP failures.

## Migration Plan

1. Replace the custom Inertia visit-header hook with `http.xsrfHeaderName` configuration.
2. Run focused frontend formatting, linting, type checking, tests, and asset build validation.
3. Deploy as a client asset update; no database or server migration is required.
4. Roll back by restoring the previous client bundle, accepting the stale-token failure mode.

## Open Questions

None.
