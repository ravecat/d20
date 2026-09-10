# shell-feature-implementation Specification

## Purpose

Guide shell feature delivery through repository ownership, typed persistence identity, validated creation paths, public contracts, and verified completion.
## Requirements
### Requirement: Discoverable shell implementation guidance
The repository SHALL provide a concise, manually owned `.agents/skills/implement-shell-feature/SKILL.md`, discoverable from root `AGENTS.md`, for accounts, actors, catalog and discovery, generic sessions, permissions, and Phoenix/Inertia/Svelte shell integration. The guidance SHALL route game-specific rules and playable engine implementation to `implement-playable-game`.

#### Scenario: Select the workflow for a shell feature
- **WHEN** a task adds or extends shell functionality
- **THEN** the repository entry point identifies the shell skill and its scope
- **AND** gameplay work is directed to the existing playable-game skill

### Requirement: Tracking and boundary gates
The shell skill SHALL require an owning D20 Project issue and ready OpenSpec artifacts before implementation, follow repository workspace policy including explicit user overrides, and identify the domain owner, public entry points, caller authorization, and relevant failure states. It SHALL preserve `D20.Sessions` as the public game-session runtime boundary and retain existing contracts unless the authorized change modifies them.

#### Scenario: Prepare a cross-boundary shell feature
- **WHEN** a feature spans domain logic, a web entry point, and shell UI
- **THEN** the workflow checks its tracking and specification readiness before implementation
- **AND** assigns domain invariants and caller authorization to server boundaries while identifying required public contract changes

### Requirement: Typed identity gate for new persisted entities
The shell skill SHALL require every new persisted shell entity to use an entity-specific stable TypeID primary key with `autogenerate: true`, declare `@type id :: TypeID.t()`, and include `id: id()` in its schema `t()` type. It SHALL require matching string primary-key migrations and compatible foreign keys, identify Ecto as the TypeID generator, and avoid assuming a database default. This gate SHALL preserve existing runtime identifier contracts and SHALL NOT require an entity or retrospective identifier migration when the requested change introduces no persisted entity.

#### Scenario: Add a persisted shell entity
- **WHEN** a feature introduces a new persisted shell entity
- **THEN** the workflow verifies its stable prefix, `@primary_key {:id, TypeID, autogenerate: true, prefix: "entity"}` pattern with the chosen prefix, named identity type, migration storage, and foreign-key compatibility
- **AND** insertion verification checks the Ecto-generated identifier

#### Scenario: Change only shell presentation
- **WHEN** a feature introduces no persisted entity
- **THEN** the workflow records the persistence gate as inapplicable without adding an entity or changing established runtime IDs

### Requirement: Creation changesets on insertion paths
The shell skill SHALL require an explicit schema `create_changeset` for each new persisted shell entity and verify that actual insertion paths invoke it. Creation changesets SHALL validate permitted attributes, keep trusted identity and ownership separate from untrusted request attributes, and map applicable database constraints to errors. The guidance SHALL require separate creation/update policies when immutable fields differ and address atomicity, concurrent creation, and retry semantics where relevant.

#### Scenario: Review entity creation
- **WHEN** a new persisted entity is inserted through a context or other creation entry point
- **THEN** the workflow traces that path through `create_changeset` and verifies valid creation, invalid attributes, trusted identity handling, and applicable database constraint failures
- **AND** review rejects a creation changeset that exists but is bypassed by an insertion path

#### Scenario: Protect creation-only attributes
- **WHEN** an attribute may be assigned at creation but is immutable afterward
- **THEN** the workflow verifies distinct creation and update policies and tests the immutable-field behavior

### Requirement: Contract verification and delivery completion
The shell skill SHALL require updates to affected public contracts and nearby behavior tests, relevant native formatting and validation commands, and browser validation through `devtools-validations` for changed UI behavior. Shell screens and visual changes SHALL also pass the Storybook UI testing and reviewed screenshot comparison gates before completion. It SHALL require reconciliation of the owning tasks and specifications, archive through the native OpenSpec lifecycle after recorded delivery work passes, strict validation, and a report of verified behavior and remaining risks. Validation SHALL scale to the changed behavior; documentation-only delivery SHALL use documentation checks without requiring runtime tests.

#### Scenario: Complete an implemented shell feature
- **WHEN** the feature's required behavior and delivery work have been verified
- **THEN** the workflow reconciles affected contracts and task statuses, archives the completed change, runs `openspec validate --all --strict --no-interactive`, and checks that the change is absent from `openspec list --json`
- **AND** reports the checks performed, required story and screenshot review evidence, and any remaining risks before claiming completion

### Requirement: Storybook UI testing gate
The shell skill SHALL require deterministic production-component Storybook stories for new or changed shell screens and visual states, following `assets/stories/README.md`. Interaction scenarios and semantic assertions SHALL live in `play`, including complex UI sequences expressed as steps. The skill SHALL center UI coverage on stories and prohibit duplicate standalone Vitest UI tests. Separate Vitest tests SHALL be limited to complex logic or boundaries that stories cannot adequately cover, with their reason and unique signal recorded in the owning change. This allocation SHALL preserve backend tests and distinct lower-layer or cross-process coverage, and SHALL acknowledge that Storybook itself runs through the existing Vitest addon.

#### Scenario: Add or change a shell screen
- **WHEN** shell work introduces or changes a screen or visual state
- **THEN** the workflow requires deterministic stories for its relevant states and `play` scenarios with semantic assertions for its interactions
- **AND** keeps that UI coverage in stories without duplicating it in standalone Vitest files

#### Scenario: Select a separate test for distinct coverage
- **WHEN** complex logic or a boundary cannot be adequately verified through stories
- **THEN** a separate Vitest test requires a recorded reason and distinct verification signal
- **AND** UI interaction complexity alone does not require moving scenarios out of `play`

### Requirement: Reviewed screenshot comparison gate
The shell skill SHALL require actual screenshot comparison for affected stories through the existing desktop, tablet, and mobile visual projects, plus image-tool inspection of baseline, actual, and available diff images. It SHALL require explicit visual coverage of relevant before, intermediate, and after states; states absent from the shared end-of-play capture SHALL be represented by dedicated deterministic stories. New UI without a reference SHALL have its candidate inspected against the intended design before accepting a baseline and rerunning normal comparison. Intentional baseline updates SHALL be narrowly scoped and followed by a comparison run without update mode. Passing `play` assertions, a successful build, screenshot file existence, or blanket baseline updates SHALL NOT alone satisfy the gate.

#### Scenario: Verify a changed existing visual state
- **WHEN** an existing story's rendered result changes
- **THEN** the workflow runs affected visual comparisons, inspects baseline and actual images plus any generated diff, and resolves unintended differences
- **AND** intentional reference updates are limited to reviewed changes and followed by a passing normal comparison

#### Scenario: Verify new UI without a baseline
- **WHEN** a required visual state has no existing screenshot reference
- **THEN** the workflow inspects the candidate against the intended design, accepts only the reviewed baseline, and reruns normal comparison

#### Scenario: Preserve intermediate visual coverage
- **WHEN** `play` leaves a required initial or intermediate state before the shared screenshot hook runs
- **THEN** the workflow requires a dedicated deterministic story that finishes in that state so it receives comparison and image inspection
