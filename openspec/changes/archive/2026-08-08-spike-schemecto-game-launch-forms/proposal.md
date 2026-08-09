## Why

The session creation page currently relies on a D20-specific changeset serializer and field descriptor even though each game already exposes an Ecto changeset containing its input types, required fields, allowed values, and initial data. A focused Schemecto spike can determine whether the shell can replace that custom transport with a standard JSON Schema contract while preserving the existing session creation workflow.

## What Changes

- Add Schemecto as a commit-pinned dependency for converting existing game changesets to JSON Schema.
- Add SJSF with its basic renderer and AJV validator as the Svelte JSON Schema form implementation.
- Register the SJSF form ID builder through the required `idBuilder` option so generated controls can initialize and render.
- Integrate the SJSF basic renderer with the shell's DaisyUI theme tokens and restore the `Play` launch action label.
- Replace the game page's `attrs` prop with a `schema` prop containing the generated JSON Schema itself.
- Generate the self-contained form schema at the page controller boundary and encode the new-session changeset data as its root `default` annotation.
- Let SJSF generate the launch controls from JSON Schema without requiring backend-provided UI Schema or field ordering in this spike.
- Preserve the existing `POST /games/:slug/sessions` payload, authoritative server changeset validation, Inertia errors, processing state, and session initialization behavior.
- Remove the bespoke `D20.Form` descriptor serializer if the spike covers the current Koala Rescue Club and Next Station London launch forms.
- Remove the obsolete client-side `AttrConfig` projection contract and waiting-room setup controls now that creation attrs are submitted before the session exists.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-session-creation-attrs`: The game page receives a self-contained JSON Schema with game-defined creation defaults instead of a custom field descriptor map.

## Impact

- Affected backend modules: `D20Web.PageController`, the existing `D20.Game.changeset/2` boundary, and the removable `D20.Form` module.
- Affected frontend modules: the game page props, shared game form styling and session types, the no-session Play form integration, and the waiting-room Start action.
- Dependency impact: add the unreleased Schemecto repository at an exact commit, plus versioned SJSF form, basic theme, and AJV validator packages.
- API impact: the internal Inertia page prop changes from `attrs` to `schema`; the session creation HTTP request and game engine callbacks remain unchanged.
- Runtime and persistence impact: no session process, database, migration, channel, iframe, or game runtime contract changes.
- Rollback: restore `D20.Form.to_form/1`, the `attrs` prop, and the existing descriptor-driven renderer, then remove the Schemecto and SJSF dependencies.
- Tracking issue: [ravecat/d20#26](https://github.com/ravecat/d20/issues/26).
