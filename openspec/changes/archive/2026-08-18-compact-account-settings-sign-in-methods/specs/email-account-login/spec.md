## MODIFIED Requirements

### Requirement: Account Settings exposes Discord linking state

The sudo-protected Account Settings page SHALL report whether the current user owns a Discord identity when Discord is available. When Discord is available and not linked, the page SHALL expose a normal full-document action that starts an explicit link intent for that same user. When Discord is available and linked, the page SHALL report the linked state without offering a second link or an unlink action. When Discord is unavailable, the page SHALL omit Discord and MUST NOT initiate authorization. Discord linking state and controls SHALL remain separate from username, email, and password forms.

#### Scenario: User can link an available Discord identity

- **WHEN** a sudo-valid user with no Discord identity opens Account Settings while Discord is available
- **THEN** Account Settings exposes a normal full-document Link Discord action
- **AND** the username, email, and password forms remain independent

#### Scenario: User already linked available Discord

- **WHEN** a user with a Discord identity opens Account Settings while Discord is available
- **THEN** Account Settings reports Discord as linked
- **AND** it does not offer a second Discord link or an unlink action

#### Scenario: Discord linking is unavailable

- **WHEN** a user opens Account Settings while Discord credentials are unavailable
- **THEN** Account Settings omits the Discord provider item
- **AND** no Discord linking action submits, navigates, or initiates authorization
