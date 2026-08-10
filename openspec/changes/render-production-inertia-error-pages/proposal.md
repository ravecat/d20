## Why

Production Inertia visits currently surface conventional `403`, `404`, `500`, and `503` responses through Inertia's diagnostic HTML dialog, which can leave players facing a blank or terse iframe with no product-owned recovery path. D20 needs safe error pages that preserve the failed request's HTTP status and remain understandable on supported devices without hiding useful development diagnostics.

## What Changes

- Return a D20-owned Inertia error page for supported production failures raised during Inertia visits, while preserving the original `403`, `404`, `500`, or `503` status instead of redirecting through a dedicated error URL.
- Present status-appropriate public copy, a safe recovery action, and the existing request correlation identifier without exposing exception details, private state, or stack traces.
- Keep conventional HTML error responses for non-Inertia requests and retain actionable Phoenix and Inertia diagnostics in development.
- Preserve existing validation and expected domain-error flows that return Inertia error props to their owning form or page.
- Add focused controller, endpoint, component, accessibility, and narrow-viewport coverage for the new failure boundary.

## Capabilities

### New Capabilities

- `inertia-error-pages`: Defines production rendering, status preservation, safe diagnostics, recovery, accessibility, and non-Inertia compatibility for application failures encountered during Inertia visits.

### Modified Capabilities

None.

## Impact

- Affected systems: Phoenix endpoint error rendering, Inertia page responses, the Svelte page resolver and application shell, and focused backend and frontend tests.
- Public behavior: production Inertia visits gain application-owned error pages for supported statuses; existing routes, request payloads, validation errors, session behavior, and iframe module contracts remain unchanged.
- Dependencies and migrations: no new runtime dependency or database migration is expected.
- Rollback: restore conventional Phoenix error rendering for failed Inertia visits, accepting the current diagnostic-dialog behavior in production.
- Tracking: [GitHub issue #202](https://github.com/ravecat/d20/issues/202).
