## ADDED Requirements

### Requirement: Short pages place naturally sized footer content at the viewport bottom

The App layout SHALL fill at least the dynamic viewport height. When page content is short, main SHALL consume remaining space and the footer SHALL retain its natural content height, including its existing padding and safe-area inset. Spare page height MUST NOT become an empty region beneath footer navigation.

#### Scenario: Short content on narrow and wide screens

- **WHEN** main content and the footer fit within the viewport
- **THEN** main consumes spare height and the footer ends at the viewport bottom
- **AND** the footer keeps its intrinsic height and existing inner padding

#### Scenario: Mobile footer disclosures expand

- **WHEN** a visitor expands or collapses a footer disclosure
- **THEN** the footer accommodates its content and main adjusts to the remaining space
- **AND** the links and legal strip remain accessible

### Requirement: Long pages retain normal document scrolling

The layout SHALL grow beyond the viewport when its contents require more space, with the footer after main in normal document flow. It SHALL preserve fixed-header spacing, keyboard focus, and Workspace overlay behavior.

#### Scenario: Content exceeds viewport height

- **WHEN** page content exceeds the available viewport height
- **THEN** the document scrolls to the footer after the full main content
- **AND** the footer does not overlay, shrink, or clip the content
