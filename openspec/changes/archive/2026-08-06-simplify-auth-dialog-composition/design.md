## Context

`AuthPanel` originally supported both the modal account entry and standalone auth pages. The standalone pages were later removed, leaving `AuthDialog` as its only consumer. `AuthDialog` currently keeps the panel mounted while closed and increments `panelVersion` on every opening so a keyed block destroys stale form state.

The application header is the sole `AuthDialog` consumer and already owns whether the dialog is open. The account surface contains registration, magic-link login, password login, mode switching, transient results, and Inertia form state. Closing the dialog is an explicit abandonment boundary, so none of that state needs to survive until the next opening.

The workspace also has a component named `Dialog`, but it is a permanently shown non-modal game surface with fullscreen behavior. It does not share the auth modal's lifecycle, dismissal, accessibility naming, surface, or backdrop contract.

## Goals / Non-Goals

**Goals:**

- Make one `AuthDialog` own the complete modal account-entry experience.
- Destroy the complete auth dialog instance when it closes so reopening starts with clean state without numeric remount versions.
- Preserve mode switching within one opening, including email continuity between Register and Login.
- Preserve existing Inertia form actions, flat form-local error handling, success states, accessible names, focus behavior, layout, and server prompts.
- Remove the obsolete Shared export and component file.

**Non-Goals:**

- Change Phoenix Accounts, routes, sessions, form payloads, return paths, or authentication security.
- Change account copy, provider availability, or visual design.
- Generalize the workspace non-modal game surface and the auth modal behind one conditional dialog component.
- Move account entry into a new Feature or Entity layer.

## Decisions

### Render `AuthDialog` only while the header state is open

The header conditionally mounts `AuthDialog` when `authOpen` is true. The dialog notifies the header when its native close event fires, and the header then removes the complete component. Reopening creates a new instance with fresh local variables, DOM fields, and Inertia `Form` components.

This directly expresses the chosen lifecycle: close means abandon. Keeping a permanently mounted component and manually resetting every present and future field was rejected because the reset list can drift. A numeric version key was rejected because it encodes destruction indirectly even though the parent already owns the open boundary.

### Inline the account surface into `AuthDialog`

Move the state, markup, icon imports, and scoped styles from `auth_panel.svelte` into `auth_dialog.svelte`. Remove props that only existed to support page and dialog variants. Keep the established auth class names so the move does not introduce unrelated visual churn.

The separate component was rejected because it now has one consumer and no independent contract. Moving the large form markup inline is accepted because the resulting component has one cohesive responsibility: the complete account-entry modal.

### Use mode branches instead of form-version remounting

Register and Login remain mutually exclusive rendered branches. Switching mode already destroys the inactive branch and its Inertia forms, so the numeric `formVersion` key is unnecessary. Local result and password-visibility state is reset during a mode change while the shared email value remains in the enclosing dialog state.

### Keep the workspace dialog local

The workspace component uses `dialog.show()` and exposes fullscreen state to a game surface. `AuthDialog` uses `showModal()` and close, backdrop, focus, and form semantics. A common wrapper would need variant flags for nearly every meaningful behavior and style while sharing only the native element name. Native `<dialog>` remains the common platform primitive; an application-level modal wrapper can be reconsidered after a second modal with the same lifecycle exists.

## Risks / Trade-offs

- [Merged component becomes large] -> Accept the size because splitting the only account surface produced an artificial public abstraction; retain cohesive sections and existing class names for readability.
- [Scoped CSS changes during the move] -> Copy the effective dialog variant styles into the merged component and verify desktop and narrow viewport browser tests.
- [Form state accidentally survives close] -> Mount the complete `AuthDialog` conditionally in the header and cover close followed by reopen in browser mode.
- [Mode switching loses the shared email] -> Keep email in dialog-local state above the mutually exclusive mode branches and retain the existing mode-switch browser assertion.
- [Unrelated dirty worktree changes are overwritten] -> Restrict edits to the auth dialog, its obsolete component/export, focused header tests, and this OpenSpec change.
