## Context

Inertia sends navigations and form submissions as background HTTP requests. Its client treats a response without `X-Inertia: true` and a page object as an HTTP exception and, unless the application cancels that event, displays the raw response in a native dialog and sandboxed iframe. D20 currently returns conventional text or HTML for some controller-owned `403` and `404` branches, and Phoenix uses `D20Web.ErrorHTML` for uncaught `500` and `503` failures. Those responses are appropriate for ordinary browser requests but produce the diagnostic dialog during production Inertia visits.

The conversion must cover both explicit error responses and exceptions rendered by `Phoenix.Endpoint.RenderErrors`. It must run before route matching so an unknown route can receive the same treatment, and after `Plug.RequestId` so the public page can carry the same correlation identifier as the server log. The existing Inertia Phoenix responder is intended for controller pages and currently normalizes Inertia responses to `200`, so it cannot preserve an already selected error status at this endpoint boundary.

The current application layout also assumes authenticated shared props and mounts the persistent workspace. A degraded error response must not depend on those props or start additional session UI while the original request is failing.

## Goals / Non-Goals

**Goals:**

- Replace Inertia's production diagnostic dialog with a D20-owned page for `403`, `404`, `500`, and `503` responses.
- Preserve the original HTTP status and a navigable URL without redirecting to a dedicated error route.
- Keep public failure data minimal, safe, correlated with logs, accessible, and usable on supported narrow viewports.
- Cover explicit controller responses, unmatched routes, CSRF or authorization failures, and exceptions rendered by the Phoenix endpoint.
- Preserve conventional HTML errors for non-Inertia requests and actionable diagnostics in development.

**Non-Goals:**

- Change validation errors, expected domain failures, JSON module endpoints, channel errors, or embedded game-client error UI.
- Recover from the underlying exception, retry mutating requests automatically, or guarantee that an unavailable application can render its enhanced fallback.
- Expose exception messages, stack traces, parameters, session state, or game state to the error page.
- Add a `/500` route or change the status semantics of failed requests.

## Decisions

### Normalize supported production responses before they are sent

Add one endpoint-level plug immediately after `Plug.RequestId`. For an enabled production request with `X-Inertia: true`, it will register a `before_send` callback. If the final status is `403`, `404`, `500`, or `503` and the response is not already a valid Inertia response, the callback will replace the raw body with a minimal Inertia page object, set `X-Inertia: true` and the JSON content type, and leave the selected status unchanged.

Registering before parsers and routing allows the callback to observe explicit `send_resp` branches, unmatched routes, forgery and authorization failures, and bodies produced later by `Phoenix.Endpoint.RenderErrors`. Existing valid Inertia responses, redirects, location visits, successful responses, and requests without the Inertia header pass through unchanged.

The page object will use the deployed client's request version and expose only the `error` component, empty validation errors, the public status, and the response request identifier. For a failed `GET`, its URL will remain the requested path and query. For a failed mutating request, it will use a validated same-origin referrer path when available and otherwise `/`, avoiding a non-navigable POST action in browser history.

Alternatives rejected:

- Redirecting to `/500` would require a second request, replace the original failure status with redirect semantics, and lose correlation with the failed operation.
- Handling `inertia:httpException` only in JavaScript would hide protocol failures on the client, depend on a healthy application bootstrap, and leave the server response outside the Inertia page contract.
- Updating every controller branch would duplicate policy and would not cover route misses, forgery failures, or uncaught exceptions.
- Changing the dependency responder to preserve non-`200` statuses would broaden this application change into dependency maintenance and still would not establish an endpoint exception boundary by itself.

### Render the error as a self-contained degraded page

Add an `error` Inertia page with status-driven public title, heading, description, recovery action, and optional request reference. The application resolver will load it like other pages, but it will opt out of the normal header, footer, authentication dialog, and workspace layout. The page will own its minimal D20 navigation and viewport surface so it does not require shared authentication props or open more runtime connections during a failure.

The primary recovery action will be a normal safe navigation rather than an automatic retry. In particular, the page will never resubmit a failed mutating request. The error heading or main region will receive programmatic focus after the Inertia swap, the document title will identify the status, and the layout will account for dynamic viewport and safe-area insets.

Reusing the full application layout was rejected because that layout reads required shared props and mounts session-aware UI that may be unavailable or implicated in the failure.

### Keep status mapping and public diagnostics server-owned

The response will send the numeric status and request identifier, while the error page maps the supported statuses to fixed public copy. No exception-derived text enters page props. `500` and `503` pages will show the correlation identifier already emitted by `Plug.RequestId`; `403` and `404` can omit it unless support value is demonstrated.

Phoenix retains its current exception logging and telemetry. The enhanced response changes presentation only and does not rescue, downgrade, or suppress the original failure.

### Gate the enhanced boundary to production behavior

Enable the response normalizer through application configuration in production and explicitly in focused tests. Development will keep Phoenix debug responses and Inertia's diagnostic dialog so engineers retain stack traces and route diagnostics. Non-Inertia requests will continue through the configured `D20Web.ErrorHTML` renderer with their original status.

## Risks / Trade-offs

- [The minimal page object drifts from the Inertia protocol] - Keep it limited to documented page fields and add backend assertions that the installed Inertia client accepts the response contract, including status, header, component, props, URL, and version.
- [The fallback itself raises] - Keep the endpoint plug free of session, parameter, database, and domain access; fall back to Phoenix's conventional error renderer if page normalization cannot complete.
- [A mutating request lacks a trustworthy referrer] - Use `/` rather than exposing the action URL or trusting a cross-origin value.
- [The full shell is unavailable on the error page] - Treat this as deliberate degraded behavior and provide minimal brand navigation and recovery without authentication or workspace dependencies.
- [An asset-version mismatch prevents the error component from resolving] - Reuse the request's current Inertia version and keep a conventional navigation action that can reload the application document.
- [Broad status interception hides an intentionally plain Inertia response] - Limit conversion to production Inertia requests, the four specified statuses, and responses that do not already declare themselves as Inertia pages.

## Migration Plan

1. Add the endpoint response-normalization plug behind environment configuration and cover its response contract in isolation.
2. Add the self-contained Svelte error page, status copy, focus behavior, and responsive browser coverage.
3. Update controller and endpoint expectations for production-like Inertia errors while retaining non-Inertia and development coverage.
4. Deploy as an application and asset update with no database migration.
5. Verify representative `403`, `404`, `500`, and `503` responses in a production-like environment and correlate a server failure reference with logs.
6. Roll back by disabling or removing the normalizer and error page, restoring the current conventional response and diagnostic-dialog behavior.

## Open Questions

None.
