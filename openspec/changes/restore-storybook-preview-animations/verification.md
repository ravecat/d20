# Verification

Tracking: [#284](https://github.com/ravecat/d20/issues/284).

## Workspace and scope

- Isolated worktree: `/home/max/apps/d20/.worktrees/storybook-preview-animations`, branch `worktree/storybook-preview-animations`, base `63d8c6af`.
- Installed locked frontend dependencies with `bun install --frozen-lockfile --cwd assets`; local Mix dependencies resolve through a symlink to the primary checkout's existing dependency directory.
- Preserved the primary checkout's unrelated untracked `assets/home/` and the independent account-deletion worktree.
- Removed only the shared preview reset/import and the four Workspace cancellation loops, and updated story guidance. Production CSS, story state assertions, screenshot setup/defaults, dependencies, and existing references are unchanged.

## Automated checks

Commands run from `assets/` unless noted:

- Before implementation, `bun run test:visual -- stories/widgets/workspace.stories.ts --project visual-light-desktop`: 24 tests passed across the six configured visual instances (the script's existing project filter remained active). Vitest printed a shutdown-timeout notice after successful tests and exited zero; this predates the edit.
- Before implementation, `bun run typecheck`: zero errors and warnings.
- After implementation, `bun run test:visual -- stories/widgets/workspace.stories.ts stories/pages/public/home.stories.ts stories/pages/authenticated/home.stories.ts`: all 108 tests passed across 18 files, without updating references.
- `bun run oxfmt --check .storybook/preview.ts stories/widgets/workspace.stories.ts stories/README.md`: passed.
- `bun run eslint .storybook/preview.ts stories/widgets/workspace.stories.ts`: passed.
- After implementation, `bun run typecheck`: zero errors and warnings.
- `bun run storybook:build`: passed with the existing large-chunk advisory. Output remains ignored under `priv/static/storybook`.
- Repository root: `git diff --check` and `openspec validate restore-storybook-preview-animations --strict --no-interactive`: passed.
- `openspec validate --all --strict --no-interactive`: all 89 items passed.
- Independent scoped diff review found no defects.

`bun run test:visual`: all 378 tests passed across 90 files and six configured instances, with no baseline updates. The command exited zero after the same shutdown-timeout notice observed before implementation. No visual reference changed.

## Interactive browser verification - pending

The task's Storybook server runs at `http://localhost:6010`. The connected Chrome instance initially exposed no page at that origin. Its Storybook tab at port 6008 belongs to the separate Next Station London game and was left unchanged. The user has been asked to open the task's Storybook page under the required DevTools workflow. Live motion and theme-switch timing remain unverified until that surface is available.

Installed Storybook 10.5.7 source confirms test environments use `pauseAnimations()` while interactive completion uses `waitForAnimations()` with a five-second fallback. This change intentionally retains those standard mechanisms. The existing application header's at-top guard can suppress its scroll animations itself; the historical delay should not be assumed to occur for every story or scroll position.

Stable screenshot comparisons do not establish animation progression or smoothness. The existing below-viewport screenshot limitation remains tracked separately by #281.
