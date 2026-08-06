## Context

Phoenix Accounts and `D20Web.UserAuth` already own email lookup, password verification, magic-link tokens, session rotation, remember-me cookies, token confirmation, and sudo reauthentication. The shared Svelte header owns the new account dialog, but direct registration, login, confirmation, settings, and sudo journeys still use generated HEEx pages. This leaves two presentation systems over one account model.

The application already uses `@inertiajs/svelte` `<Form>` and the Phoenix Inertia adapter for same-origin mutations, redirect-based validation, shared authentication props, CSRF headers, processing state, and error bags. Keeping a second JSON protocol for account actions would duplicate those conventions and make registration and login failures behave differently from the rest of the shell.

This change is tracked by GitHub issue #21 and coordinates with the still-active registration change tracked by #193.

## Goals / Non-Goals

**Goals:**

- Present registration and sign-in as two modes of one shared-shell account dialog.
- Support magic-link request and email-and-password sign-in simultaneously in Login mode.
- Use Inertia form submissions, redirects, flash, error bags, and the shared `authenticated` prop instead of custom JSON responses.
- Preserve Phoenix-generated authentication semantics, token confirmation, safe session rotation, and remember-me cookies while moving all product account screens to Inertia.
- Preserve a safe current-page return for modal registration, magic-link confirmation in the same browser session, and password sign-in.
- Render only the active Register or Login mode and preserve accessible native dialog behavior.
- Keep direct account URLs deep-linkable and render registration, login, magic-link confirmation, settings, and sudo reauthentication as Inertia pages.

**Non-Goals:**

- Add username sign-in or username persistence.
- Implement Google, Facebook, Apple, or Discord authorization.
- Add password creation to initial registration.
- Configure production email delivery, background jobs, retries, or delivery telemetry.
- Merge an anonymous actor or its active sessions into a user account.
- Convert Phoenix LiveDashboard, the local mailbox, error rendering, or other development and system pages to Inertia.

## Decisions

### Use Inertia forms over a shell-specific JSON API

Registration, magic-link request, and password sign-in use `@inertiajs/svelte` `<Form>` against the existing Phoenix account POST routes. All product account routes use the Inertia pipeline so requests receive redirect conversion, carried validation errors, flash data, shared authentication state, and CSRF handling. The browser pipeline remains available only for LiveView and development/system HTML routes and does not need `Inertia.Plug`.

Each controller keeps Accounts and UserAuth calls presentation-independent. GET actions render named Inertia pages and mutation failures assign scoped errors before a see-other redirect. The internal `/api/users/register` route, JSON response mapping, HEEx-specific branches, auth HTML view modules, and auth templates are removed.

Keeping custom `fetch` calls was rejected because it duplicates CSRF, processing, response parsing, and error-state behavior already supplied by Inertia. Retaining HEEx fallbacks was rejected because the application has chosen Inertia as its product presentation boundary and parallel auth pages would duplicate layout, form-state, accessibility, and test contracts without changing the server security model.

### Reuse account forms across the modal and direct pages

The dialog chrome remains responsible only for native modality, close behavior, and focus restoration. A reusable Svelte account surface owns Register and Login modes and is rendered both inside the dialog and on the direct `/users/register` and `/users/log-in` pages. The direct page selects its initial mode from the controller and can switch routes through Inertia links without copying form markup.

Magic-link confirmation and account settings remain separate page components because their states and authorization differ from guest account entry. Confirmation receives only the email, token, confirmation status, and reauthentication state needed to submit the existing token action. Settings receives the current email and exposes independent email and password forms with isolated error bags. A stale sudo session still redirects to `/users/log-in`; that Inertia page pre-fills and locks the authenticated email and explains the reauthentication requirement.

### Keep one native account dialog with explicit modes

Rename the registration-only component to a shared account dialog with local `register | login` mode. Register remains the initial mode when opened from the header. The existing-user and new-user actions are native buttons that switch modes without navigation, preserve the entered email, clear stale result and error state, update the accessible title, and focus the first field in the new mode.

Only the active top-level mode is rendered. Login mode renders both supported sign-in forms because magic link and password are simultaneous alternatives, separated from each other and from provider placeholders. This avoids BGA's accessibility-tree problem where visually hidden inactive steps remain reachable.

Native `<dialog>.showModal()` owns modality and focus containment. The component does not implement a manual Tab trap. It explicitly focuses the first active email input after open or mode change, supports the native Escape close, provides an explicit close button and backdrop close, and restores focus to the header trigger.

The dialog keeps one inline size and lets CSS derive its block size directly from the active mode's content. Mode changes do not measure the DOM, write numeric block sizes, schedule animation frames, or retain resize timers. The title and description remain fixed while the content track becomes the scroller only when the natural size exceeds the viewport. Native intrinsic-size animation may be added as a progressive enhancement when it can animate content replacement without scripted measurement and without violating the browser support policy.

### Isolate the three form contracts with Inertia error bags

The forms use distinct error bags: `registration`, `magicLinkLogin`, and `passwordLogin`. Registration and both login forms may contain `email`, so error bags prevent one response from appearing in another form.

