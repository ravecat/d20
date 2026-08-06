## Context

The account surfaces contain registration, magic-link login, password login, magic-link confirmation, email settings, and password settings as separate Inertia Svelte `Form` instances. Each form currently declares an `errorBag`. The Inertia Phoenix adapter applies that bag when a controller assigns errors, stores the already-bagged map in the session for a redirect, and applies the same bag again when the redirected request loads the session errors. The client scopes one level, leaving a nested map that does not match the form slot's flat field-error contract.

Inertia's form helper already owns processing, success, and error state per form instance. Its documented server flow is for Phoenix to call `assign_errors` with a changeset or flat field map and redirect back to the page containing the form.

## Goals / Non-Goals

**Goals:**

- Deliver flat server errors to the exact account form that initiated the request.
- Follow the standard Inertia form-helper and Phoenix redirect flow.
- Preserve independent state for every account form without explicit error bags.
- Cover the final redirected Inertia response rather than only the intermediate controller response.

**Non-Goals:**

- Change account validation, duplicate-email privacy, delivery semantics, session rotation, or return paths.
- Replace the Inertia `Form` component or introduce manual fetch and `422` handling.
- Patch generated dependency files under `deps/` or add a dependency override.
- Change dialog composition, dismissal, or visual design.

## Decisions

### Let each Inertia Form instance scope its own request errors

Remove `errorBag` from registration, login, confirmation, and settings forms. Only the submitting `Form` receives the request callbacks and stores the returned errors, so sibling forms retain independent state without a server-side bag key.

Keeping the bags and teaching the UI to read `errors.registration.email` was rejected because it depends on an accidental double wrapping and would break when the adapter returns the documented flat form errors. Manually stripping a duplicate key in the controller or client was rejected for the same reason.

### Keep Phoenix assign-errors and redirect behavior

Controllers continue to pass changesets or flat maps into `assign_errors` and return a `303` redirect to the immediate response page. This preserves the adapter's session-backed validation flow and avoids treating Inertia validation as a JSON `422` API.

Patching `Inertia.Plug` under `deps/` was rejected because dependency-managed source is not an application customization boundary and the form helper does not need bags for this UI.

### Test the redirect boundary directly

Controller tests will submit an Inertia request without an error-bag header, recycle the connection through the redirect destination, and assert the final page exposes one flat field-error map. Browser component tests remain responsible for user-visible form isolation and accessible error rendering.

This closes the gap where controller tests asserted the session immediately after POST while browser tests replaced the real Inertia form transport with a mock.

## Risks / Trade-offs

- [A future form bypasses its local Form state and reads global page errors] -> Keep error rendering inside each `Form` snippet and cover sibling-form isolation in browser tests.
- [Another caller still sends an explicit error-bag header] -> Preserve Phoenix adapter behavior for that caller; auth controller tests model the actual account forms without the header.
- [The active dialog-composition change moves stale error-bag markup] -> Update its preservation wording so later composition work retains the corrected flat-error contract.

## Migration Plan

Remove the client error-bag declarations from account forms, update focused tests, and deploy without data or session migration. Rollback restores the declarations and test expectations but also restores the current invisible-error defect.

## Open Questions

None.
