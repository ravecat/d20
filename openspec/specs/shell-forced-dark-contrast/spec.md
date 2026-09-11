# shell-forced-dark-contrast Specification

## Purpose
Keep shell surfaces and interactive links readable under the reproduced external forced-dark transformation while preserving native themes and shell behavior.
## Requirements
### Requirement: Game-detail surfaces remain readable under forced-dark rendering

The shell SHALL render the game-detail description, activation panel, metadata, and supported activation states with contrasting foreground and background colors when the light-themed document is transformed by the reproduced Dark Reader dynamic forced-dark environment. Corrected ordinary text and enabled action labels SHALL retain at least 4.5:1 contrast, or 3:1 for large text, against their actual rendered surfaces.

#### Scenario: An unavailable game is viewed with forced dark enabled
- **WHEN** a light-themed unavailable game-detail page is rendered with the reproduced forced-dark transformation
- **THEN** its description and activation panels do not retain a pale background behind pale text
- **AND** its metadata and interest action remain readable

#### Scenario: Activation states share the corrected surface
- **WHEN** game detail presents Play, Lobby, interest, or saved Requested state on the corrected activation surface
- **THEN** each state's text, metadata, and relevant controls remain perceivable
- **AND** pending and disabled controls retain their existing interaction restrictions
- **AND** error feedback remains visible without changing submission or session behavior

### Requirement: Shell links retain contrast in interactive states

The shell SHALL keep the D20 linked brand, header navigation, footer links, and body or heading links readable against their rendered surfaces in default, hover, keyboard-focus, and existing current-page states. It MUST preserve existing keyboard-focus indicators and navigation behavior.

#### Scenario: Header brand receives hover or keyboard focus
- **WHEN** the user hovers or keyboard-focuses the D20 home link in the reproduced forced-dark environment
- **THEN** its label retains a contrasting foreground instead of becoming dark on a dark header
- **AND** keyboard focus retains the visible label underline
- **AND** the same behavior holds in the expanded and compact header

#### Scenario: A shared content or navigation link becomes interactive
- **WHEN** a footer, header, body, or heading link is hovered, keyboard-focused, or marked as the current page where that state exists
- **THEN** its foreground remains readable against its actual surface
- **AND** its accessible name, destination, focus treatment, and interaction remain intact

### Requirement: Additional shell corrections are based on observed contrast failures

The delivery SHALL inspect the existing public shell pages, authentication and account screens, shared feedback, and workspace controls for the same forced-dark surface/foreground failures. It SHALL record the inspected families, relevant states, observed failures or unchanged outcomes, and the declarations corrected. Source syntax alone MUST NOT be treated as proof of a rendering failure.

#### Scenario: Related color declarations are audited
- **WHEN** a metadata label, provider action, notification, or workspace control contains a related color mixture
- **THEN** its foreground and background are inspected in its real rendered context, including relevant hover, focus, error, pending, or disabled states
- **AND** a correction is limited to a demonstrated readability failure
- **AND** correctly rendered transparent mixtures and unrelated layout remain unchanged

#### Scenario: Shared pages complete the audit
- **WHEN** the contrast correction is prepared for completion
- **THEN** the owning delivery artifact records coverage of Home/catalog, existing public information pages, game detail, authentication/confirmation/registration, profile, persistent shell, and workspace feedback/controls
- **AND** it distinguishes live forced-dark observations from native-theme and deterministic-preview verification

### Requirement: Native themes and shell contracts remain stable

The correction SHALL preserve the selected native light or dark theme, existing responsive composition, accessible semantics, and all supported shell workflow states. It MUST NOT detect an extension, overwrite stored theme preferences, disable external forced-dark rendering, or modify backend, persistence, session, or embedded-game contracts.

#### Scenario: The application is used without external recoloring
- **WHEN** the corrected shell renders in its native light or dark theme
- **THEN** corrected surfaces, labels, links, and focus indicators remain readable
- **AND** page geometry and existing action, loading, error, success, pending, and disabled behavior remain intact
- **AND** existing Compact workspace inversion and Theater behavior continue to follow their authoritative contracts

#### Scenario: A visitor retains a chosen theme
- **WHEN** the corrected application opens with a stored theme preference and an external forced-dark transformation
- **THEN** the application preserves that preference and its existing theme-selection behavior
- **AND** the contrast fix requires no extension detection or preference mutation

#### Scenario: Theme styles are delivered through the existing asset pipeline
- **WHEN** theme CSS is served in development or compiled for production
- **THEN** the complete active theme remains available to the reproduced external transformation so corresponding foreground and background roles can be recolored together
- **AND** explicit light, explicit dark, and existing system-preference selection retain their native cascade behavior
- **AND** the correction uses the existing theme definitions without a duplicated runtime palette

#### Scenario: Phoenix root layouts load cross-origin development styles
- **WHEN** either Phoenix root layout renders the existing Vite asset references
- **THEN** generated stylesheet links use anonymous CORS so the existing CORS-enabled development asset server permits access to their CSS rules
- **AND** existing asset URLs, manifest entry resolution, JavaScript loading, authentication, and theme selection remain intact
- **AND** no credentialed CORS mode or broader server CORS policy is introduced

### Requirement: Verification covers native themes and the reproduced external transformation

The delivery SHALL verify the forced-dark reproduction in the selected existing development browser and SHALL review representative affected native light/dark Storybook states through generated light/dark by desktop/tablet/mobile screenshot projects. A native dark theme or dark media-query emulation alone MUST NOT be presented as verification of external dynamic recoloring.

#### Scenario: Forced-dark behavior is verified
- **WHEN** the fix is checked in the existing development browser
- **THEN** the delivery records the selected URL, forced-dark mechanism, application theme, relevant computed colors, screenshots, and observed results
- **AND** the corrected game panels and interactive header link are visibly readable
- **AND** prepared browser route, viewport, and theme state are restored after inspection

#### Scenario: Native visual references are reviewed
- **WHEN** Storybook cases run in each combination of native light/dark theme and desktop/tablet/mobile size
- **THEN** production components render the same deterministic scenarios in both native themes without theme-only story exports, live submissions, or transports
- **AND** the project sets its theme and viewport before rendering and interaction execution
- **AND** affected baseline, actual, and available diff images are inspected before intentional reference updates are accepted
- **AND** normal screenshot comparisons pass against the reviewed references together with the relevant existing behavior checks
