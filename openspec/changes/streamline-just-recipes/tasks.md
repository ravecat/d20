## 1. Command Interface

- [x] 1.1 Add positional `mix` and `assets` dispatchers to `justfile`, with root and `assets/` working directories respectively, required trailing arguments, native exit statuses, and no redundant failure footer.
- [x] 1.2 Refactor `serve` and `check` to invoke their required native commands directly while preserving existing options, defaults, action order, and failure behavior.
- [x] 1.3 Remove `setup`, `start`, `down`, `test`, `build`, `typecheck`, `agent-skills-sync`, `agent-skills-check`, `db-create`, `db-migrate`, and `db-reset`, leaving only discovery infrastructure, dispatchers, and composite workflows.

## 2. Developer Documentation

- [x] 2.1 Update `README.md` command and validation examples to separate composite `just` workflows from direct Mix, Bun, and Docker commands and to document replacements for removed recipes.
- [x] 2.2 Update root `AGENTS.md` command guidance so repository automation uses retained workflows or native commands and states the composition rule for future recipes.

## 3. Validation

- [x] 3.1 Run `just --fmt --check`, inspect `just --summary`, and confirm every removed single-action recipe is unavailable while `default`, `mix`, `assets`, `serve`, `up`, `format`, and `check` remain available.
- [x] 3.2 Exercise `just mix help typecheck` and `just assets browsers`, and verify representative failing native commands preserve failure without a redundant `just` footer.
- [x] 3.3 Dry-run `serve` and `up` to verify composition and argument defaults, then run `just check` to validate the retained cross-stack workflow.
