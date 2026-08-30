## MODIFIED Requirements

### Requirement: Game detail page insets remain compact and symmetric
The game detail page SHALL use one equal physical inline inset across its app header, main content, and app footer: `1rem` at and below the existing `48rem` breakpoint and `1.5rem` above that breakpoint. It SHALL retain block-end edge protection while using the document root as its only page-level vertical scrolling element.

#### Scenario: Game detail renders on a narrow viewport
- **WHEN** a player opens a game detail page at or below the existing `48rem` breakpoint
- **THEN** the app header, game detail shell, and app footer align to a `1rem` inset on each physical inline edge
- **AND** the preview, activation content, action, and description remain inside those insets
- **AND** the D20 brand, account action, and footer link remain inside those insets

#### Scenario: Game detail renders on a wide viewport
- **WHEN** a player opens a game detail page above the existing `48rem` breakpoint
- **THEN** the app header, game detail shell, and app footer align to a `1.5rem` inset on each physical inline edge
- **AND** the split layout remains inside those insets

#### Scenario: Game detail content exceeds a wide viewport
- **WHEN** game detail content overflows the viewport vertically
- **THEN** the document root is the only page-level vertical scrolling element
- **AND** the main region does not reserve its own scrollbar gutter or scroll independently
- **AND** the app header, game detail shell, and app footer keep equal physical inline insets
- **AND** the shell retains its block-end padding

#### Scenario: Narrow-layout page uses the standard shell
- **WHEN** a page uses the default narrow app-shell variant
- **THEN** its existing `1rem` header and footer insets remain unchanged
