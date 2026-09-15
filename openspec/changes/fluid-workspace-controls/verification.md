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
- Implementation is retained locally for review; browser verification and lifecycle finalization remain incomplete. The active deltas are intentionally not synchronized or archived before that gate passes.

### Fullscreen capture limitation

The six fullscreen references all capture an effective 1280x900 viewport. Native fullscreen escapes the Storybook iframe's mobile/tablet dimensions. These references verify real fullscreen entry, Close/Exit appearance, and absent Compact at the maximum size in both themes; they do not verify native fullscreen sizing at narrow or intermediate widths. Those checks remain part of the prepared-page browser verification below.

## Prepared-page browser verification

Pending access to a D20 development page with the changed workspace. Chrome DevTools listed `http://localhost:6006/?path=/story/game--finished-solo&globals=theme:dark`, but its snapshot identifies the separate Next Station London game catalog rather than D20 shell stories. No navigation or state changes were made. The user was asked to provide an appropriate target under the devtools-validations page-preservation rule.
