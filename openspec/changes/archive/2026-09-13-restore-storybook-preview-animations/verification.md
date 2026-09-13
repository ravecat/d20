# Verification

Tracking: [#284](https://github.com/ravecat/d20/issues/284).

## Workspace and scope

- Isolated worktree: `/home/max/apps/d20/.worktrees/storybook-preview-animations`, branch `worktree/storybook-preview-animations`, base `63d8c6af`.
- Installed locked frontend dependencies with `bun install --frozen-lockfile --cwd assets`; local Mix dependencies resolve through a symlink to the primary checkout's existing dependency directory.
- Preserved the primary checkout's unrelated untracked `assets/home/` and the independent account-deletion worktree.
- Removed the shared preview reset/import and the four Workspace cancellation loops, and updated story guidance. Both public and authenticated Home metadata defaults now use the existing `homeBrowseGames` fixture: 32 browse entries produce eight hero cards and 24 compact cards. Explicit empty, singleton, favorites, and small widget scenarios are unchanged.
- Production CSS, story state assertions, screenshot setup/defaults, and dependencies are unchanged. Baseline changes are limited to stories inheriting the expanded Home defaults.

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

## Expanded Home fixture validation

- The initial comparison of both Home files ran 84 tests: 36 explicit override cases passed and 48 cases inheriting the expanded default differed across eight stories and six instances. The same run also reported two public Index test timeouts and one dark-tablet Index stable-capture timeout; successful subsequent capture and comparison are required before acceptance.
- Independent review inspected representative reference/actual/diff images across both themes and all three viewports, and checked pixel bounds for all 47 available actual images. Dimensions and layout were preserved; changed pixels were confined to card content and the visible catalog background behind dialogs. Compact cards now begin with Shifting Stones, Sky Team, and Trailblazers; the first hero remains Voyages.
- Scoped `oxfmt --check` and ESLint passed for the preview and all touched story files; `git diff --check` passed. `bun run typecheck` reported zero errors and warnings, and `bun run storybook:build` completed with the existing large-chunk advisory.
- A parallel baseline-update attempt was interrupted with exit 130 after host memory became constrained (approximately 1.5 GB available and all 32 GB of swap used). It is not counted as successful validation. The same matrix was rerun one project at a time through the existing package script; repository configuration and test assertions remain unchanged.
- `bun run vitest run --project visual-<theme>-<viewport> stories/pages/public/home.stories.ts stories/pages/authenticated/home.stories.ts --update --maxWorkers=1` passed 14 tests for each of light/dark desktop/tablet/mobile, totaling 84 tests. All six processes exited zero. The earlier test and stable-capture timeouts did not recur.
- Exactly 48 Home references changed: public Index, No Playable Games, Sign In, Sign In Sent Magic Link, Sign Up, Sign Up With Email, and authenticated Index and Confirmation With Magic Link, each across six instances. No override-scenario or Workspace reference changed.
- Final independent baseline review confirmed dimensions match HEAD, 47 updated references match the previously reviewed actual images pixel-for-pixel, and the newly captured public dark-tablet Index differs only in expected compact-card content. No code or baseline defects were found.
- `bun run vitest run --project visual-<theme>-<viewport> --maxWorkers=1`, without `--update`, passed all 63 tests in 15 files for each of the six configured instances: 378 tests across 90 files in total. All processes exited zero. The pre-existing shutdown-timeout notice remains; no test or screenshot-stability timeout recurred.

## Interactive browser verification

The user opened the task's D20 Storybook at `http://localhost:6010`; its existing Chrome DevTools page 9 was reused. Other browser surfaces were left unchanged, and the D20 page was restored to its previous Unavailable Game story after inspection.

- Before the data correction, the public Index had one canonical hero card and no hero animation, confirming the production singleton guard was responsible.
- After the correction, public and authenticated Index each rendered eight canonical hero cards. With reduced motion disabled and neither hover nor focus in the carousel, both hero animation clocks advanced naturally and card positions changed across a full slide interval. Public sampling observed the track wrap back to Voyages; authenticated sampling observed a 653-pixel advance. Screenshots visually confirmed the running catalog and a transition to Death Valley.
- Workspace Connection Statuses retained running status-pulse and session-pan animations after its interactions. Sampling observed opacity change from 0.990306 to 0.25 and the long-label translation progress from 0.006233 to 0.864788 of its overflow distance.
- Theme toolbar changes applied dark and light themes while motion continued. Scrolling authenticated Home removed the header's at-top guard and compacted the header. A dark-to-light change at scroll position 24 applied `data-theme="light"` after approximately 201 ms. Header scroll animations were already finished in this inspected state, so the five-second fallback was not reproduced in that switch.
- The user's browser has Dark Reader injected. Manual checks establish motion, structure, scrolling, and theme attribute changes; the isolated automated browser matrix establishes theme screenshot appearance.

Installed Storybook 10.5.7 source confirms test environments use `pauseAnimations()` while interactive completion uses `waitForAnimations()` with a five-second fallback. This change intentionally retains those standard mechanisms. The existing application header's at-top guard can suppress its scroll animations itself; the historical delay should not be assumed to occur for every story or scroll position.

Stable screenshot comparisons do not establish animation progression or smoothness. The existing below-viewport screenshot limitation remains tracked separately by #281.

## Delivery reconciliation

- `openspec archive restore-storybook-preview-animations --yes` synchronized the catalog requirement and archived the change as `2026-09-13-restore-storybook-preview-animations`.
- `openspec validate --all --strict --no-interactive`: all 88 items passed. `openspec list --json` no longer includes this change.
- The completed local delivery remains on `worktree/storybook-preview-animations` for review. The task's Storybook server remains available at port 6010. No target-branch integration, remote publication, or deployment is required or claimed.
