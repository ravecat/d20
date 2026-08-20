## MODIFIED Requirements

### Requirement: Shared account dialog switches between registration and login

The system SHALL provide one guest account dialog with Login as its default account-entry mode and Register as its secondary account-creation mode. An unauthenticated shared header SHALL present a `Log in` action and MUST NOT present a `Register` action. Activating the header action SHALL open Login mode without navigation. Activating the new-user action in Login mode SHALL switch to Register mode without navigation, and activating the existing-user action in Register mode SHALL switch back to Login mode without navigation. The first email field in each active mode SHALL be declared as that mode's native autofocus target when the dialog is shown. Mounting the dialog for an open auth state SHALL invoke its native modal opening behavior once. Escape, supported light dismissal, and the explicit close action SHALL converge on the native dialog close event, which SHALL close shared auth state and remove the dialog. A mode change while the dialog is already open SHALL preserve the entered email, clear stale form errors and result states, update the accessible dialog name, and focus the first field in the active mode from the shared mode-switch handler after its conditional DOM update. The visible title for reauthentication, Register, and Login SHALL be selected directly inside the rendered heading from component input properties so localizable display strings remain at their markup consumption site; the component MUST NOT store the selected title in intermediate reactive state. Closing the dialog SHALL discard unfinished input and transient form and result state so the next clean header opening starts in Login mode with fresh values. The inactive top-level mode MUST NOT remain in the rendered accessibility tree.

#### Scenario: Guest opens account entry from the shared header

- **WHEN** an unauthenticated guest activates the shared header account action
- **THEN** the action is named `Log in`
- **AND** the same page displays the shared dialog in Login mode
- **AND** Login forms and available `Sign in with <provider>` actions are rendered
- **AND** no `Register` header action or registration-only dialog control is rendered
- **AND** the browser's native dialog focusing behavior selects the Login email field

#### Scenario: Guest uses the explicit close action

- **WHEN** a guest activates the dialog's explicit close action
- **THEN** the native modal closes
- **AND** the shared auth state closes and removes the dialog
- **AND** reopening from the header starts with a fresh Login form

#### Scenario: Guest switches from login to registration

- **WHEN** a guest enters an email in Login mode and activates Create account
- **THEN** the same dialog displays Register mode without navigation
- **AND** the entered email remains available in registration
- **AND** login-only controls are no longer rendered
- **AND** focus moves to the registration email field after Register mode is rendered

#### Scenario: Guest switches from registration to login

- **WHEN** a guest activates Log in from Register mode
- **THEN** the same dialog displays Login mode without changing the current page URL
- **AND** the entered email remains available in the login forms
- **AND** registration-only controls are no longer rendered
- **AND** focus moves to the first Login email field after Login mode is rendered

#### Scenario: Guest closes unfinished account entry

- **WHEN** a guest enters account data or reaches a transient result and closes the account dialog
- **THEN** the unfinished input and transient state are discarded
- **AND** opening Log in again starts with a fresh Login form

#### Scenario: Dialog selects localizable title copy

- **WHEN** the dialog renders reauthentication, Register, or Login mode
- **THEN** its heading selects the corresponding visible title directly from component input properties at the markup consumption site
- **AND** the selected display string is not stored in intermediate reactive state
