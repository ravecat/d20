---
name: implement-shell-feature
description: Implement or extend D20 shell features for accounts, actors, catalog and discovery, generic sessions, permissions, and Phoenix/Inertia/Svelte integration. Use for shell functionality, including new persisted entities; route game-specific rules and playable engines to implement-playable-game.
---

# Implement Shell Feature

Deliver shell functionality through its owning domain, server boundary, persistence, and supported client workflow. Repository paths below are relative to the repository root.

## 1. Gate: tracked, implementation-ready scope

- Read `AGENTS.md` and follow its workspace policy, including explicit user overrides. Identify the owning work before writing.
- Verify an owning issue in the D20 Project with `$github-management`. Find its active OpenSpec change; use `$openspec-propose` if absent, or extend the owning artifacts when the request is part of the same outcome.
- Read the proposal, design, delta specifications, and tasks. Record observable acceptance criteria, affected boundaries, and relevant failure states. Resolve blocking questions before implementation, then use `$openspec-apply-change`.
- Route game-specific rules or engine implementation to `$implement-playable-game`. A shell feature alone does not authorize changes in a separate iframe repository.

## 2. Gate: ownership and authorization

- Trace the existing domain API, persistence or runtime state, web entry points, caller-facing data, and nearby tests using the routing map in `AGENTS.md`. Consult `justfile`, `mix.exs`, and `assets/package.json` for native commands.
- Keep domain invariants in the owning context and caller authorization on the server. Derive the caller from authenticated or trusted session context; a client-supplied identity or hidden control is not authorization.
- Use `D20.Sessions` for public game-session runtime operations. Keep generic lifecycle in the shell and game-specific legality in the game namespace.
- Define permitted inputs, outputs, and denied behavior for each affected caller role. Preserve existing error and public contracts unless the authorized change modifies them. Expose only caller-permitted data, not raw internal state.

## 3. Gate: new persisted entity identity and creation

Apply this gate to every new persisted shell entity. If none is introduced, record why it is not applicable; do not invent persistence or retrofit existing identifiers. Runtime `D20.Sessions.Session` UUIDs remain a separate contract. Changes to existing persistence still require verification of their affected invariants.

Read `lib/d20/games/game.ex` for the schema and separate creation/update policies, and `priv/repo/migrations/20260824000000_create_games.exs` for storage. Use their identity pattern with the new entity's stable prefix:

```elixir
@primary_key {:id, TypeID, autogenerate: true, prefix: "entity"}

@type id :: TypeID.t()
@type t :: %__MODULE__{id: id()}
```

Include the entity's other fields in `t()`. Replace `"entity"` with its domain-specific prefix and keep that prefix stable across schema, constraints, fixtures, and contracts.

- Create the table with `primary_key: false` and `add :id, :string, primary_key: true, null: false`. Match association types and database foreign-key columns to the referenced identifier representation; for TypeID targets, use compatible TypeID schema fields and string references.
- Ecto performs TypeID autogeneration on schema insertion. Do not assume a SQL default generates it; explicit migration/backfill inserts must supply valid IDs and enforce the same invariants.
- Provide an explicit schema `create_changeset` that casts an allowlist of creation attributes and validates required fields and domain constraints. Obtain trusted ownership or caller identity separately from request attributes, then assign it through the authorized creation path. Keep generated IDs out of the client attribute allowlist.
- Trace each application creation entry point through `create_changeset` to insertion, including administrative paths. A changeset that exists but is bypassed does not pass this gate.
- Separate creation and update policies when creation-only fields are immutable afterward. Exclude those fields from ordinary update casting and verify their preservation.
- Back persisted invariants with applicable database null, unique, foreign-key, or check constraints and map expected failures to changeset errors. For multi-record creation or concurrent/retried requests, define the required transaction boundary and duplicate/idempotency behavior; application prechecks alone cannot guarantee uniqueness.

