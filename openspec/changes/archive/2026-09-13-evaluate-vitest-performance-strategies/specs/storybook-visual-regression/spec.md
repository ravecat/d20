## MODIFIED Requirements

### Requirement: Every discovered story has responsive image references

The frontend package SHALL transform every story discovered by Storybook into a Chromium Vitest Browser Mode test and SHALL compare its complete rendered document against committed light and dark image references at desktop, tablet, and mobile sizes.

#### Scenario: Visual coverage follows Storybook discovery

- **WHEN** a contributor adds a deterministic story matched by `assets/.storybook/main.ts`
- **THEN** the Storybook Vitest integration generates a browser test for that story without adding a second file-name, story-name, identifier, or tag manifest
- **AND** the generated story test runs once in each of the six named visual theme and viewport browser instances
- **AND** no visual test reconstructs the story fixture

#### Scenario: Each responsive state is compared

- **WHEN** a generated story test runs in a named native theme and viewport instance
- **THEN** Storybook establishes the instance's `light` or `dark` theme and named `1280x720`, `1024x640`, or `320x900` viewport before decorators, render, and optional `play` execution
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
- **AND** routine runs disable Playwright trace recording to reduce overhead
- **AND** a single-instance, single-file diagnostic rerun with the native `--browser.trace on` option records a trace without changing screenshot assertions or references

#### Scenario: A new story has no accepted reference

- **WHEN** a discovered story is compared before a matching reference exists
- **THEN** Vitest creates the candidate reference and fails the comparison
- **AND** a contributor must review the candidate and run a normal comparison before the reference is accepted as passing

### Requirement: One Vitest command surface preserves existing coverage

The frontend test command SHALL run existing unit and cross-browser behavior tests together with Storybook visual projects without replacing their established environments, browsers, or responsibilities.

#### Scenario: Run the complete frontend test workflow

- **WHEN** a contributor runs the frontend `test` script without project filters
- **THEN** Vitest runs the existing jsdom unit project
- **AND** Vitest runs the existing browser project in Chromium and Firefox at its established viewport
- **AND** Vitest runs all six named light/dark by desktop/tablet/mobile Storybook browser instances in Chromium
- **AND** each generated Storybook test performs one visual comparison in each theme and viewport instance
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

#### Scenario: Visual instances share preparation without losing independence

- **WHEN** multiple visual theme and viewport instances are selected
- **THEN** one Storybook Vite project shares preparation and one ignored dependency cache across its six named native browser instances
- **AND** public per-instance `provide` and `inject` values establish Storybook globals through the framework's public annotation API before render and play
- **AND** all applicable registered addon annotations and repository preview annotations remain active
- **AND** each visual instance executes at most two files concurrently with isolation enabled
- **AND** the visual group uses native `sequence.groupOrder: 1` after the existing unit/browser group so different worker limits remain valid
- **AND** tests and interactions within a file remain sequential
- **AND** any file concurrency or browser isolation setting is adopted only after equivalent repeated runs and changed-order independence checks
- **AND** native instance names and artifact directories distinguish all matrix cells without collisions

## ADDED Requirements

### Requirement: Fullscreen interaction validation uses trusted browser input

The Workspace interaction story SHALL validate actual fullscreen entry and exit without depending on trace recording to produce incidental user activation.

#### Scenario: Run the fullscreen story through the native test command

- **WHEN** AutoSelection runs in the Vitest visual project
- **THEN** the visual project's documented environment marker selects the public Vitest Browser native click API for fullscreen entry, independently of `--mode`
- **AND** the existing enter/exit, keyboard, focus and semantic assertions remain unchanged
- **AND** the test does not mock fullscreen or bypass browser activation requirements
- **AND** ordinary Storybook development and production builds retain their portable interaction path without requiring the Vitest browser runtime
