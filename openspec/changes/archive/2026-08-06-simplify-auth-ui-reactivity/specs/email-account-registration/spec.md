## MODIFIED Requirements

### Requirement: Registration dialog is keyboard and viewport accessible

The registration dialog SHALL use native modal dialog semantics, expose an accessible name, move focus into the open dialog, support Escape and an explicit close action, preserve visible focus indicators, and keep all content operable at supported narrow and wide viewport sizes. Register title copy SHALL be selected directly inside the rendered heading from component input properties and MUST NOT be stored in intermediate reactive state. The implementation SHALL leave post-close focus placement to native dialog behavior and MUST NOT require a caller-supplied return-focus element or explicitly focus the Register trigger after close. The registration dialog SHALL declare native light dismissal for browsers that support it and MUST NOT implement backdrop hit testing through scripted pointer-coordinate or dialog-bound calculations. Browsers without native light-dismiss support SHALL retain Escape and the explicit close action.

#### Scenario: Keyboard user opens and closes registration

- **WHEN** a keyboard user activates Register and then closes the dialog with Escape
- **THEN** focus is contained within the modal while it is open
- **AND** the application closes the dialog without explicitly focusing the Register action

#### Scenario: Browser supports native modal light dismissal

- **WHEN** Register mode is open in a browser that supports native modal light dismissal and the guest activates the CSS-styled backdrop
- **THEN** the browser closes the dialog without application pointer-coordinate or dialog-bound hit testing
- **AND** the application does not require the Register action as a return-focus element

#### Scenario: Browser does not support native modal light dismissal

- **WHEN** Register mode is open in a browser without native modal light-dismiss support
- **THEN** the guest can still close the dialog with Escape or the explicit close action

#### Scenario: Registration opens on a narrow viewport

- **WHEN** a guest opens registration at a supported mobile viewport width
- **THEN** the email field, Create account action, provider choices, login action, status messages, and close action remain visible or reachable by scrolling

#### Scenario: Registration heading selects localizable copy

- **WHEN** the shared dialog renders Register mode
- **THEN** its heading selects `Create your free account` directly from component input properties at the markup consumption site
- **AND** the selected display string is not stored in intermediate reactive state
