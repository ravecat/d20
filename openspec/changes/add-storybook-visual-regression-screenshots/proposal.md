## Why

D20 stories make important isolated UI states reviewable, but the catalog and Vitest suites currently have separate validation lifecycles and no automated rendered-pixel regression boundary. Integrating Storybook discovery with Vitest Browser Mode lets every deterministic story become a reviewed visual contract without duplicating fixtures or introducing another test runner.

Owning issue: https://github.com/ravecat/d20/issues/243

## What Changes

- Integrate the existing Storybook catalog with the official Storybook Vitest addon while preserving the current unit and Chromium/Firefox browser projects.
- Run every discovered story as a real Chromium browser test at named desktop (`1280x720`), tablet (`1024x640`), and mobile (`320x900`) viewports.
- Compare the complete rendered story document after its render and optional `play` lifecycle against committed Vitest screenshot references.
- Keep reviewed references under `assets/__screenshots__/stories/<story-file>/<viewport>/chromium/<story>.png`, with plain `desktop`, `tablet`, or `mobile` viewport directories and the single supported `chromium` browser directory, while ignoring actual, diff, trace, and HTML report output.
- Use the pinned Linux Chromium reference environment without custom font, color-profile, or text-rendering launch overrides.
- Pin the shared production and Storybook text font as a lockfile-managed self-hosted Fontsource variable font, and keep the global synthesis and smoothing declarations so glyph outlines no longer depend on host font lookup or a runtime Google Fonts request.
- Document only the essential Chromium setup, normal comparison, explicit baseline update, and reference-review workflow through existing repository commands.
- Keep stories deterministic and independent from Phoenix, live channels, Inertia submissions, workspace transports, and external game iframes.

## Capabilities

### New Capabilities

- `storybook-visual-regression`: Defines automatic three-viewport visual comparison for every discovered Storybook story, native Vitest review artifacts, explicit baseline acceptance, and preservation of existing non-visual tests.

### Modified Capabilities

None.

## Impact

- Affects shared frontend CSS, dependencies, and artifacts under `assets/css/app.css`, `assets/package.json`, `assets/bun.lock`, `assets/.storybook/`, `assets/vite.config.mjs`, `assets/__screenshots__/`, ignore rules, and contributor documentation.
- Adds version-aligned Storybook Vitest and Vitest UI development dependencies without adding a second browser runner or cloud service.
- Expands `mix assets.test` and `just check` through the existing `assets` test script so visual drift fails repository validation.
- Adds one pinned production font dependency and changes global production text rasterization without changing component structure or behavior, Phoenix routes or runtime, persistence, session contracts, iframe module contracts, migrations, or deployment behavior. Rollback removes the Storybook Vitest projects, shared screenshot hook, references, added development dependencies, font dependency, and global text-rendering declarations while leaving existing unit, browser, and static Storybook validation intact.
