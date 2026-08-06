## MODIFIED Requirements

### Requirement: Account dialog follows the active mode content size

At viewports tall enough to contain the active mode, the account dialog SHALL derive its block size from that mode's content through CSS while retaining one common inline size. The native dialog SHALL own its visible surface and common responsive content inset, and the title, description, notices, forms, results, separators, provider choices, and mode switch SHALL share that inline alignment without independent horizontal region padding. Non-scrolling account content MUST NOT reserve scrollbar space and SHALL keep equal inline insets between the dialog content edges and full-width method controls. Switching between Register and Login MUST NOT require scripted DOM measurement, numeric block-size writes, animation-frame scheduling, or resize timers. When the active mode is taller than the available viewport, the dialog SHALL constrain itself to the viewport and keep active content reachable through internal scrolling.

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

#### Scenario: Active dialog content exceeds the viewport

- **WHEN** the available viewport is shorter than the active mode's complete content size
- **THEN** the dialog remains within the viewport
- **AND** the dialog retains its responsive content inset
- **AND** active controls remain reachable through the dialog's content scroller
