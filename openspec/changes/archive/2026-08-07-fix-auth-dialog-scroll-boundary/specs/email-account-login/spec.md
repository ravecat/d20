## MODIFIED Requirements

### Requirement: Account dialog follows the active mode content size

At viewports wider than the supported mobile breakpoint and tall enough to contain the active mode, the account dialog SHALL derive its block size from that mode's content through CSS while retaining one common inline size. At supported mobile viewport widths, the account dialog SHALL nearly fill the available dynamic viewport within a small safe-area-aware outer inset and SHALL retain its border, rounded corners, and shadow so it remains visually identifiable as a dialog. The native dialog SHALL own its visible surface, and the title, description, notices, forms, results, separators, provider choices, and mode switch SHALL share one common responsive content inset. The title row and explicit close action SHALL remain outside one internal body scroller and SHALL use the same responsive inline inset as the body content. That scroller SHALL span the dialog surface to its inline edges, SHALL start with the active account description, and SHALL contain every following notice, form, result, separator, provider choice, and mode switch in document order. The scroller's own responsive inline padding SHALL preserve the common content inset and separate its child content from the user-agent scrollbar. Non-scrolling account content MUST NOT reserve scrollbar space and SHALL keep equal inline insets between the dialog content edges and full-width method controls. Switching between Register and Login MUST NOT require scripted DOM measurement, numeric block-size writes, animation-frame scheduling, or resize timers. When the active mode is taller than the available viewport, the dialog SHALL constrain itself within the outer inset, keep the title row visible, and keep the complete body reachable through its single internal scroller.

#### Scenario: Guest switches modes on a desktop viewport

- **WHEN** a guest opens Register and switches to Login at a viewport that can contain the complete Login layout
- **THEN** the dialog retains its inline size and adopts the Login content block size through normal CSS layout
- **AND** the dialog surface provides one common inline inset for the active mode regions
- **AND** the body scrollport reaches both inline edges of the dialog surface while its child content retains that inset
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
- **AND** the body scrollport reaches the surface's inline-end edge independently of native scrollbar width

#### Scenario: Active dialog content exceeds the viewport

- **WHEN** the available viewport is shorter than the active mode's complete content size
- **THEN** the dialog remains within the viewport
- **AND** the dialog retains its responsive content inset
- **AND** the title row and close action remain outside the scrolling region
- **AND** one body scroller contains the description and every following active-mode row through the final mode content
- **AND** the native scrollbar belongs to that body scroller at the dialog surface's inline-end edge while body content remains inset
- **AND** scrolling that body keeps all active controls reachable without moving the title row
