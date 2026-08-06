## Context

The shared account UI currently splits native modal behavior and visible surface ownership between two components. `auth_dialog.svelte` supplies a transparent, zero-padding `<dialog>`, while `auth_panel.svelte` supplies the border, background, shadow, and separate horizontal padding on its title, description, notices, and scrollable content. Those independent insets are close but not structurally shared, so content edges can drift as states are added or replaced.

Register mode also nests its separator and provider choices inside the registration form's success branch. A successful submission therefore removes most of the mode rather than only the completed email method, producing an avoidable dialog size change.

The existing worktree contains broader uncommitted authentication and app-shell changes. This change must remain limited to the account dialog, account panel, focused browser coverage, and its OpenSpec artifacts.

## Goals / Non-Goals

**Goals:**

- Keep the Register mode alternatives and mode switch rendered after email registration succeeds.
- Give dialog content one responsive inline alignment controlled by the native dialog surface.
- Preserve content-driven sizing, viewport constraints, internal scrolling, focus behavior, and current form contracts.
- Verify the result in the existing Vitest browser project at desktop and narrow viewport sizes.

**Non-Goals:**

- Change registration, login, email delivery, session, or redirect behavior.
- Add animation or scripted layout measurement.
- Change provider availability or implement provider authentication.
- Refactor unrelated app-shell or authentication work already present in the worktree.

## Decisions

### Replace only the completed registration method

Register mode will render either the email form or its check-email result in the same position. The first separator, provider choices, and Login mode switch will remain outside that conditional branch. This matches the existing magic-link Login behavior and keeps the surrounding mode structure stable.

Removing the entire registration body was rejected because provider alternatives remain valid after an email request and their removal creates a large decorative layout shift.

### Make the native dialog the visible dialog surface

The native `<dialog>` will own the border, radius, background, shadow, and common padding. Its dialog-mode `AuthPanel` child will retain semantic grouping and vertical flex layout but remove its duplicate surface and padding. The panel will use `gap` for vertical region spacing, while title, description, notices, and content use no independent horizontal padding.

Keeping the transparent dialog and consolidating padding on `AuthPanel` was rejected because it would improve alignment but would not establish the native dialog as the surface and positioning boundary requested for this UI.

### Preserve CSS-only intrinsic sizing and scrolling

The open dialog will be a constrained flex container so the dialog-mode panel can shrink within the available block size. The panel content remains the internal scroller for short viewports. No DOM measurement, numeric style writes, animation frames, or resize timers will be added.

Moving scrolling to the entire dialog was rejected because it would scroll the title and close action out of view and weaken the current fixed-chrome behavior.

### Assert user-visible state first and geometry only for the explicit layout contract

Browser coverage will locate forms, results, providers, and mode actions through accessible roles, labels, and visible text. Computed geometry will be inspected only where the requirement explicitly concerns surface ownership, common insets, and layout stability.

## Risks / Trade-offs

- [Transferring the surface changes the flex sizing boundary] -> Verify natural desktop height, success-state height delta, and 360 by 640 scrolling in the browser runner.
- [Focus outlines could be clipped by the dialog surface] -> Retain sufficient dialog padding around interactive controls and verify existing focus tests continue to pass.
- [The success message can wrap differently across fonts and widths] -> Require a bounded, not pixel-identical, height change while preserving the common inline size.
- [Existing uncommitted work can overlap the same files] -> Apply minimal patches and inspect the focused diff before validation.

## Migration Plan

1. Move the registration separator and alternatives outside the email form success conditional.
2. Transfer surface and responsive inset styles from the dialog-mode panel to the native dialog.
3. Update focused browser coverage and run frontend formatting, lint, typecheck, and targeted tests.
4. Roll back by restoring the prior conditional nesting and component-scoped surface styles if validation identifies a regression.

No data migration, deployment coordination, or runtime compatibility step is required.

## Open Questions

None.
