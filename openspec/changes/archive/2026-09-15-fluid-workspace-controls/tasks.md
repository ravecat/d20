## 1. Implement fluid controls

- [x] 1.1 Apply the three clamp formulas to button dimensions, icon dimensions, and button padding in `assets/js/widgets/workspace/ui/workspace.svelte`, preserving status/bar geometry and action semantics.
- [x] 1.2 Add a deterministic fullscreen-ending workspace story using existing fixtures and semantic interaction assertions so the shared screenshot hook covers fullscreen alongside Theater and Compact.

## 2. Verify the changed presentation

- [x] 2.1 Run scoped formatting and lint checks for touched frontend files, `bun run typecheck`, and `bun run test:unit -- tests/widgets/workspace` from `assets/`.
- [x] 2.2 Run `bun run test:visual -- stories/widgets/workspace.stories.ts`; inspect baseline, actual, and available diff images for affected Compact, Theater, and fullscreen states across both themes and all three existing viewport projects. Update only reviewed workspace references with scoped `--update`, then rerun normal comparisons. All 30 pass; native fullscreen captures the same 1280px width in every project, as recorded in `verification.md`; narrower fullscreen verification passed in 2.3.
- [x] 2.3 Use `devtools-validations` on the correct D20 target to verify clamp minima, interpolation, and maxima at 400px, 800px, and 1200px with a 16px root, plus bounding widths, larger root text, visible focus, unchanged bar height, and Close/Compact/fullscreen actions. Record actual evidence and any target-access blocker.

## 3. Reconcile delivery

- [x] 3.1 Record verified results and limitations in the owning artifacts, synchronize both deltas, archive only after required validation passes, run `openspec validate --all --strict --no-interactive`, and confirm the change is absent from `openspec list --json` before the semantic completion commit.
