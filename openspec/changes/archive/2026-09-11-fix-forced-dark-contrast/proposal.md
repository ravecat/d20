## Why

Browser-forced dark rendering leaves game-detail description and activation panels pale while recoloring their text pale, making the content unreadable. The global interactive-link color also turns the D20 header brand dark against a dark surface; [issue #278](https://github.com/ravecat/d20/issues/278) owns correcting these failures and inspecting the other existing shell pages for the same problem.

Native-theme regression coverage must exercise the same story scenarios in both themes without duplicating the Storybook catalog with theme-only Dark exports. The user has authorized replacing the current visual configuration and references with a generated theme and viewport matrix as a continuation of this uncommitted correction.

## What Changes

- Restore readable game-detail panels, metadata, and activation content under the reproduced browser-forced dark rendering while retaining native light and dark presentation.
- Keep the header brand and other shell links readable in their default, hover, keyboard-focus, and current-page states, preserving existing focus indicators.
- Audit existing public pages, authentication and account screens, shared notifications, and workspace controls; correct additional color rules only when the audit demonstrates the same contrast failure.
- Correct the shared delivery of theme colors and affected generated CSS so external recoloring can keep surface and foreground roles synchronized. Apply local semantic-color changes only for failures that remain after the shared correction; preserve theme selection, page composition, and all existing loading, error, success, disabled, and pending behavior.
- Configure the existing Vite pipeline to transform CSS through the already locked LightningCSS compiler, lower nesting, and derive its targets from the current Browserslist policy. Keep the authored theme colors and promote the existing compiler version to an explicit development dependency.
- Make both Phoenix root asset references request stylesheets with anonymous CORS so their CSS rules are accessible to the browser transformation on the reproduced development-origin delivery.
- Lower shared interactive-link specificity so provider and inverse controls retain their authored foregrounds during hover and keyboard focus. Reference severity theme colors directly in notification surfaces so external recoloring resolves their background roles.
- Preserve the homepage carousel focus reset through CSS compilation without changing its existing visual references.
- Verify the forced-dark reproduction through the existing development browser. Generate six native Storybook visual projects from `light` and `dark` crossed with `desktop`, `tablet`, and `mobile`, applying both globals before each story renders and runs its interactions.
- Run visual projects in parallel with files and tests sequential within each project. Use flat `visual-<theme>-<viewport>` project names, an isolated dependency cache for each project, and the existing Vitest command surface for wildcard selection.
- Remove exports whose only distinction is a dark theme, retaining each meaningful scenario and the interactive theme toolbar. Replace all Storybook references with `assets/__screenshots__/<story-path>/<theme>/<viewport>/chromium/<scenario>-1.png` through native Vitest capture and comparison.
- Replace the ineffective Noto Sans Symbols 2 fallback with pinned Noto Sans Math containing U+2264, correcting the host-font-dependent MaximumOnly reference instability reproduced during matrix validation. Preserve the primary mono font and native comparison tolerances.
- Preserve the existing unit and standalone browser projects, their environments, browsers, behavior coverage, and reference paths. Their migration belongs to issue #280 and is outside this change.

## Capabilities

### New Capabilities

None in this continuation. The original contrast phase introduced `shell-forced-dark-contrast` and synchronized it into the uncommitted working tree before this change was reactivated.

### Modified Capabilities

- `browser-support-policy`: Keep one Browserslist policy while explicitly deriving LightningCSS targets for development and production CSS transformation instead of relying on the default inherited CSS target.
- `shell-forced-dark-contrast`: Retain the observed forced-dark correction and audit contract, and verify native themes through the generated six-project matrix.
- `storybook-visual-regression`: Generate visual coverage from the theme and viewport matrix, retain one scenario catalog, use theme-qualified native reference paths, and preserve existing non-visual coverage.

The existing `workspace-compact-theme-contrast` capability remains authoritative for Compact inversion; this change adds shell-wide forced-dark coverage without changing that contract.


## Impact

- Primary source boundaries: `assets/vite.config.mjs`, `assets/svelte.config.mjs`, `assets/package.json`, `assets/bun.lock`, `lib/d20_web/components/layouts/root.html.heex`, and `inertia_root.html.heex`. The remaining demonstrated failures require the lower-specificity anchor rule in `assets/css/app.css` and direct severity tokens in `assets/js/shared/components/inline_notification.svelte`. The equivalent transform reset in `assets/js/pages/home/ui/home.svelte` preserves existing carousel focus geometry under the compiler. Game panels, metadata, auth/provider components, account pages, and workspace controls retain their existing color declarations.
- Validation updates `assets/vite.config.mjs`, `assets/package.json`, theme-only exports under `assets/stories/`, and all reviewed references under `assets/__screenshots__/stories/`, using the existing frontend test and screenshot infrastructure. The shared screenshot hook and existing theme decorator remain the capture and theme boundaries; workflow documentation must show the matrix and its reference paths. References under `assets/__screenshots__/tests/` remain unchanged.
- Promote the already locked `lightningcss` 1.32.0 to a direct development dependency; no new runtime library or compiler swap is required. There are no persistence entities, migrations, Phoenix route/API changes, session behavior changes, public protocol changes, or embedded-game implementation changes. Rollback is a revert of the scoped CSS compilation, asset-loading, and associated verification changes.
- This is an independently reviewable contrast correction on the clean `caac3ad2` base in `worktree/forced-dark-contrast`. Favorites and API discovery have their own worktrees; the active footer and borderless-shell changes own content, layout, header geometry, and their outstanding delivery work. Existing scrollbar theming also remains outside this correction unless an actual readability failure is documented. Shared file overlap does not transfer those outcomes into issue #278.
