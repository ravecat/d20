## ADDED Requirements

### Requirement: Every discovered story has responsive image references

The frontend package SHALL transform every story discovered by Storybook into a Chromium Vitest Browser Mode test and SHALL compare its complete rendered document against committed desktop, tablet, and mobile image references.

#### Scenario: Visual coverage follows Storybook discovery

- **WHEN** a contributor adds a deterministic story matched by `assets/.storybook/main.ts`
- **THEN** the Storybook Vitest integration generates a browser test for that story without adding a second file-name, story-name, identifier, or tag manifest
- **AND** the generated story test runs once in each visual viewport project
- **AND** no visual test reconstructs the story fixture

#### Scenario: Each responsive state is compared

- **WHEN** a generated story test runs in the desktop, tablet, or mobile visual project
- **THEN** Storybook establishes the project's named `1280x720`, `1024x640`, or `320x900` viewport before decorators, render, and optional `play` execution
- **AND** the screenshot hook does not resize the story after `play`
- **AND** the complete test document is compared through Vitest's native `toMatchScreenshot()` assertion
- **AND** production and Storybook render ordinary text and mathematical symbols with the same lockfile-pinned self-hosted Fontsource assets without a runtime Google Fonts request or host font lookup
- **AND** the screenshot hook explicitly loads every declared document font after the Storybook lifecycle and before visual capture
- **AND** production and Storybook use the same global declarations that disable font synthesis and request legibility and grayscale smoothing
- **AND** no screenshot-only wrapper, test-only CSS override, arbitrary delay, custom image comparator, custom Fontconfig file, or Chromium font, color-profile, or text-rendering launch override changes the captured state

#### Scenario: An interaction story is captured after play

- **WHEN** a story defines a `play` function
- **THEN** its interaction and semantic assertions complete before visual comparison
- **AND** the screenshot hook does not repeat the interaction or inspect the generated task identity
- **AND** a failed `play` assertion prevents that story's visual comparison from being accepted as successful

### Requirement: Visual references and failure evidence are reviewable

The frontend package SHALL keep reviewed screenshot references under version control and SHALL keep generated actual, diff, trace, and HTML report evidence outside tracked source and runtime artifacts.

#### Scenario: Visual artifacts use stable package-local paths

- **WHEN** Vitest creates or reads screenshot artifacts
- **THEN** committed references reside under `assets/__screenshots__/` in a tree that mirrors the owning story path
- **AND** each reference uses a `<story-path>/<viewport>/<browser>/<story>.png` hierarchy with `<viewport>` one of `desktop`, `tablet`, or `mobile` and `<browser>` currently `chromium`
- **AND** the filename does not repeat the browser or include a redundant platform suffix because Linux Chromium is the single supported reference environment
- **AND** generated actual and diff images reside under `assets/.vitest-attachments/`
- **AND** generated HTML reports and retained failure traces reside under `assets/.vitest/`
- **AND** only the reviewed references are tracked by Git
- **AND** references and generated test evidence are excluded from the production Docker build context

#### Scenario: A normal comparison detects rendered drift

- **WHEN** rendered pixels differ from a committed reference during a normal test run
- **THEN** the generated story test fails
- **AND** Vitest provides reference, actual, and diff evidence when available
- **AND** the committed reference is not replaced automatically
- **AND** a Playwright-provider trace is retained for the failed Storybook viewport test

#### Scenario: A new story has no accepted reference

- **WHEN** a discovered story is compared before a matching reference exists
- **THEN** Vitest creates the candidate reference and fails the comparison
- **AND** a contributor must review the candidate and run a normal comparison before the reference is accepted as passing

### Requirement: Reference updates require explicit acceptance

The visual workflow SHALL separate ordinary comparison from intentional reference updates and SHALL require no external visual-testing service.

#### Scenario: Accept an intentional visual change

- **WHEN** a contributor confirms that a rendered change is intentional
- **THEN** the contributor regenerates affected references through Vitest's explicit `--update` mode
- **AND** reviews added, changed, and removed images in Git
- **AND** removes stale references left by renamed or deleted stories
- **AND** reruns normal comparison successfully against the reviewed references

#### Scenario: Use visual regression without a cloud account

- **WHEN** a contributor runs, reviews, reports, or updates visual comparisons
- **THEN** no external account, project token, hosted snapshot service, or remote baseline store is required
- **AND** references remain repository files

### Requirement: One Vitest command surface preserves existing coverage

The frontend test command SHALL run existing unit and cross-browser behavior tests together with Storybook visual projects without replacing their established environments, browsers, or responsibilities.

#### Scenario: Run the complete frontend test workflow

- **WHEN** a contributor runs the frontend `test` script without project filters
- **THEN** Vitest runs the existing jsdom unit project
- **AND** Vitest runs the existing browser project in Chromium and Firefox at its established viewport
- **AND** Vitest runs the desktop, tablet, and mobile Storybook projects in Chromium
- **AND** each generated Storybook test performs one visual comparison in each viewport project
- **AND** no Storybook development server or second test runner is required

#### Scenario: Run focused visual workflows

- **WHEN** a contributor supplies optional Vitest project, reporter, UI, or update flags through the frontend command boundary
- **THEN** the contributor can run one viewport project or the complete viewport matrix
- **AND** can produce a static HTML report or inspect failures in Vitest UI
- **AND** can update references only when `--update` is explicitly present
- **AND** optional Vitest arguments are forwarded without a custom parser

#### Scenario: Existing non-visual coverage remains authoritative

- **WHEN** Storybook visual comparisons pass
- **THEN** existing semantic, accessibility, focus, interaction, responsive-state, transport, and cross-browser assertions still run independently
- **AND** screenshot success is not treated as proof of those behaviors
- **AND** existing unit and browser test project filters remain available

### Requirement: Repository validation and documentation include visual regression

The repository SHALL include Storybook visual comparison in its established frontend test validation and SHALL document the essential reference lifecycle without duplicating upstream tool documentation.

#### Scenario: Run aggregate repository checks

- **WHEN** a contributor runs `just check`
- **THEN** the existing `mix assets.test` boundary runs the Storybook viewport projects and their screenshot comparisons in addition to existing frontend tests
- **AND** missing or changed visual references cause aggregate validation to fail
- **AND** the static Storybook build remains a separate required check

#### Scenario: Discover the visual workflow

- **WHEN** a contributor reads the repository Storybook and story-convention documentation
- **THEN** they can identify the pinned Chromium setup, normal comparison, and explicit update commands
- **AND** the tracked reference location and three named viewport dimensions
- **AND** the requirement that stories remain deterministic and isolated from live application boundaries
