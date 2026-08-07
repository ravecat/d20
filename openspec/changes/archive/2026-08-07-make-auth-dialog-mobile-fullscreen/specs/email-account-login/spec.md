## MODIFIED Requirements

### Requirement: Account dialog follows the active mode content size

At viewports wider than the supported mobile breakpoint and tall enough to contain the active mode, the account dialog SHALL derive its block size from that mode's content through CSS while retaining one common inline size. At supported mobile viewport widths, the account dialog SHALL nearly fill the available dynamic viewport within a small safe-area-aware outer inset and SHALL retain its border, rounded corners, and shadow so it remains visually identifiable as a dialog. The native dialog SHALL own its visible surface and common responsive content inset, and the title, description, notices, forms, results, separators, provider choices, and mode switch SHALL share that inline alignment without independent horizontal region padding. Non-scrolling account content MUST NOT reserve scrollbar space and SHALL keep equal inline insets between the dialog content edges and full-width method controls. Switching between Register and Login MUST NOT require scripted DOM measurement, numeric block-size writes, animation-frame scheduling, or resize timers. When the active mode is taller than the available viewport, the dialog SHALL constrain itself within the outer inset and keep active content reachable through internal scrolling.

#### Scenario: Guest switches modes on a desktop viewport

- **WHEN** a guest opens Register and switches to Login at a viewport that can contain the complete Login layout
- **THEN** the dialog retains its inline size and adopts the Login content block size through normal CSS layout
- **AND** the dialog surface provides one common inline inset for the active mode regions
- **AND** a non-scrolling full-width account control has equal inline-start and inline-end insets
- **AND** switching back adopts the shorter Register content block size without an inline block-size override
- **AND** neither mode requires internal scrolling

#### Scenario: Registration result replaces its email form

- **WHEN** a guest successfully submits the email registration form at a viewport that can contain Register mode
- **THEN** the dialog retains its common inline size
- **AND** the check-email result uses the same inline alignment as the replaced form and surrounding Register mode content
- **AND** the dialog block size changes only by the natural size difference between the email form and result

#### Scenario: Account dialog opens on a mobile viewport

- **WHEN** a guest opens Register or Login at a supported mobile viewport width
- **THEN** a small outer reveal separates every dialog edge from the available dynamic viewport edge
- **AND** each outer reveal respects the corresponding device safe area
- **AND** the surface retains its border, rounded corners, and shadow
- **AND** each content edge retains the common mobile inset

#### Scenario: Active dialog content exceeds the viewport

- **WHEN** the available viewport is shorter than the active mode's complete content size
- **THEN** the dialog remains within the viewport
- **AND** the dialog retains its responsive content inset
- **AND** active controls remain reachable through the dialog's content scroller

### Requirement: Login dialog remains keyboard and viewport accessible

The account dialog SHALL use native modal dialog semantics, expose an accessible name for the active mode, use programmatically associated labels for every form field, preserve visible focus indicators, support native Escape and an explicit close action, and keep all active controls reachable at supported narrow and wide viewports. The implementation SHALL leave post-close focus placement to native dialog behavior and MUST NOT require a caller-supplied return-focus element or explicitly focus a caller-owned element after close. The implementation MUST NOT add a custom Tab focus trap to the native modal dialog. The account dialog SHALL declare native light dismissal for browsers that support it and MUST NOT implement backdrop hit testing through scripted pointer-coordinate or dialog-bound calculations. Browsers without native light-dismiss support SHALL retain Escape and the explicit close action.

#### Scenario: Keyboard user switches and closes login

- **WHEN** a keyboard user opens Register, switches to Login, and closes with Escape
- **THEN** focus enters the active Login mode after the switch
- **AND** the browser contains focus within the native modal while it is open
- **AND** the application closes the dialog without explicitly focusing a caller-owned element

#### Scenario: Browser supports native modal light dismissal

- **WHEN** Login mode is open in a browser that supports native modal light dismissal and the guest activates the CSS-styled backdrop
- **THEN** the browser closes the dialog without application pointer-coordinate or dialog-bound hit testing
- **AND** the application does not require a caller-supplied return-focus element

#### Scenario: Browser does not support native modal light dismissal

- **WHEN** Login mode is open in a browser without native light-dismiss support
- **THEN** the guest can still close the dialog with Escape or the explicit close action

#### Scenario: Login opens on a narrow viewport

- **WHEN** a guest opens Login at a supported mobile viewport width
- **THEN** Login uses the near-full-viewport inset account surface
- **AND** both enabled forms, provider choices, the mode switch, status messages, and close action remain visible or reachable by scrolling
