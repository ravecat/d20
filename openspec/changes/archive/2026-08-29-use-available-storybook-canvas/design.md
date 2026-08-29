## Context

The Storybook viewport addon treats an absent preview-level viewport global as the unconstrained Reset viewport state. D20 currently sets `initialGlobals.viewport.value` to `desktop` in `assets/.storybook/preview.ts`, so interactive browsing always starts in a fixed 1280x720 iframe. Separate Storybook Vitest projects set their own viewport globals in `assets/vite.config.mjs`; those values establish deterministic responsive state before rendering and visual capture.

## Goals / Non-Goals

**Goals:**

- Let interactive Storybook use all canvas space until a contributor explicitly selects a named viewport.
- Preserve the existing named viewport options and deterministic visual-test matrix.
- Keep theme, controls, addons, and story behavior unchanged.

**Non-Goals:**

- Change viewport dimensions, visual-test project configuration, screenshot references, browser contexts, or supported responsive layouts.
- Add a synthetic viewport option representing the available canvas.
- Change production runtime behavior.

## Decisions

- Remove the preview-level `initialGlobals.viewport` entry rather than setting it to `undefined`, `null`, or a new option key. The absence of a selected value is Storybook's native Reset viewport state and avoids representing unconstrained canvas space as a fixed device.
- Retain `parameters.viewport.options` unchanged so contributors can explicitly select Desktop, Tablet landscape, or Mobile.
- Retain every `storybookTest({ initialGlobals })` viewport value in `assets/vite.config.mjs`. Interactive preview defaults and generated visual-test defaults have separate owners and different determinism requirements.
- Validate configuration through formatting, TypeScript/Svelte diagnostics, and a static Storybook build. Visual references do not need regeneration because test project globals and dimensions remain unchanged.

## Risks / Trade-offs

- [A previously selected viewport can remain encoded in a contributor's current Storybook URL or manager state] -> The configuration controls clean startup behavior; contributors can use Reset viewport once to clear an existing selection.
- [Removing the wrong global could affect deterministic screenshots] -> Limit the implementation diff to `assets/.storybook/preview.ts` and verify all three explicit plugin-level viewport globals remain in `assets/vite.config.mjs`.
