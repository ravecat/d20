## ADDED Requirements

### Requirement: Shared browser-support policy
The frontend package SHALL define its supported browsers with the following Browserslist query and exclusion:

```json
[
  "baseline widely available with downstream",
  "not Firefox < 128"
]
```

#### Scenario: Resolve supported browsers
- **WHEN** a developer runs the supported-browser inspection command
- **THEN** Browserslist returns the Baseline Widely Available browser set with downstream browsers
- **AND** the result contains no Firefox version below 128

#### Scenario: Advance the moving Baseline policy
- **WHEN** the Browserslist compatibility data or evaluation date advances
- **THEN** the supported browser set may advance without manually changing version literals
- **AND** the Firefox 128 minimum exclusion remains effective

### Requirement: Inspectable compiler targets
The frontend package SHALL provide a repository command that converts the shared Browserslist policy into one compact minimum target per compiler-supported browser family.

#### Scenario: Inspect production compiler targets
- **WHEN** a developer runs the compiler-target inspection command
- **THEN** the command prints targets accepted by Vite 8's Oxc transformer
- **AND** the printed Firefox target is 128 or newer

### Requirement: Browser compatibility linting
The existing frontend lint command SHALL check recognized Web APIs and ES APIs against the shared Browserslist policy.

#### Scenario: Lint an unsupported API
- **WHEN** frontend JavaScript, TypeScript, or a Svelte script uses a recognized API unsupported by at least one declared browser without a guarded fallback or declared polyfill
- **THEN** `mix assets.lint` returns a non-zero status with a compatibility diagnostic

#### Scenario: Lint guarded feature use
- **WHEN** frontend code guards an optional API with recognized feature detection before use
- **THEN** compatibility linting permits the guarded use under its default conditional-check behavior

#### Scenario: Lint a provided polyfill
- **WHEN** the repository provides a polyfill and declares that exact API in the ESLint compatibility settings
- **THEN** compatibility linting does not report the polyfilled API solely because a target lacks native support

### Requirement: Browser-derived production build
The Vite 8 production build SHALL derive its JavaScript target from the shared Browserslist policy and SHALL let the default CSS target inherit the same compact target array.

#### Scenario: Build with the shared policy
- **WHEN** a developer runs `mix assets.build`
- **THEN** Vite 8 lowers and minifies JavaScript for the resolved browser targets
- **AND** CSS minification uses the same target array by default
- **AND** the production manifest retains the existing application entry records

### Requirement: Stable validation command boundary
Browser-policy enforcement SHALL run through the existing frontend lint and build commands without replacing the repository's Mix aliases or top-level just recipes.

#### Scenario: Run repository checks
- **WHEN** a developer runs `just check`
- **THEN** compatibility linting executes through the existing frontend lint path
- **AND** the established frontend and backend validation commands remain available

### Requirement: Compatibility scope disclosure
The browser-support integration SHALL NOT claim to provide runtime API polyfills, legacy bundles, CSS source linting, HTML compatibility linting, or real-browser behavioral verification.

#### Scenario: Encounter a platform behavior outside static coverage
- **WHEN** compatibility depends on partial implementation, permissions, browser defects, rendering, or an unrecognized HTML or CSS feature
- **THEN** the static browser policy does not treat a successful lint and build as proof of runtime compatibility
