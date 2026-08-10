## Context

The game page receives JSON Schema generated from each engine's Ecto changeset and passes it to one shared SJSF configuration. The compatibility resolver maps a schema `enum` to SJSF's enum field, whose default `selectWidget` currently renders a native select. The installed basic theme also provides a radio widget, and the shared stylesheet already covers its public `.sjsf-radio` class.

JSON Schema describes allowed values but does not prescribe their presentation. The current game launch enums are short setup choices, and the product decision is to expose those choices directly instead of requiring users to open a select.

## Goals / Non-Goals

**Goals:**

- Render every direct single-value enum in a game launch schema as native radio controls by default.
- Apply the policy in the shared SJSF adapter without naming game-specific properties.
- Preserve schema defaults, typed values, validation, Inertia submission, and server authority.
- Keep non-enum controls and SJSF combination selectors on their existing widgets.

**Non-Goals:**

- Do not add UI Schema to the backend JSON Schema contract.
- Do not infer widget choice from a property name such as `sheet`.
- Do not change multi-value enums, boolean controls, session payloads, or game changesets.
- Do not add a dynamic option-count heuristic in this change.

## Decisions

1. The shared theme conditionally resolves `selectWidget` to the basic theme's radio component when the component config contains a direct `schema.enum`.

   This makes the policy apply to every game and every enum property while leaving other consumers of `selectWidget`, such as schema combinations, on the basic theme fallback. Importing and resolving the existing radio component preserves SJSF's value mapping, event handling, validation, labels, keyboard behavior, and native input semantics.

   Alternative considered: add a `sheet` entry to `launch_form.svelte` UI Schema. That couples the generic launch form to Koala Rescue Club and does not help future games.

   Alternative considered: replace `selectWidget` unconditionally. That would also turn non-enum SJSF selectors into radios and makes the shared policy broader than the requested enum behavior.

2. The backend continues to send plain JSON Schema without presentation annotations.

   The controller and game engines remain responsible for types, allowed values, requirements, defaults, and authoritative validation. Widget choice stays in the shared frontend form adapter, so submitted values retain the same flat shape and types.

   The shared radio style uses `--color-base-content` for its native accent, producing a neutral dark control in the light theme and a neutral light control in the dark theme. Checkbox accents remain on `--color-primary`.

3. Tests assert semantics and payloads at the existing frontend layers.

   Browser coverage queries radio controls by role and accessible option name, verifies the declared default is checked, and retains responsive activation layout coverage. The focused component test changes the selected radio and verifies that Inertia receives the selected enum value. Tests do not depend on SJSF DOM depth or styling classes.

4. Radio and multi-checkbox groups use a single-column grid.

   Every choice occupies a separate full-width row with the same `2.5rem` minimum interaction height as the submit action, keeping game setup options immediately scannable regardless of label length. Labels allow text wrapping and cannot force the form beyond its container.

## Risks / Trade-offs

- [Risk] A future enum with many values could make the launch panel too tall. -> Keep the global radio policy explicit and allow that concrete form to supply a frontend UI override back to a select when the need appears.
- [Risk] Overriding the wrong SJSF component could affect combination controls. -> Resolve radio only when the widget config contains a direct `schema.enum`, and retain browser coverage for the generated enum.
- [Risk] A future SJSF upgrade could change component compatibility. -> Keep type checking and focused browser tests in the validation boundary.

## Migration Plan

1. Add the installed basic-theme radio component to the shared conditional theme resolver.
2. Update focused unit and browser expectations from combobox semantics to radio semantics.
3. Run frontend formatting, linting, type checking, unit tests, and browser tests.

Rollback removes the conditional resolver and restores the basic theme's select widget. No backend or data migration is required.

## Open Questions

None.
