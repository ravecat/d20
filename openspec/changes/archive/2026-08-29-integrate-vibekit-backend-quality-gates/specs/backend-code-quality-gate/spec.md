## ADDED Requirements

### Requirement: Development-only backend quality toolchain

The project SHALL make Credo, Dialyxir, ExDNA, ExSlop, and Reach available for development and test validation and SHALL exclude those tools and the standalone Vibe agent from the production runtime dependency graph.

#### Scenario: Contributor resolves development dependencies

- **WHEN** dependencies are resolved for development or test
- **THEN** every configured backend quality tool is available through its Mix task
- **AND** the tool versions are reproducibly locked by the project

#### Scenario: Production dependencies are resolved

- **WHEN** dependencies and application metadata are resolved for production
- **THEN** Credo, Dialyxir, ExDNA, ExSlop, Reach, VibeKit, and Vibe are absent from the production runtime application set

### Requirement: Single backend quality command

The project SHALL expose `mix ci` as the single complete backend quality command, SHALL run it in the test environment, and MUST stop unsuccessfully when any required stage fails.

#### Scenario: Backend quality gate succeeds

- **WHEN** a contributor runs `mix ci` against a compliant checkout with the test database available
- **THEN** the command runs warnings-as-errors compilation, backend formatting verification, backend tests, strict Credo with ExSlop, Dialyzer, ExDNA, and Reach in the documented order
- **AND** every stage completes successfully

#### Scenario: Required backend stage fails

- **WHEN** any required `mix ci` stage returns an unsuccessful result
- **THEN** the backend gate exits unsuccessfully
- **AND** later stages do not conceal the failing stage or report overall success

#### Scenario: Backend tests require database setup

- **WHEN** `mix ci` reaches the backend test stage
- **THEN** it uses the existing test alias that creates and migrates the test database before running ExUnit

### Requirement: Project-calibrated analyzer policy

The backend gate SHALL store analyzer policy in reviewable project configuration, SHALL prefer source corrections over suppression, and MUST NOT use blanket ignore rules to obtain a passing baseline.

#### Scenario: Existing duplication is accepted temporarily

- **WHEN** reviewed existing ExDNA clone groups cannot be removed within this change without unrelated refactoring
- **THEN** the gate uses an explicit measured maximum clone budget and checked-in analysis scope
- **AND** any clone count above that budget fails the gate

#### Scenario: Analyzer warning is suppressed

- **WHEN** a Credo/ExSlop or Dialyzer finding is a demonstrated false positive or external incompatibility
- **THEN** the configuration identifies the narrow finding and its rationale
- **AND** unrelated findings remain enabled

#### Scenario: Existing clone count is reduced

- **WHEN** accepted cleanup lowers the reviewed ExDNA clone count
- **THEN** the configured clone budget is reduced to prevent reintroducing the removed duplication

### Requirement: Domain-to-web architecture enforcement

Reach policy SHALL classify pure D20 domain and game-policy modules separately from `D20Web.*` and MUST reject a direct dependency from a classified pure-domain module to the web layer. Application composition and runtime adapters with an explicit publication responsibility MAY depend on web-owned processes without being classified as pure domain.

#### Scenario: Pure domain module imports the web layer

- **WHEN** a classified pure-domain module introduces a direct dependency on a `D20Web.*` module
- **THEN** `mix reach.check --arch` reports the violating dependency and exits unsuccessfully

#### Scenario: Runtime adapter publishes through a web-owned process

- **WHEN** an explicitly classified application or runtime adapter depends on an allowed web-owned process
- **THEN** the Reach architecture policy does not misclassify that adapter dependency as a pure-domain violation

#### Scenario: Reach reports heuristic smells

- **WHEN** Reach finds a heuristic smell that is not an architecture-policy violation
- **THEN** the backend gate displays the finding as review evidence
- **AND** the initial policy does not fail solely because of that advisory smell

### Requirement: Quality gate preserves application contracts

Integrating and satisfying the backend quality gate MUST preserve D20's public APIs, routes, Phoenix channel contracts, schemas, persistence behavior, session and game runtime semantics, iframe module contracts, and production startup behavior.

#### Scenario: Production application starts after integration

- **WHEN** D20 is compiled and started with production dependencies after the quality gate is integrated
- **THEN** no quality tool or Vibe process is started
- **AND** existing application children and external contracts remain unchanged

#### Scenario: Analyzer finding requires out-of-scope behavior change

- **WHEN** resolving an analyzer finding would require a public contract, persistence, or user-visible behavior change
- **THEN** that behavior change is not performed under this change
- **AND** the finding is handled through a narrow justified policy or separate tracked work

### Requirement: Backend quality workflow documentation

Repository documentation SHALL identify the complete and focused backend quality commands, the first-run Dialyzer PLT cost, the ExDNA baseline policy, and the boundary between this local gate and release workflow task #113.

#### Scenario: Contributor investigates a failed gate

- **WHEN** a contributor consults repository documentation after `mix ci` fails
- **THEN** the documentation identifies how to run the failing analyzer independently
- **AND** explains how findings and baselines are reviewed without blanket suppression
