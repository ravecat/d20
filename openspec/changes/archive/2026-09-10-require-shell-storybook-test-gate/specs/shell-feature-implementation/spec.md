## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Contract verification and delivery completion
The shell skill SHALL require updates to affected public contracts and nearby behavior tests, relevant native formatting and validation commands, and browser validation through `devtools-validations` for changed UI behavior. Shell screens and visual changes SHALL also pass the Storybook UI testing and reviewed screenshot comparison gates before completion. It SHALL require reconciliation of the owning tasks and specifications, archive through the native OpenSpec lifecycle after recorded delivery work passes, strict validation, and a report of verified behavior and remaining risks. Validation SHALL scale to the changed behavior; documentation-only delivery SHALL use documentation checks without requiring runtime tests.

#### Scenario: Complete an implemented shell feature
- **WHEN** the feature's required behavior and delivery work have been verified
- **THEN** the workflow reconciles affected contracts and task statuses, archives the completed change, runs `openspec validate --all --strict --no-interactive`, and checks that the change is absent from `openspec list --json`
- **AND** reports the checks performed, required story and screenshot review evidence, and any remaining risks before claiming completion
