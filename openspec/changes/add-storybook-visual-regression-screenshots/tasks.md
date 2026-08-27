## 1. Add version-aligned Storybook test tooling

- [x] 1.1 Add `@storybook/addon-vitest` and `@vitest/ui` at versions aligned with the existing Storybook and Vitest packages, then update `assets/bun.lock` without unrelated dependency upgrades.
- [x] 1.2 Register the Vitest addon in `assets/.storybook/main.ts` while preserving the existing docs, accessibility, alias, and static-build configuration.
- [x] 1.3 Define desktop (`1280x720`), tablet (`1024x640`), and mobile (`320x900`) viewport options in `assets/.storybook/preview.ts`, with desktop as the interactive default.

## 2. Integrate generated stories with Vitest screenshots

- [x] 2.1 Add `assets/.storybook/vitest.setup.ts` with one shared post-test `document.documentElement` screenshot assertion.
- [x] 2.2 Extend `assets/vite.config.mjs` with explicit desktop, tablet, and mobile Storybook Chromium projects, pre-render viewport globals, a non-scaling host context, deterministic project and file ordering, failure-only traces, HTML output, and centralized screenshot-reference paths.
- [x] 2.3 Confirm the existing jsdom unit project and Chromium/Firefox browser project retain their current include rules, mocks, viewport, setup, and focused package scripts.
- [x] 2.4 Update Git, formatting/lint, and Docker context exclusions so `assets/__screenshots__/` references are tracked while `.vitest-attachments/`, `.vitest/`, and all test evidence stay outside production artifacts.

## 3. Prove and establish visual references

- [x] 3.1 Install the pinned Playwright Chromium build and prove one generated story creates a missing reference, passes normal comparison after review, produces actual/diff/HTML/trace evidence on a deliberate temporary mismatch, and updates only through explicit `--update`.
- [x] 3.2 Verify a story with a `play` function is captured after its interaction assertions without repeating the interaction or resizing after play.
- [x] 3.3 Generate and review desktop, tablet, and mobile Linux Chromium references for every currently discovered story, remove stale candidates, and pass a normal full-matrix comparison.

## 4. Document contributor workflows

- [x] 4.1 Keep `README.md` limited to pinned browser setup, normal visual comparison, explicit reference updates, and the tracked reference location.
- [x] 4.2 Update `assets/stories/README.md` so new deterministic stories automatically receive three-viewport visual coverage and continue to prohibit live Phoenix, Inertia, transport, and iframe dependencies.
- [x] 4.3 Document `assets/__screenshots__/`, `assets/.vitest-attachments/`, and `assets/.vitest/` ownership and clarify that screenshots supplement rather than replace semantic and cross-browser tests.

## 5. Validate and reconcile delivery

- [x] 5.1 Run focused frontend formatting, ESLint, TypeScript, and Svelte diagnostics for the changed configuration and documentation.
- [x] 5.2 Run the existing unit project, existing Chromium/Firefox browser project, each Storybook viewport project, and the complete frontend test command with normal comparison.
- [x] 5.3 Generate the documented HTML report, verify its image evidence, and build the static Storybook catalog without Phoenix or a live backend.
- [ ] 5.4 Run `just check`, `openspec validate --all --strict --no-interactive`, and `git diff --check`.
- [ ] 5.5 Reconcile the new capability into the authoritative OpenSpec specifications and update GitHub issue #243 completion criteria and evidence before archival.

## 6. Normalize the accepted reference environment

- [x] 6.1 Remove the custom Fontconfig file and Chromium font, color-profile, and text-rendering launch overrides while retaining the shared `1280x900` browser context.
- [x] 6.2 Name each generated browser project explicitly as `desktop`, `tablet`, or `mobile`, use that complete name directly in `assets/__screenshots__/<story-path>/<viewport>/<browser>/<story>.png` without runtime string rewriting, and update contributor commands.
- [ ] 6.3 Regenerate and review all current references, run repeated normal visual comparisons plus the complete frontend suite, and confirm no stale references or runtime artifacts remain.
- [x] 6.4 Allow the Browser Mode API server to select the next available port and verify a visual project starts while `63315` is already occupied.
- [x] 6.5 Remove the unnecessary Font Loading API wait from the shared screenshot hook and verify visual capture still runs after the Storybook lifecycle.
- [ ] 6.6 Pin the shared text font as an exact lockfile-managed Fontsource variable asset used by production and Storybook without Google Fonts or host font lookup, regenerate all references, and verify repeated unchanged comparisons do not produce text-only false positives.