Email inputs use stable ids, `type="email"`, `autocomplete="username"`, `inputmode="email"`, and visually hidden programmatic labels while retaining `Email address` as the visible placeholder. The password form uses a required `autocomplete="current-password"` input and a show/hide password control. `Keep me signed in` is an unchecked checkbox that sends the existing `remember_me=true` value only when selected.

Registration success replaces the registration form with a check-email result. Magic-link success replaces only the magic-link form so password and provider alternatives remain usable. Invalid credentials produce one generic password-form error and never identify whether the email or password was wrong.

### Preserve current-page return through a validated session value

Account forms keep the immediate form response separate from the eventual post-authentication destination. `response_to` returns validation, delivery, and check-email states to the surface that submitted the request, while `return_to` is stored for the later authenticated redirect. `D20Web.UserAuth` accepts either value only when it is a local absolute path with no scheme, host, or protocol-relative prefix.

In the modal both values are the current Inertia page. Direct registration and login pages use their own URL for `response_to` so their result remains visible, while `return_to` remains the prior protected page or the signed-in fallback. Password success reads the stored destination before session renewal and redirects back after authentication. Registration and magic-link requests retain it so a confirmation link opened in the same browser session returns to the intended page after the existing confirmation POST. Missing, external, or malformed values use safe route-specific fallbacks.

Accepting an unchecked redirect target was rejected because it would create an open redirect. Relying only on the Referer header was rejected because it may be absent and does not express the intended return contract as clearly as a validated form field.

### Keep provider choices visible but inert

Register and Login modes show the same Google, Facebook, Apple, and Discord identities with mode-specific copy. Buttons remain disabled, include visible unavailability text, and do not submit, navigate, or start authorization. Provider-specific issues own future routes, callback security, identity linking, and account completion.

Provider marks remain ordinary SVG assets imported as trusted build-time strings through Vite's `?raw` query and inserted inline with Svelte's `{@html}` directive. Their SVG roots use `currentColor` and fill the parent icon box, so the dialog owns sizing and vertical alignment without static SVG-only Svelte components or a global descendant selector.

### Test application behavior through standard Svelte render APIs

Component tests use the maintained render lifecycle supplied by Svelte Testing Library in the unit environment and Vitest Browser Svelte in browser mode. Page tests must not add local `mount` wrappers or Svelte harness components that only reshape and forward props. A fixture component remains justified only when it supplies meaningful context, a slot composition, transport, timers, or another environment that the subject actually requires.

The Inertia test double remains an application boundary: tests verify the routes, payloads, options, form states, and callbacks requested by D20 code. They do not reproduce or assert Inertia's internal navigation, history, persistent-layout, or transport implementation. Component teardown tests use the renderer's standard `unmount` result, and prop-response tests use its standard `rerender` result.

## Risks / Trade-offs

- [Multiple forms share the email field name] -> Use a separate Inertia error bag for every form and clear local form errors on mode changes and close.
- [An Inertia redirect could close or remount the dialog] -> POST visits preserve state, redirect back to the same page, and use form success/error callbacks; password success intentionally removes the guest dialog when `authenticated` becomes true.
- [A submitted response or return path could become an open redirect] -> Validate both through one local-path function and keep route-specific fallback redirects.
- [Passwordless registered users may try password login] -> Keep magic link first and always available; password failures remain generic.
- [Magic-link delivery success cannot reveal account existence] -> Preserve the generated generic success message whether or not the email exists; production delivery diagnostics remain operational work.
- [Direct pages and the dialog could drift] -> Reuse the same account surface and form contracts rather than duplicating their markup.
- [The worktree contains unrelated in-progress changes] -> Limit implementation edits to auth controllers, routing, UserAuth, shared account UI, focused tests, and the two coordinated OpenSpec changes.
- [The complete Login layout is taller than some laptop and mobile viewports] -> Constrain the content-driven dialog to the viewport and use the content scroller when it does not fit.
- [Intrinsic block sizes cannot transition consistently across supported browsers] -> Prefer natural CSS layout and accept an immediate mode-size update rather than adding scripted measurement and frame scheduling for a decorative transition.
- [Test helpers can accidentally reproduce framework behavior] -> Use standard Svelte renderers, keep the Inertia double at the call boundary, and test only D20-owned state and lifecycle.

## Migration Plan

1. Revise the active email-registration design, requirement, and tasks to use the shared Inertia account dialog.
2. Route all product account journeys through the Inertia pipeline and remove HEEx response branches and auth templates.
3. Replace the registration-only component with a reusable account surface used by the switchable dialog and direct auth pages.
4. Add focused Inertia pages for magic-link confirmation and settings, including the sudo reauthentication state.
5. Update controller and frontend coverage for the forms, error bags, accessibility, direct URLs, and session return.
6. Run targeted checks, broad repository validation, archive `add-email-account-registration`, then archive this change.

No data migration or coordinated game-module release is required. Rollback restores the removed auth HTML modules, templates, and browser routes while retaining all existing users, passwords, tokens, and sessions.

## Open Questions

None. Username and provider authentication remain independently tracked features, and production mail delivery remains separate delivery work.
