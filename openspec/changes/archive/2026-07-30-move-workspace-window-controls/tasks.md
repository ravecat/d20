## 1. Workspace Derivation

- [x] 1.1 Replace per-session `isExpanded` evaluation with one reactive optional `expandedId` while preserving Auto, Focused, Compact, and fallback behavior.

## 2. Unified Control Composition

- [x] 2.1 Type the required `Dialog` children snippet with fullscreen state and the fullscreen toggle action, then remove dialog-owned control markup and styles without moving Fullscreen API mechanics.
- [x] 2.2 Render Close, the applicable Compact or Expand action, and fullscreen in one workspace-owned named block with preserved semantics, accessible naming, icon hiding, geometry, focus, visibility, and behavior.

## 3. Verification

- [x] 3.1 Run Svelte autofix for both changed components and resolve every reported issue.
- [x] 3.2 Update and run focused workspace component and browser tests covering unified control order, layout fallback, close forwarding, fullscreen behavior, control reachability, and iframe continuity.
- [x] 3.3 Run formatting, linting, type checking, and strict `move-workspace-window-controls` OpenSpec validation.