Pass this gate only after verifying valid creation and its generated prefix, invalid attributes, trusted identity handling, relevant database constraint failures, and immutable-field behavior. Add concurrency or retry checks when those semantics affect acceptance. Validate the migration and its rollback assumptions for the actual deployment path.

## 4. Implement the supported workflow

- Use the relevant Elixir and Phoenix skills for backend/web changes and Svelte/TypeScript skills for frontend changes. Follow nearby patterns while keeping authorization and authoritative calculations on the server.
- Update affected public payloads, projections, permissions, errors, and the matching `priv/specs/` contract together with their boundary tests. Keep supported client workflows complete without leaking private data.
- For shell UI changes, account for the relevant loading, empty, error, success, disabled, and pending states. Preserve accessibility and use `$devtools-validations` to verify changed behavior in the browser.

## 5. Gate: Storybook scenarios and reviewed screenshots

Apply this gate to new or changed shell screens and visual states. Use `$storybook` and `$web-testing`, and read `assets/stories/README.md` before authoring coverage.

- Prepare deterministic stories using production components and existing shell decorators/styles. Cover the relevant states from the acceptance criteria with isolated dependencies and stable fixtures.
- Put interaction scenarios and semantic assertions in `play` using `storybook/test` and accessible queries. Keep complex UI sequences in `play`, organized into steps. Complexity alone is not a reason to move UI coverage into a separate test file.
- Center UI tests on stories, which already run through `@storybook/addon-vitest`. Do not duplicate their scenarios in standalone Vitest UI tests. Add separate Vitest tests only for complex logic or boundaries that stories cannot adequately exercise; record the reason and distinct verification signal in the owning change. Preserve required backend and distinct lower-layer or cross-process tests.
- Run affected stories from `assets/` with `bun run test:visual -- <story-path>`, using the existing desktop, tablet, and mobile projects in `assets/vite.config.mjs`. The shared `assets/.storybook/vitest.setup.ts` hook supplies full-document screenshot comparisons after render and `play`; `play` assertions alone do not compare pixels. Reuse this infrastructure.
- Give each required before, intermediate, and after visual state screenshot coverage. If `play` leaves a required state before the shared hook runs, add a deterministic story that finishes in that state so it receives its own comparison.
- Open baseline, actual, and available diff images with image or browser tools for every affected state and viewport. Inspect the rendered result and resolve unintended differences. A passing build or `play`, screenshot file existence, or diff statistics cannot replace image inspection.
- For new UI without a baseline, inspect the candidate against the intended design before accepting its reference, then rerun normal comparison. For intentional visual changes, update only reviewed affected references with a narrowly scoped `--update`, inspect the resulting images, and rerun without update mode. Never use blanket baseline updates to clear failures.

Pass this gate only when the required stories and screenshot comparisons pass and their images have been reviewed. Use `$devtools-validations` for browser investigation and the supported integrated workflow as needed.

## 6. Verify and reconcile delivery

- Run focused tests at changed domain and persistence, authorization, and controller/channel/projection boundaries. Include rejection paths and observable acceptance criteria. Allocate frontend coverage through the Storybook gate above, retaining tests for distinct behavior it cannot verify.
- Format touched files and run applicable native checks from the manifests: targeted `mix test`, the affected story and justified separate test suites, `mix assets.lint`, `mix typecheck`, or build checks. Broaden to `just check` for cross-stack or release-relevant changes. Documentation-only work needs documentation validation rather than runtime tests or screenshots.
- Reconcile every affected task, specification, contract, and durable artifact with verified behavior. Once all recorded delivery work passes, use `$openspec-archive-change`, run `openspec validate --all --strict --no-interactive`, and verify the change is absent from `openspec list --json`.
- Follow the repository completion and commit policy. Report delivered behavior, applicable persistence evidence, changed contracts, checks run, and remaining risks. For UI work, include story coverage, reviewed screenshot states/viewports, and intentional baseline changes. Required stale or uncommitted delivery artifacts prevent a completion claim.
