# storybook-visual-regression Specification

## Purpose

Define deterministic light/dark by desktop/tablet/mobile visual comparison of Storybook-rendered D20 states through the existing Vitest Browser toolchain, including native review evidence, explicit reference acceptance, and preservation of existing non-visual coverage.
## Requirements
### Requirement: Every discovered story has responsive image references

The frontend package SHALL transform every story discovered by Storybook into a Chromium Vitest Browser Mode test and SHALL compare its complete rendered document against committed light and dark image references at desktop, tablet, and mobile sizes.

#### Scenario: Visual coverage follows Storybook discovery

- **WHEN** a contributor adds a deterministic story matched by `assets/.storybook/main.ts`
- **THEN** the Storybook Vitest integration generates a browser test for that story without adding a second file-name, story-name, identifier, or tag manifest
- **AND** the generated story test runs once in each of the six visual theme and viewport projects
- **AND** no visual test reconstructs the story fixture

#### Scenario: Each responsive state is compared

- **WHEN** a generated story test runs in a generated native theme and viewport project
- **THEN** Storybook establishes the project's `light` or `dark` theme and named `1280x720`, `1024x640`, or `320x900` viewport before decorators, render, and optional `play` execution
- **AND** the existing theme decorator applies the selected theme before rendering, without a toolbar click or browser appearance change
- **AND** the screenshot hook does not change the theme or resize the story after `play`
- **AND** the complete test document is compared through Vitest's native `toMatchScreenshot()` assertion
- **AND** production and Storybook render ordinary text and mathematical symbols with the same lockfile-pinned self-hosted Fontsource assets without a runtime Google Fonts request or host font lookup
- **AND** the pinned mathematical fallback contains U+2264 so maximum-player labels do not depend on a host font
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
- **AND** each reference uses a `<story-path>/<theme>/<viewport>/<browser>/<scenario>-<capture-index>.png` hierarchy with `<theme>` one of `light` or `dark`, `<viewport>` one of `desktop`, `tablet`, or `mobile`, and `<browser>` currently `chromium`
- **AND** each scenario retains the same filename across matrix cells, with the native per-test capture index beginning at `1`
- **AND** the filename does not repeat the theme or browser or include a redundant platform suffix because Linux Chromium is the single supported reference environment
- **AND** generated actual and diff images reside under `assets/.vitest-attachments/<story-path>/<theme>/<viewport>/<browser>/` so concurrent projects cannot overwrite each other
- **AND** generated HTML reports and retained failure traces reside under `assets/.vitest/`
- **AND** only the reviewed references are tracked by Git
- **AND** references and generated test evidence are excluded from the production Docker build context

#### Scenario: A normal comparison detects rendered drift

- **WHEN** rendered pixels differ from a committed reference during a normal test run
- **THEN** the generated story test fails
- **AND** Vitest provides reference, actual, and diff evidence when available
- **AND** the committed reference is not replaced automatically
- **AND** a Playwright-provider trace is retained for the failed Storybook theme and viewport test

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
- **AND** Vitest runs all six light/dark by desktop/tablet/mobile Storybook projects in Chromium
- **AND** each generated Storybook test performs one visual comparison in each theme and viewport project
- **AND** no Storybook development server or second test runner is required

#### Scenario: Run focused visual workflows

- **WHEN** a contributor supplies optional Vitest project, reporter, UI, or update flags through the frontend command boundary
- **THEN** the contributor can run one `visual-<theme>-<viewport>` project, a theme or viewport subset through a project wildcard, or the complete matrix through `--project 'visual-*'`
- **AND** can produce a static HTML report or inspect failures in Vitest UI
- **AND** can update references only when `--update` is explicitly present
- **AND** optional Vitest arguments are forwarded without a custom parser

#### Scenario: Existing non-visual coverage remains authoritative

- **WHEN** Storybook visual comparisons pass
- **THEN** existing semantic, accessibility, focus, interaction, responsive-state, transport, and cross-browser assertions still run independently
- **AND** screenshot success is not treated as proof of those behaviors
- **AND** existing unit and browser test project filters and browser screenshot reference paths remain available unchanged

#### Scenario: Projects progress concurrently with sequential work inside each project

- **WHEN** multiple generated visual projects are selected
- **THEN** they can execute in parallel without ordered project groups
- **AND** each project executes its story files sequentially with `fileParallelism: false`
- **AND** tests and interactions inside a project run sequentially
- **AND** the native project names and artifact directories distinguish concurrent matrix cells
- **AND** each visual project uses its own ignored Vite dependency cache so concurrent project servers do not share mutable optimized modules

### Requirement: Repository validation and documentation include visual regression

The repository SHALL include Storybook visual comparison in its established frontend test validation and SHALL document the essential reference lifecycle without duplicating upstream tool documentation.

