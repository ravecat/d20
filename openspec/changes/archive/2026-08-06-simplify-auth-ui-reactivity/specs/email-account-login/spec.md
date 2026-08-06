## MODIFIED Requirements

### Requirement: Shared account dialog switches between registration and login

The system SHALL provide one guest account dialog with Register and Login modes. Activating the existing-user action in Register mode SHALL switch to Login mode without navigation, and activating the new-user action in Login mode SHALL switch to Register mode without navigation. A mode change SHALL preserve the entered email, clear stale form errors and result states, update the accessible dialog name, and focus the first field in the active mode. The visible title for reauthentication, Register, and Login SHALL be selected directly inside the rendered heading from component input properties so localizable display strings remain at their markup consumption site; the component MUST NOT store the selected title in intermediate reactive state. Closing the dialog SHALL discard unfinished input and transient form and result state so the next opening starts from its requested initial mode and values. The inactive top-level mode MUST NOT remain in the rendered accessibility tree.

#### Scenario: Guest switches from registration to login

- **WHEN** a guest opens Register from the shared header, enters an email, and activates Log in
- **THEN** the same dialog displays Login mode without changing the current page URL
- **AND** the entered email remains available in the login forms
- **AND** registration-only controls are no longer rendered
- **AND** focus moves to the first login email field

#### Scenario: Guest switches from login to registration

- **WHEN** a guest activates Create account from Login mode
- **THEN** the same dialog displays Register mode without navigation
- **AND** the entered email remains available in registration
- **AND** login-only controls are no longer rendered

#### Scenario: Guest closes unfinished account entry

- **WHEN** a guest enters account data or reaches a transient result and closes the account dialog
- **THEN** the unfinished input and transient state are discarded
- **AND** opening Register again starts with a fresh registration form

#### Scenario: Dialog selects localizable title copy

- **WHEN** the dialog renders reauthentication, Register, or Login mode
- **THEN** its heading selects the corresponding visible title directly from component input properties at the markup consumption site
- **AND** the selected display string is not stored in intermediate reactive state
