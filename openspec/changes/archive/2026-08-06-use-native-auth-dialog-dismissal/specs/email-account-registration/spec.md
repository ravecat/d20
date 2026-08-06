## MODIFIED Requirements

### Requirement: Registration dialog is keyboard and viewport accessible

The registration dialog SHALL use native modal dialog semantics, expose an accessible name, move focus into the open dialog, support Escape and an explicit close action, restore focus to the Register trigger after close, preserve visible focus indicators, and keep all content operable at supported narrow and wide viewport sizes. The registration dialog SHALL declare native light dismissal for browsers that support it and MUST NOT implement backdrop hit testing through scripted pointer-coordinate or dialog-bound calculations. Browsers without native light-dismiss support SHALL retain Escape and the explicit close action.

#### Scenario: Keyboard user opens and closes registration

- **WHEN** a keyboard user activates Register and then closes the dialog with Escape
- **THEN** focus is contained within the modal while it is open
- **AND** focus returns to the Register action after it closes

#### Scenario: Browser supports native modal light dismissal

- **WHEN** Register mode is open in a browser that supports native modal light dismissal and the guest activates the CSS-styled backdrop
- **THEN** the browser closes the dialog without application pointer-coordinate or dialog-bound hit testing
- **AND** focus returns to the Register action

#### Scenario: Browser does not support native modal light dismissal

- **WHEN** Register mode is open in a browser without native modal light-dismiss support
- **THEN** the guest can still close the dialog with Escape or the explicit close action

#### Scenario: Registration opens on a narrow viewport

- **WHEN** a guest opens registration at a supported mobile viewport width
- **THEN** the email field, Create account action, provider choices, login action, status messages, and close action remain visible or reachable by scrolling
