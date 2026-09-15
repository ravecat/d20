# Verification

Tracking issue: https://github.com/ravecat/d20/issues/286

## Baseline

- Isolated worktree: `.worktrees/fluid-workspace-controls`, branch `worktree/fluid-workspace-controls`, base `eec96d0ee3bd84c8482bd1df0b472ed6b78c7e76`.
- Installed locked frontend dependencies with `bun install --cwd assets --frozen-lockfile`; the worktree reuses the existing ignored dependency directory through a symlink.
- `bun run test:unit -- tests/widgets/workspace/ui/workspace.test.ts`: 8 passed.
- `bun run test:visual -- stories/widgets/workspace.stories.ts`: 24 passed across light/dark desktop, tablet, and mobile. Existing screenshots reviewed as full-page and control-detail contact sheets.
- `bun run typecheck`: no errors or warnings.
- The baseline visual runner exited with code 0 after reporting a shutdown timeout. This warning predates the CSS change.

## Changed presentation

- `bun x oxfmt --check js/widgets/workspace/ui/workspace.svelte stories/widgets/workspace.stories.ts`: passed.
- `bun x eslint js/widgets/workspace/ui/workspace.svelte stories/widgets/workspace.stories.ts`: passed.
- `bun run test:unit -- tests/widgets/workspace`: 16 passed in two files.
- `bun run typecheck`: no errors or warnings after implementation.
- First visual comparison produced exactly the expected 16 mobile/tablet reference differences and six new fullscreen references; all eight existing desktop comparisons passed unchanged.
- Reviewed all existing theme/viewport baselines and all changed actual/diff images. Controls shrink within their existing groups; icons remain legible, status badges and bar height stay unchanged, and narrow identifiers gain room. Updated only the 16 reviewed workspace references and added six reviewed fullscreen references. Updated references are pixel-identical to the reviewed actual images.
- Scoped visual reference update: 30 passed. Normal comparison rerun: 30 passed with exit code 0; the existing shutdown-timeout warning remains.
- Independent review found no implementation defect. Button contents fit across the full clamp range.
- `openspec validate --all --strict --no-interactive`: 89 passed, zero failures.
- Prepared-page browser verification subsequently passed as recorded below. The implementation remains local; this artifact update finalizes the specification lifecycle.

### Fullscreen capture limitation

The six fullscreen references all capture an effective 1280x900 viewport. Native fullscreen escapes the Storybook iframe's mobile/tablet dimensions. These references verify real fullscreen entry, Close/Exit appearance, and absent Compact at the maximum size in both themes; they do not verify native fullscreen sizing at narrow or intermediate widths. Prepared-page browser verification below supplies those narrow and intermediate native-fullscreen checks.

## Prepared-page browser verification

Chrome DevTools verification passed on the user-supplied D20 target `http://localhost:6007/?path=/story/widgets-workspace--auto-selection`, served from this worktree. This resolves the earlier target-access blocker.

With a 16px root, the browser reported the same square dimensions for Compact and Theater controls:

| CSS viewport width | Button | Icon | Button padding |
| --- | --- | --- | --- |
| 320px and 400px | 20px | 12px | 2px |
| 800px | 25px | 13.5px | 3px |
| 1200px and 1600px | 30px | 15px | 4px |

- Compact chrome remained 46px high and its status badge 30px high throughout these viewport checks.
- At a 20px root and 400px viewport, button/icon/padding were 25px/15px/2.5px; status/chrome heights were 37.5px/57.5px. The reviewed screenshot showed both Compact bars with fitting icons/status and the existing identifier overflow lane.
- Real native fullscreen was checked at actual CSS viewport widths of 400px, 800px, 1200px, and 1280px. Button sizes were 20px, 25px, 30px, and 30px; icons were 12px, 13.5px, 15px, and 15px. Reviewed screenshots showed Close and Exit fullscreen, with no Compact action. Exiting restored Compact.
- Reviewed visible native keyboard focus at 400px. Replaying AutoSelection verified keyboard-driven layout transitions and actual fullscreen entry/exit.
- Close was clicked in Storybook, whose mocked call intentionally performs no session removal. Existing workspace tests verify close dispatch (`assets/tests/widgets/workspace/ui/workspace.test.ts:191` and `assets/tests/widgets/workspace/model/workspace.test.ts:159`); this CSS-only change does not claim live server removal verification or change server behavior.
- The console retained existing `about:blank` sandbox script-blocking and null-origin `postMessage` warnings; no new sizing error was observed.
- Temporary browser instrumentation and styles were removed. The supplied route and theme were retained, with session B expanded and session A compact restored.

## Lifecycle finalization

- Synchronized the complete affected requirements into `workspace-window-controls` and `workspace-session-status-bars`, preserving all existing scenarios and adding the four sizing scenarios.
- Archived as `openspec/changes/archive/2026-09-15-fluid-workspace-controls/` with the repository CLI; all tasks are complete.
- `openspec validate --all --strict --no-interactive`: 88 passed, zero failures after archival.
- `openspec list --json`: the change is absent. Both archived deltas match the authoritative requirements.
- `git diff --check`: passed. These finalization records accompany local implementation commit `d8f20d52`; this step changes no product code or stories.