#### Scenario: Run aggregate repository checks

- **WHEN** a contributor runs `just check`
- **THEN** the existing `mix assets.test` boundary runs the Storybook theme and viewport projects and their screenshot comparisons in addition to existing frontend tests
- **AND** missing or changed visual references cause aggregate validation to fail
- **AND** the static Storybook build remains a separate required check

#### Scenario: Discover the visual workflow

- **WHEN** a contributor reads the repository Storybook and story-convention documentation
- **THEN** they can identify the pinned Chromium setup, normal comparison, and explicit update commands
- **AND** the tracked reference hierarchy, two native themes, six project names, and three named viewport dimensions
- **AND** the requirement that stories remain deterministic and isolated from live application boundaries

### Requirement: Storybook interactions use deterministic component state

Storybook stories that own user interaction behavior SHALL express that behavior through a `play` function, SHALL remain isolated from live application transports, and SHALL run in the generated Chromium visual theme and viewport projects before screenshot comparison.

#### Scenario: Workspace interaction stories use deterministic state

- **WHEN** a Workspace interaction story is prepared
- **THEN** a Storybook-only `phoenix-session` fixture supplies its complete deterministic session value through `set`
- **AND** shared transport states use a direct reactive status control
- **AND** initial, ready, and cleared state values remain inline and create fresh nested records
- **AND** the story returns `clear` as its cleanup
- **AND** the production Workspace state and runtime session implementation remain unchanged
- **AND** production component changes remain limited to compact-status presentation

#### Scenario: Workspace interaction behavior runs in the visual matrix

- **WHEN** the frontend test workflow runs
- **THEN** the Auto selection story verifies initial selection, Compact restoration, selection switching, keyboard activation, focus order, and fullscreen controls through accessible queries
- **AND** one ready connection-status story renders three sessions, including two Live sessions, one Finished session, and a long-identifier case
- **AND** dedicated Reconnecting and Failed stories present their shared Workspace transport overlays directly
- **AND** accessibility remains a cross-cutting addon check instead of receiving a dedicated Workspace story
- **AND** the generated light/dark by desktop/tablet/mobile Chromium Storybook projects execute each retained story before visual comparison

#### Scenario: Ready compact statuses share stable typography

- **WHEN** Live and Finished sessions render together in the ready connection-status story
- **THEN** each compact status dot and label group remains centered in its fixed-width control
- **AND** Live and Finished use the same reduced font size without state-specific typography overrides
- **AND** both native themes at desktop, tablet, and mobile sizes preserve the reviewed Chromium presentation

#### Scenario: Superseded browser harness is removed

- **WHEN** the retained Storybook stories and lower-layer Workspace tests cover the former browser harness responsibilities
- **THEN** the manual Workspace browser harness is removed
- **AND** lower-layer model and presentation tests retain authoritative snapshot, Phoenix-session, SDK and frame lifecycle, subscription cleanup, and model-contract responsibilities
- **AND** Storybook does not duplicate those lower-layer implementation assertions as separate catalog stories

### Requirement: Stories represent scenarios independently of visual theme

The Storybook catalog SHALL declare each meaningful scenario once and SHALL obtain native light/dark visual coverage from the generated project matrix. Theme-only Dark exports and theme overrides that defeat matrix selection MUST be removed while meaningful fixtures and interactions remain available.

#### Scenario: A contributor selects a scenario in Storybook

- **WHEN** a contributor opens a retained story such as Requested or HeaderFocused
- **THEN** the catalog has no duplicate entry whose only distinction is a dark theme
- **AND** the existing theme toolbar can switch that scenario between native light and dark
- **AND** the existing default light theme and available-canvas viewport behavior remain intact

#### Scenario: Existing Storybook references migrate to the matrix

- **WHEN** the visual matrix replaces the previous viewport-only projects
- **THEN** each retained story has a reviewed native reference in every theme and viewport combination
- **AND** obsolete viewport-first Storybook references and theme-only alias references are removed
- **AND** standalone browser test references remain unchanged
- **AND** normal comparison passes after explicit native reference generation and review

### Requirement: Fullscreen interaction validation uses trusted browser input

The Workspace interaction story SHALL validate actual fullscreen entry and exit without depending on trace recording to produce incidental user activation.

#### Scenario: Run the fullscreen story through the native test command

- **WHEN** AutoSelection runs in the Vitest visual project
- **THEN** the visual project's documented environment marker selects the public Vitest Browser native click API for fullscreen entry, independently of `--mode`
- **AND** the existing enter/exit, keyboard, focus and semantic assertions remain unchanged
- **AND** the test does not mock fullscreen or bypass browser activation requirements
- **AND** ordinary Storybook development and production builds retain their portable interaction path without requiring the Vitest browser runtime
