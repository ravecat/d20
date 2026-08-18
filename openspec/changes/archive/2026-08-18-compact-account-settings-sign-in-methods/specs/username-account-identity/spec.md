## MODIFIED Requirements

### Requirement: Existing accounts remain usable and can adopt a username

The username column SHALL remain nullable for accounts created before username support and for registrations that have not completed confirmation. An authenticated existing user without a username SHALL be offered a dedicated account-settings form to claim one. Existing email, password, magic-link, and linked-provider authentication MUST remain valid whether or not the account has claimed a username. When Account Settings displays an assigned username, its supporting description SHALL explain that the username identifies the player to other D20 players and MUST NOT claim that the username cannot be changed. This presentation constraint MUST NOT add a replacement form or change the existing username claim operation.

#### Scenario: Legacy user opens account settings

- **WHEN** an authenticated user without a username opens account settings
- **THEN** the page provides a username claim form
- **AND** the user's existing authentication methods remain unchanged

#### Scenario: User has already claimed a username

- **WHEN** an authenticated user with a username opens account settings
- **THEN** the page displays the assigned username
- **AND** its supporting description explains that the username identifies the player to other D20 players
- **AND** the description does not claim that the username cannot be changed
- **AND** the page does not offer a username replacement form
