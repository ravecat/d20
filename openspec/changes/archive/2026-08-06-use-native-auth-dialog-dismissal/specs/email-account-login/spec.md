## MODIFIED Requirements

### Requirement: Login dialog remains keyboard and viewport accessible

The account dialog SHALL use native modal dialog semantics, expose an accessible name for the active mode, use programmatically associated labels for every form field, preserve visible focus indicators, support native Escape and an explicit close action, restore focus to the invoking header action, and keep all active controls reachable at supported narrow and wide viewports. The implementation MUST NOT add a custom Tab focus trap to the native modal dialog. The account dialog SHALL declare native light dismissal for browsers that support it and MUST NOT implement backdrop hit testing through scripted pointer-coordinate or dialog-bound calculations. Browsers without native light-dismiss support SHALL retain Escape and the explicit close action.

#### Scenario: Keyboard user switches and closes login

- **WHEN** a keyboard user opens Register, switches to Login, and closes with Escape
- **THEN** focus enters the active Login mode after the switch
- **AND** the browser contains focus within the native modal while it is open
- **AND** focus returns to the Register trigger after close

#### Scenario: Browser supports native modal light dismissal

- **WHEN** Login mode is open in a browser that supports native modal light dismissal and the guest activates the CSS-styled backdrop
- **THEN** the browser closes the dialog without application pointer-coordinate or dialog-bound hit testing
- **AND** focus returns to the invoking header action

#### Scenario: Browser does not support native modal light dismissal

- **WHEN** Login mode is open in a browser without native modal light-dismiss support
- **THEN** the guest can still close the dialog with Escape or the explicit close action

#### Scenario: Login opens on a narrow viewport

- **WHEN** a guest opens Login at a supported mobile viewport width
- **THEN** both enabled forms, provider choices, the mode switch, status messages, and close action remain visible or reachable by scrolling
