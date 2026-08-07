## Context

`Header` conditionally mounts `AuthDialog` only while the auth store is open. The child nevertheless compares the store's requested open state with the native dialog's `open` flag in an effect, even though mounting already represents the open transition. It also calls one `tick()`-based focus helper both after `showModal()` and from the local `switchMode()` handler. The existing specifications already require initial focus to enter the dialog and mode changes to focus the active mode's first field.

The native dialog algorithm honors `autofocus` when `showModal()` runs, but it does not provide the same lifecycle signal for replacing a conditional branch while the dialog remains open. Svelte must still wait for that branch update before focusing its bound input.

## Goals / Non-Goals

**Goals:**

- Delegate initial focus selection to native modal-dialog autofocus.
- Refocus the first active field after any store-driven mode change while the dialog is already open.
- Use component mounting for the open transition and the native dialog close event for the close transition.
- Represent ordinary Register opening and server-prompted Login opening with one store event.
- Keep password reveal state within the component that renders the password input.

**Non-Goals:**

- Change which field receives focus, including during sudo reauthentication.
- Add a custom focus trap or explicit post-close focus restoration.
- Change account forms, state transitions, routes, or responsive layout.

## Decisions

### Use native autofocus for dialog entry

Add `autofocus` to the bound registration email input and the bound first Login email input. The top-level mode branches are mutually exclusive, so only one autofocus target exists in the dialog at a time. `showModal()` can then select that field during its native focusing steps without a second application focus call.

The alternative was to keep calling `focus()` after `showModal()`. That duplicates a platform behavior already designed for native dialogs and obscures which element is intended as the initial target.

### Keep mode-switch focus in the shared handler

After the shared `switchMode()` handler triggers the synchronous store transition, it waits for `tick()` and focuses the currently bound active email input.

Keeping branch-switch focus in the single shared handler avoids separate `open` and `mode` selectors and avoids effect-specific scheduling guards.

The alternatives were a mode-aware effect, which requires narrower selectors and stale-continuation guards, and a per-input action, which would add another lifecycle abstraction for a single focus call.

### Use one-way native dialog lifecycle events

Call `showModal()` once from `onMount`, after Svelte has assigned the bound dialog element. The parent already mounts `AuthDialog` only when shared auth state is open, so a second open-state comparison inside the child duplicates that condition.

Make the explicit close button call `dialog.close()`. Escape, supported light dismissal, and the explicit action then converge on the native dialog's `close` event. The existing `onclose` handler resets shared auth state, which causes the parent to unmount the component. This produces one directional flow for each transition instead of continuously reconciling two open flags.

The alternative was binding or assigning the dialog's `open` attribute. That opens a non-modal dialog and does not provide the top-layer, backdrop, inertness, and focus behavior of `showModal()`.

### Use one open event with an optional prompt

Define the auth-store `open` event payload as `{ prompt?: AuthPrompt }`. Calling `open()` initializes a clean Register session. Calling `open({ prompt })` initializes Login mode, preloads the prompt email, and preserves the prompt for the requested authentication or reauthentication flow. Both paths reset the same transient result state.

The installed `@xstate/store` trigger type makes an all-optional payload argument optional, so the ordinary Register call remains `open()` rather than `open({})`. The alternative was keeping `openPrompt` as a second event whose transition duplicates the same session initialization fields.

### Keep password reveal state local

Declare `passwordVisible` with local Svelte `$state` in `AuthDialog`. The Show/Hide button keeps its text, accessible name, and `aria-pressed` value derived from that local state, while the password input continues switching its standard `type` between `password` and `text`.

Reset the local value when the shared mode-switch handler leaves Login. Closing the dialog already destroys the component and its local state. Removing `passwordVisible` and `togglePassword` from the auth store keeps the shared context limited to account-session facts used across dialog branches.

The alternative was directly mutating `HTMLInputElement.type`, which would require imperative synchronization of the button label and pressed state.

## Risks / Trade-offs

- [Multiple autofocus targets could make native selection ambiguous] -> Mark only the first input in each mutually exclusive top-level mode, leaving the second Login email input without `autofocus`.
- [The mode dependency could refocus during initial dialog entry] -> Give the `showModal()` branch precedence and schedule application focus only when the dialog is already open.
- [The conditional input binding is not updated when the handler resumes] -> Await Svelte `tick()` before reading and focusing the bound active input.
- [A future caller closes shared auth state directly while the dialog is mounted] -> Keep production dismissal paths inside `AuthDialog`; its native close event is the owner of the shared close transition.
- [A future unprompted direct Login entry is needed] -> Extend the open payload with an explicit mode instead of inferring a third meaning from the absent prompt.
- [Password remains visible after leaving and returning to Login] -> Reset local reveal state in the shared mode-switch handler and cover the round trip in the browser test.
