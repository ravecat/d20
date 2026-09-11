## Context

[Issue #278](https://github.com/ravecat/d20/issues/278) tracks a presentation-only correction in the Phoenix/Inertia/Svelte shell. The isolated worktree starts clean at `caac3ad2`; the existing game page test suite passes all 17 tests before changes. Other active changes and worktrees own favorites, discovery, footer content, and header geometry, so this work must not absorb their unfinished tasks.

At the start of the matrix continuation, the contrast implementation and its validation record remained uncommitted in this worktree. Its prematurely archived OpenSpec change was reactivated for the user's accepted visual matrix. The config then had three repeated viewport projects ordered by `sequence.groupOrder`, and selected native dark states were separate story exports. The installed Storybook Vitest integration already accepted `initialGlobals`, and the shared native screenshot hook ran after the story lifecycle. The existing unit and standalone browser projects retain their current ownership; their migration is separately tracked by issue #280.

The existing development browser reproduces the report with Dark Reader dynamic rendering enabled, document `data-theme="light"`, stored `phx:theme=light`, and dark `prefers-color-scheme`. This is an external color transformation of the light page, distinct from selecting the application's native dark theme and from accessibility `forced-colors` mode.

The initial visible failures map to these declarations:

- `assets/js/pages/game/ui/game.svelte` gives both description and activation panels `color-mix(in oklab, var(--color-base-100) 94%, var(--color-base-200))`. In the reproduction, the mixed surface remains pale while the descendant foreground becomes pale.
- `assets/css/app.css` applies `color-mix(in oklab, var(--color-base-content) 72%, black)` to hovered, keyboard-focused, and current-page anchors. Its fixed black contribution can leave the header brand and other links dark on the transformed dark surface.

Further live inspection identifies a shared delivery problem: the transformation's synchronized stylesheet retains the first `@layer base` block but drops later same-name blocks containing theme variables. The corresponding transformed theme-variable values are missing, which can affect direct token backgrounds as well as `color-mix` backgrounds. Temporarily providing the current theme declarations outside those layers restores provider and metadata colors together. Generated nested `@supports` fallback rules around the global link color also require inspection because the transformation leaves that nested interactive rule unprocessed.

This evidence supersedes the initial assumption that every failure requires a component-level color replacement. Other components contain related opaque mixes, but a source match alone does not prove failure. Several token/transparent mixes are recolored correctly and should remain unless their rendered result fails inspection.

A live trial compiled the actual application CSS through the already installed LightningCSS 1.32.0 with `Features.Nesting` included and `minify: false`, then provided that accessible compiled stylesheet to the same prepared browser. The compiler merged ten repeated base-layer blocks into one and hoisted nested support conditions. Transformed theme variables became available again, the auth panel, fields, and provider controls rendered dark surfaces with readable pale text, and hover rules were processed. This verifies the chosen shared compiler boundary while leaving the authored theme palette unchanged.

A paired trial loaded that same transformed stylesheet without and with `crossorigin="anonymous"`. Without it, CSS rules were inaccessible and the transformed variables disappeared; with it, transformed variables and readable dark surfaces returned. Both compilation and accessible stylesheet loading are required for this reproduction.

## Goals / Non-Goals

**Goals:**

- Make game-detail text, metadata, forms, and actions readable on their panel backgrounds in the reproduced forced-dark browser.
- Keep the D20 linked brand and shared navigation/content links readable through pointer, keyboard-focus, and current-page states.
- Inspect the existing shell page families and fix further demonstrated color-pair failures at the owning CSS declaration.
- Preserve native light and dark themes, semantic states, responsive composition, and accessible focus treatment.
- Cover every discovered story in both native themes and all three existing viewports without theme-only catalog entries.
- Keep the native comparison mechanism and make the theme and viewport explicit in reviewable reference paths.

**Non-Goals:**

- Detecting a browser extension, shipping extension-specific CSS, disabling the external transformation, overwriting `phx:theme`, or changing theme selection policy.
- Removing every `color-mix`, replacing the theme palette or toolchain, upgrading unrelated dependencies, redesigning the shell, changing spacing, or introducing a general-purpose theme abstraction.
- Changing backend behavior, routes, data, persistence, game rules, public protocols, third-party reference renderers, or separate embedded-game repositories.
- Deploying a server, integrating into primary master, or completing other active changes.
- Adopting the trial visual addon, changing image comparison tolerances, or migrating the standalone browser environment under issue #280.

## Decisions

### Correct shared theme and CSS delivery before changing components

Set Vite's `css.transformer` to `lightningcss` and configure `css.lightningcss` to derive compiler targets with `browserslistToTargets` from the existing package Browserslist policy. Include `Features.Nesting` so CSS nesting is lowered even when the supported browsers understand it natively. Keep the JavaScript target and source policy unchanged. Promote the already locked `lightningcss` 1.32.0 to a direct development dependency because Vite configuration imports its API; do not depend on its incidental transitive installation.

Disable the redundant style pass in `vitePreprocess` (`style: false`), since existing Svelte styles use plain CSS. Svelte must lower its `:global` syntax before Vite transforms the emitted CSS; the script preprocessor and virtual CSS/HMR imports remain enabled.

Use the existing Tailwind/daisyUI output as input to this normal Vite transformation. LightningCSS performs the demonstrated layer consolidation and nested-rule lowering without a custom CSS parser or post-build patch. Inspect development-served and production-compiled output because the browser consumes generated CSS, not the source file directly. Preserve the existing JavaScript and independent CSS manifest entries and HMR boundary.

Use existing semantic theme definitions as the single source of truth. Do not duplicate the complete palette as hard-coded runtime overrides, manually flatten unrelated layers, introduce extension detection, or add a second compiler library. Confirm that explicit light, explicit dark, and the existing system preference behavior still resolve the same theme values. The diagnostic temporary browser declaration is replaced by the production asset pipeline, not shipped as a runtime override.

Pass `crossorigin="anonymous"` through both existing `PhoenixVite.Components.assets` root-layout invocations and verify it on their rendered stylesheet links and actual separate-origin development CSSOM access. Reuse the existing Vite CORS response instead of broadening server access policy. Add focused rendering coverage for both root templates; preserve JavaScript loading, manifest URLs, CSRF, authentication, and page rendering.

After that shared correction, retest the initial panels, provider actions, metadata, and link states before considering per-component edits. If a declaration still produces an observed contrast failure, use the closest existing semantic surface/content pair at that declaration. For a remaining global interactive-link failure, preserve readable component foreground roles and existing non-color focus treatment while eliminating only the problematic composition.

Inspect component-specific cascades: inverse buttons, artwork overlays, and workspace controls can require their existing foreground roles. Preserve the brand's nonrectangular keyboard-focus underline. Do not add blanket `!important` overrides or extension selectors.

The alternatives of changing each visible component, changing only panel text, or forcing the application's dark theme leave the shared variable-delivery cause unresolved or replace the user's selected theme. A broad build-tool replacement would exceed the demonstrated need. The already installed compiler provides the verified correction through Vite's existing configuration boundary.

The final hover audit found two residual failures after compiler correction: the global interactive anchor selector still overrode component foregrounds, yielding 4.15:1 for authentication providers and 3.59:1 for account provider actions under Dark Reader 4.9.130. Lower the shared rule specificity with `:where(a[href])`, retaining its existing pseudo-classes and color mixture. Explicit component foregrounds then win for provider and inverse controls, while the D20 brand and ordinary unstyled content links retain the existing interactive treatment processed by the corrected CSS pipeline. This resolves the common cascade cause without adding repeated component overrides; existing hover surfaces, borders, and focus indicators remain intact.

The native carousel focus comparison also detects a compiler optimization that merges adjacent `transform: none !important` and `translate: none !important` into a 3D transform and drops the independent translation reset. Use the equivalent `transform: initial !important` to preserve both reset declarations. The existing Chromium and Firefox focus snapshots must pass unchanged; do not accept geometry changes as new baselines.

The final production-preview audit also reproduces a pale information-notification surface with pale text. Dark Reader leaves the background mixture unresolved when its accent passes through `--inline-notification-accent`. Reference the existing severity color directly in each severity background mixture; retain the shared accent alias for borders/icons and preserve the exact native tint. A temporary direct-info-token trial restores the dark surface. Apply the same surface expression to warning and error variants, then verify all three.

### Bound the wider audit by rendered evidence

Use this inventory to record coverage and outcomes in the owning task artifact during implementation:

| Area | Existing pages or production components | States to inspect |
| --- | --- | --- |
| Persistent shell | Header, D20 brand, account actions, footer and content links | Guest/authenticated, expanded/compact header, default, hover, focus-visible, current-page where present |
| Discovery and public information | Home/catalog, About, Contact, Rights holders, Developers | Headings and linked headings, cards, metadata, empty content, footer links |
| Game detail | `game.svelte`, shared metadata labels, session and interest forms | Play, Lobby, unavailable interest, Requested, pending/error states, description |
| Authentication and profile | Shared auth dialog, confirmation, registration completion, account settings | Login/registration, provider hover, linked/unlinked provider actions, form errors, success, pending/disabled controls |
| Shared runtime feedback | Inline notifications, shell workspace controls | Error/success feedback, control hover/focus, Compact and Theater, reconnecting/failed states |

Candidate declarations include metadata-label backgrounds, auth-provider hover backgrounds, account provider-action backgrounds, inline-notification surfaces, and workspace control hover surfaces. Inspect them in context, including compositing over their actual parent, before choosing a change. Record unchanged families as inspected rather than altering them to create uniform source syntax. Public routes that are drafts or absent from the current router are not new pages to implement.

### Separate native-theme regression evidence from forced-dark evidence

The current automated theme toolbar and CSS media emulation do not reproduce Dark Reader's dynamic stylesheet rewriting. Keep the integrated reproduction in the selected existing development page using `devtools-validations`; record the URL, transformation mode, document theme, relevant computed colors, screenshots, and final outcomes. Restore prepared route, viewport, and theme state after the audit and avoid submitting real authentication, account, interest, or session actions for visual verification.

Use deterministic production-component Storybook stories for native light/dark visual and interaction coverage. Reuse existing game, Home/auth, account-settings, footer, and workspace stories where they cover affected states, adding only missing meaningful states. New interactions belong in story `play` functions, without duplicating those scenarios in standalone UI tests. Theme differences are supplied by the visual project matrix described below. Review the generated references at desktop `1280x720`, tablet `1024x640`, and mobile `320x900`; accept only intentional visual changes and rerun normal comparisons.

Check foreground/background contrast for the corrected ordinary text and enabled link/action labels: at least 4.5:1 for ordinary text and 3:1 for large text. Inspect focus indicators and meaningful icons against adjacent colors, and ensure disabled and pending labels remain perceivable without converting them into enabled controls. The correction does not expand into an unrelated whole-site accessibility redesign.

Run the existing focused game, header, and any additionally affected behavior suites, followed by frontend format/lint, type checking, and asset build commands from the manifests. Inspect the resolved Browserslist targets and verify emitted development and production CSS through the same acceptance scenarios. Run focused rendering/controller tests for both root templates and applicable Elixir formatting checks as well. The original `bun run test -- tests/pages/game/ui/game.test.ts` result is baseline evidence, not validation of the fix. Normal Storybook comparison proves native visual behavior; it must not be reported as proof of the external forced-dark transformation.

### Generate native visual projects from theme and viewport lists

Define `light` and `dark` themes and the existing `desktop`, `tablet`, and `mobile` viewport names once in `assets/vite.config.mjs`. Use the Cartesian product to construct six flat Vitest project configurations with Chromium instance names `visual-<theme>-<viewport>`. Keep viewport dimensions in the existing Storybook preview configuration. No nested project hierarchy or duplicated scenario manifest is needed.

For each generated project, pass `initialGlobals: { theme, viewport: { value: viewport } }` to `storybookTest`. These globals configure the story context before decorators, render, and `play`; the existing `withThemeByDataAttribute` decorator applies `data-theme` at render time. The unchanged screenshot hook then waits for declared fonts and uses native `toMatchScreenshot()` after the interaction lifecycle. No screenshot-time button click, browser media emulation, late theme mutation, or custom comparator is introduced.

Remove theme-only Dark exports and their `globals.theme` overrides throughout `assets/stories/`. Retain all meaningful fixtures and interactions, including `HeaderFocused`, under their existing scenario names. The interactive catalog continues to switch themes through its existing toolbar, with the current default light theme. Neither the toolbar nor duplicated story exports drive automated theme selection.

Omit the previous `sequence.groupOrder` barriers so the six visual projects can run concurrently. Each visual project keeps `fileParallelism: false` and sequential test execution; no story uses concurrent execution. This permits independent themes/viewports to progress together while each project renders one story file at a time. Preserve the existing browser provider behavior, failure trace retention, and independent project trace directories.

Use a project-local native screenshot path resolver that closes over its theme and viewport. For example, two scenarios in the same source file produce:

```text
assets/__screenshots__/stories/pages/public/game.stories.ts/
  light/desktop/chromium/Requested-1.png
  light/desktop/chromium/Unavailable-Game-1.png
  dark/desktop/chromium/Requested-1.png
  dark/desktop/chromium/Unavailable-Game-1.png
```

The same scenario filenames repeat beneath `tablet` and `mobile`. The `-1` suffix remains Vitest's per-test capture index. Keep the existing root resolver for standalone browser tests, and leave references under `assets/__screenshots__/tests/` intact. Configure the native `resolveDiffPath` for visual projects with the same theme/viewport/browser hierarchy under `attachmentsDir`, because the default actual/diff paths omit the project and collide when projects run concurrently.

Update `test:visual` to select `--project 'visual-*'`. Native filters such as `--project 'visual-dark-*'` and `--project 'visual-*-mobile'` provide focused runs without another parser. Keep the existing unit and browser entries, filters, environments, browser set, and screenshot paths. Update the existing workflow documentation only where its project names, matrix, or paths become stale.

### Replace Storybook references through the native workflow

Migrate the 183 existing light/dark references byte-identically to their new paths, then run the native matrix to compare those references and create the 111 previously missing dark candidates. Review those candidates before a successful normal comparison; use explicit `--update` only if a reviewed intentional rendering change requires replacing an existing reference. Review representative paired light/dark captures and compare mapped prior references to distinguish the path migration from rendered changes. Account for every retained scenario in every matrix cell; theme-only aliases must not survive as scenarios or filenames. Remove obsolete viewport-first Storybook directories only after the new reference inventory is complete. Run the full matrix again without `--update` and record the result, then run the existing non-visual commands and frontend checks needed to verify their preserved behavior.

The earlier contrast audit and its command evidence remain historical evidence in `tasks.md`. The later matrix record separately establishes successful normal comparison of all 294 references and successful independent non-visual validation. Final synchronization, archive, issue reconciliation, and the completion commit remain delivery steps.

### Supply the missing mathematical glyph from a pinned font

Full-matrix validation reproduces an eight-pixel MaximumOnly difference in all three light projects; a focused repeat instead passes light and fails the three newly captured dark references. `fc-query` proves that both the primary Mono font and the installed Symbols 2 math font omit U+2264. Its font stylesheet name and successful download therefore do not guarantee glyph coverage. Replace the unused Symbols 2 fallback package/import/family with `@fontsource/noto-sans-math` 5.3.0, verify U+2264 in the actual WOFF2 charset, and keep the production/Storybook font boundary shared. Import its `latin-400.css` explicitly: that font file covers U+2264, while the package index stylesheet's Unicode ranges exclude the required character. Update only the six MaximumOnly references after reviewing the intended pinned glyph, then require a successful normal full matrix. Do not alter glyph semantics, introduce synthetic styling, delay captures arbitrarily, or relax pixel comparison.

### Isolate dependency caches for parallel visual projects

The installed Storybook addon 10.5.7 derives its Vite cache directory from `configDir`, so all six generated projects otherwise share a mutable dependency cache. A normal run was aborted after approximately nine minutes: two projects completed 98 assertions while four browser instances remained idle before story execution. The shared cache and startup behavior strongly support a cache collision as the explanation, but no browser network trace establishes the exact causal chain.

Override the addon's cache default with the small `visual-project-cache` Vite plugin using `enforce: "post"`, assigning each visual project its own ignored `.vitest/cache/<project-name>` directory. Distinct per-project `deps/_metadata.json` files verify the resolved cache separation. The replacement normal run passed all 78 story files and 294 tests with exit 0, and its execution intervals show a peak of six simultaneous story files. This validates the isolated-cache configuration while retaining project concurrency, capture behavior, and the native comparator. The historical shared-cache collision remains a strongly supported explanation rather than a claim of browser-network-trace proof.

### Pre-optimize the existing browser dependency before tests

After the lockfile change, a combined normal run reported late discovery of `@inertiajs/core` and an unexpected test-page reload, invalidating that validation attempt. Add the dependency to the existing standalone browser project's `optimizeDeps.include` so it is optimized during startup rather than during a running test. Preserve the browser test include patterns, mocks, browser set, viewport, and reference paths. This is runner stabilization for the current matrix validation, not the environment migration tracked by #280.

The following combined non-visual run no longer reloaded for late optimization. It passed its test assertions but exited nonzero when an existing real Phoenix socket reconnect timer fired after the auth unit test's DOM teardown. Review traces that socket import to the unchanged shared-store barrel, independently of the matrix. Keep this outcome separate from the optimization correction and record independent unit/browser results and the combined-run limitation rather than reporting the assertion count as a successful process result.

## Risks / Trade-offs

- External color transformers vary by configuration and version. Mitigation: record and retest the concrete reproduced environment; claim coverage for observed behavior rather than universal extension compatibility.
- Changing color indirection can change external recoloring. Mitigation: keep the exact native severity tint expressions and inspect all severity surfaces after transformation; the reference path migration must not conceal unexpected rendering changes.
- A global link rule reaches custom surface contexts. Mitigation: inspect the actual default/hover/focus/current cascade for header, footer, body links, and inverse controls before accepting the change.
- CSS layer placement or compilation changes can alter precedence outside the initial panels. Mitigation: preserve theme selection and cascade ordering, compare emitted development and production output, and validate the representative native-theme shell states.
- Anonymous cross-origin asset loading depends on the asset server's existing CORS response. Mitigation: inspect actual stylesheet loading and CSSOM access, cover rendered attributes if changed, and avoid credentialed requests or a broader CORS policy.
- Account and runtime edge states may be unavailable on a live page. Mitigation: use existing deterministic stories for complete state coverage and document which forced-dark checks were observed live or in an available prepared preview.
- Active changes share some CSS owners. Mitigation: keep every edit and reference attributable to issue #278 and leave other worktree contents and unrelated lifecycle artifacts untouched.
- Six concurrent visual projects increase browser and compilation load. Mitigation: keep each project's files and tests sequential, validate the complete matrix, and investigate resource failures without silently restoring ordered project groups or accepting unstable images.
- A retained story-level theme override would defeat matrix coverage. Mitigation: inspect the retained catalog for overrides and review paired native theme captures after generation.
- Reference migration expands dark coverage beyond the prior representative aliases. Mitigation: inventory each scenario across all six cells, inspect unexpected rendering differences, and require a normal comparison after acceptance.
- Existing capture clips rendered content below the Storybook iframe viewport in the EightPlayable desktop and ImageMetadata tablet cases, even though the PNG extends further. Mitigation: record this pre-existing whole-document coverage gap in issue #281, preserve the current capture behavior during the matrix migration, and do not claim that passing matrix references verify content outside the captured iframe viewport. The whole-document specification remains unchanged pending that separate correction.

## Migration Plan

No persistence or API migration is required. The new-persisted-entity gate is inapplicable because this change adds no entities or storage. The dependency lock records the direct use of the already installed compiler, and normal frontend asset compilation carries the corrected styles; deployment is outside this local delivery. The Storybook migration replaces viewport-first references with theme/viewport references and removes theme-only aliases. Rollback restores configuration, scripts, story exports, and associated references together, along with the scoped CSS compilation/dependency declaration and necessary root asset-loading attributes, without data recovery or session migration.

The original contrast requirements and build-policy delta were synchronized before the uncommitted archive was reactivated. Their retained deltas now use `MODIFIED Requirements` against those existing working-tree specifications so the final native archive does not attempt to add the same requirements twice. The visual-regression delta updates its existing requirements and adds the scenario-independent theme contract. Matrix implementation and validation are complete; final synchronization and archive are recorded in `tasks.md`.

After implementation and required validation pass, reconcile this change's tasks and actual audit findings, synchronize the delta through the repository-native archive workflow, run `openspec validate --all --strict --no-interactive`, and verify that this change is absent from `openspec list --json`. Include the reconciled artifacts in the semantic completion commit.

## Open Questions

None blocking for this matrix implementation. The user selected the native six-project matrix, parallel projects with sequential work inside each project, the theme-qualified reference hierarchy, and removal of theme-only stories. The browser mechanism, shared compiler correction, and anonymous CORS requirement have been observed; their prior audit and validation limits remain recorded in `tasks.md`. The matrix, reference migration, failure-artifact paths, isolated caches, and pinned mathematical glyph are implemented and the full normal visual matrix has passed. Final delivery reconciliation is recorded in `tasks.md`; the pre-existing iframe capture coverage gap is tracked separately in issue #281, and the combined non-visual teardown and baseline shutdown limitations remain explicit in the verification record.
