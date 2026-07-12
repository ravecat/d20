## ADDED Requirements

### Requirement: Footer links to the developer area
Every Inertia game-shell footer SHALL provide an internal link to `/developers` with visible text `for developers`.

#### Scenario: User follows the footer link
- **WHEN** a user activates the `for developers` footer link
- **THEN** the application navigates to `/developers` through Inertia
- **AND** the destination renders inside the standard game app shell

### Requirement: Developer entry page introduces client implementation
The application SHALL expose `GET /developers` as an Inertia page titled `For developers` and SHALL explain that engineers can use game AsyncAPI contracts to implement compatible clients.

#### Scenario: Developer page is requested
- **WHEN** a visitor requests `/developers`
- **THEN** the server responds with the `developers` Inertia component
- **AND** the page renders a level-one heading `For developers`
- **AND** the page explains that the listed AsyncAPI contracts describe how compatible clients connect and exchange game messages

### Requirement: Developer page indexes current game specifications
The developer page SHALL derive a semantic list from every registered game that has a matching static `priv/specs/<slug>.yaml` file. Every entry SHALL be one compact row containing only the game name, an `Open reference` link, and a `YAML` link. Registered games without a matching specification and unregistered specification files SHALL remain absent.

#### Scenario: Specification list renders
- **WHEN** the developer page is displayed
- **THEN** the semantic list contains one row for Qwinto and one row for Koala Rescue Club
- **AND** each row displays the game name, `Open reference`, and `YAML` on one line
- **AND** the links target the matching interactive reference and raw YAML endpoint
- **AND** the list does not display a section heading, availability count, description, protocol label, or version label

#### Scenario: Matching specification is added
- **WHEN** a registered game gains a static `priv/specs/<slug>.yaml` file
- **THEN** its game slug is included in the developer list without adding a game-specific router or Svelte entry

### Requirement: Developer index matches the application visual language
The developer page SHALL inherit the application's existing typography and SHALL use the compact catalog content insets instead of page-specific fonts or oversized landing-page spacing.

#### Scenario: Developer index is displayed in the app shell
- **WHEN** the developer page is displayed at a desktop or narrow viewport
- **THEN** its headings and body copy use the shared application font stack
- **AND** its outer content inset matches the catalog page at that viewport
- **AND** the compact specification rows remain on one line without horizontal overflow

### Requirement: Game specifications are publicly readable
The application SHALL expose game AsyncAPI contracts through the dynamic read-only routes `/developers/specs/:slug` and `/developers/specs/:slug/raw`. The application SHALL resolve `:slug` through the game registry and SHALL serve only a matching static `priv/specs/<slug>.yaml` file.

#### Scenario: Engineer opens an interactive reference
- **WHEN** an engineer requests `/developers/specs/qwinto` or `/developers/specs/koala-rescue-club`
- **THEN** the server responds with an HTML AsyncAPI reference
- **AND** the reference renderer loads the matching same-origin raw specification URL

#### Scenario: Engineer requests a raw contract
- **WHEN** an engineer requests `/developers/specs/qwinto/raw` or `/developers/specs/koala-rescue-club/raw`
- **THEN** the server responds with the matching AsyncAPI 3.0 YAML document
- **AND** the response content type identifies YAML text

#### Scenario: Registered game has no static specification
- **WHEN** an engineer requests a reference or raw route for a registered game without `priv/specs/<slug>.yaml`
- **THEN** the server responds with not found

#### Scenario: Slug is not registered
- **WHEN** an engineer requests a reference or raw route with an unknown slug
- **THEN** the server responds with not found
- **AND** no request-provided value is used as an unchecked filesystem path
