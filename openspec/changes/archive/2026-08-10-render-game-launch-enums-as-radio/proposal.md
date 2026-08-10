## Why

Game launch enums usually contain only a few mutually exclusive setup choices, but the shared SJSF renderer currently hides them in a select. Showing these choices as radio controls makes them immediately visible and better matches the interaction model of compact game setup forms.

## What Changes

- Make radio controls the shared default for single-value enum choices in game launch forms.
- Keep JSON Schema and the submitted flat attrs payload unchanged.
- Preserve SJSF ownership of generated markup, value typing, validation, and accessible radio semantics.
- Place radio and checkbox choices in separate full-width rows with wrapping labels.
- Cover the shared default with browser and submission tests rather than adding a Koala-specific `sheet` rule.
- Allow a future exceptional form with many enum values to override the shared default back to a select through SJSF UI configuration.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-session-creation-attrs`: Single-value enum creation fields are presented as visible radio choices by default while preserving their typed submission contract.

## Impact

- Affected frontend modules: the shared SJSF theme configuration, shared form styling if required by the registered radio widget, and focused game page tests.
- Backend, JSON Schema, Inertia request, game engine, session runtime, persistence, migration, and iframe contracts remain unchanged.
- No new dependency is required because the installed SJSF basic theme already provides a radio widget.
- Rollback restores the basic theme's default select widget for enum fields.
- Tracking issue: [ravecat/d20#26](https://github.com/ravecat/d20/issues/26).
