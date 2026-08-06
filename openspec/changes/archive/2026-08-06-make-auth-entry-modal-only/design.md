## Context

The shared shell already owns a native `AuthDialog` that posts registration, magic-link, and password forms to the Phoenix-generated auth actions. Separate `auth.svelte` GET pages duplicate those forms and are currently also used as redirect targets by `require_authenticated_user/2`, `require_sudo_mode/2`, and invalid magic-link handling.

The POST actions, Accounts functions, session rotation, remember-me cookie, magic-link confirmation POST, and safe `:user_return_to` session value remain authoritative. Magic-link confirmation and account settings need direct URLs because they are entered from email or protected account workflows. GitHub issue #21 tracks this change.

## Goals / Non-Goals

**Goals:**

- Use one modal presentation for registration, magic-link request, password login, and sudo reauthentication.
- Remove both standalone auth GET routes and their Svelte page slice.
- Preserve safe post-authentication return behavior and scoped Inertia form responses.
- Surface server-required login, sudo, and invalid-token states inside the shared dialog without query parameters.
- Retain direct magic-link confirmation and account-settings pages.

**Non-Goals:**

- Adding a password-reset token, forgot-password page, username login, or provider authentication.
- Changing account persistence, token formats, session lifetimes, remember-me behavior, or confirmation security.
- Moving magic-link confirmation or account settings into the dialog.

## Decisions

### 1. Carry server-requested dialog state through a one-time session prop

`D20Web.UserAuth` stores an `auth_prompt` map in the session before redirecting to the public home route. The Inertia pipeline exposes that map as a shared prop on the next request and deletes the session entry after assigning it. The prompt contains the mode, reauthentication flag, safe return path, and optional user-facing message.

This is preferred over query parameters because the prompt may contain transient security context and should not remain in browser history or copied URLs. It is preferred over preserving GET auth pages because those pages are the duplication being removed.

### 2. Use the home route as the server-prompt host

Requests rejected by authenticated or sudo plugs redirect to `/`, after first storing the protected local path in `:user_return_to`. Invalid and expired magic links also redirect to `/` with a Login prompt and an understandable message. The home route is always available through the Inertia shell and therefore provides a stable surface behind the dialog.

### 3. Separate immediate form response from authenticated destination

The header passes the current Inertia page URL as `responseTo` and the prompt's safe stored destination as `returnTo`. Validation and magic-link-request responses therefore return behind the still-open dialog, while successful password or token authentication uses the existing `:user_return_to` destination.

The persistent layout keeps locally opened dialogs mounted across Inertia redirects. A server prompt initializes the same dialog for the first render and is then consumed.

### 4. Render the dialog for guest and sudo states

The shared header renders one `AuthDialog` independently of whether the current actor is authenticated. Guests receive the Register trigger. Authenticated users do not receive guest actions, but a server prompt can open Login mode with `reauthenticate: true`, a locked account email, and sudo-specific copy.

### 5. Keep confirmation and settings direct; use magic link for recovery

`GET /users/log-in/:token` continues to render `auth_confirmation.svelte`, preserving explicit POST confirmation so link scanners cannot authenticate by GET. `/users/settings` remains the place to set or change a password after magic-link authentication. No parallel password-reset token or recovery page is introduced.

## Risks / Trade-offs

- [A non-Inertia client submits an auth form and loses local dialog state] -> All product auth forms are Inertia forms; server-prompted security redirects still work on a fresh request.
- [A structured prompt remains in the session] -> The Inertia pipeline deletes it on the first page request after assignment.
- [Authenticated headers previously omitted the dialog] -> Render one shared dialog for both authentication states and open it for authenticated users only from a trusted server prompt.
- [Removing GET routes breaks bookmarks] -> This is an intentional breaking change; no compatibility redirect is retained.
- [Closing a prompted dialog leaves `:user_return_to` stored] -> Preserve the existing Phoenix behavior; the next successful authentication consumes the same safe destination.

## Migration Plan

1. Add the one-time shared auth prompt and redirect rejected auth flows to `/`.
2. Extend the shared dialog and header to consume the prompt for guest and sudo states.
3. Remove the two GET routes, controller rendering actions, `pages/auth`, and direct-page tests.
4. Update route, controller, UserAuth, and browser coverage before deployment.

Rollback restores the GET routes and `pages/auth` while leaving Accounts data, tokens, and sessions compatible.

## Open Questions

None.
