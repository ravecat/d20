## ADDED Requirements

### Requirement: Shared account dialog switches between registration and login
The system SHALL provide one guest account dialog with Register and Login modes. Activating the existing-user action in Register mode SHALL switch to Login mode without navigation, and activating the new-user action in Login mode SHALL switch to Register mode without navigation. A mode change SHALL preserve the entered email, clear stale form errors and result states, update the accessible dialog name, and focus the first field in the active mode. The inactive top-level mode MUST NOT remain in the rendered accessibility tree.

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

### Requirement: Account dialog follows the active mode content size
At viewports tall enough to contain the active mode, the account dialog SHALL derive its block size from that mode's content through CSS while retaining one common inline size. Switching between Register and Login MUST NOT require scripted DOM measurement, numeric block-size writes, animation-frame scheduling, or resize timers. When the active mode is taller than the available viewport, the dialog SHALL constrain itself to the viewport and keep active content reachable through internal scrolling.

#### Scenario: Guest switches modes on a desktop viewport
- **WHEN** a guest opens Register and switches to Login at a viewport that can contain the complete Login layout
- **THEN** the dialog retains its inline size and adopts the Login content block size through normal CSS layout
- **AND** switching back adopts the shorter Register content block size without an inline block-size override
- **AND** neither mode requires internal scrolling

#### Scenario: Active dialog content exceeds the viewport
- **WHEN** the available viewport is shorter than the active mode's complete content size
- **THEN** the dialog remains within the viewport
- **AND** active controls remain reachable through the dialog's content scroller

### Requirement: Login mode exposes magic-link and password alternatives
Login mode SHALL show a magic-link form, an `or` separator, an email-and-password form, another `or` separator, and visible Google, Facebook, Apple, and Discord sign-in choices marked unavailable. The two enabled forms SHALL submit independently and unavailable provider choices MUST NOT submit, navigate, or initiate authorization.

#### Scenario: Guest reviews login methods
- **WHEN** Login mode opens
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit an email address and password
- **AND** Google, Facebook, Apple, and Discord are visible but disabled

### Requirement: Magic-link login request uses the Inertia account flow
The magic-link login form SHALL submit the email through the existing Phoenix login action using an Inertia form and its own error bag. The response MUST use neutral language that does not reveal whether the email belongs to an account. A successful request SHALL show a check-email result inside Login mode while leaving password and provider alternatives available.

#### Scenario: Existing email requests a magic link
- **WHEN** a guest submits the magic-link form with an existing account email
- **THEN** the existing login-instruction delivery is requested
- **AND** the dialog reports that an email will arrive if the address is in the system
- **AND** the current Inertia page remains behind the open dialog

#### Scenario: Unknown email requests a magic link
- **WHEN** a guest submits the magic-link form with an email that does not belong to an account
- **THEN** no account is created and no authentication occurs
- **AND** the dialog presents the same neutral check-email result used for an existing email

### Requirement: Password login uses the existing Phoenix session security
The password login form SHALL require an email and current password, SHALL offer an unchecked Keep me signed in choice, and SHALL authenticate through the existing Accounts password verification and UserAuth session creation. Successful authentication MUST rotate the browser session according to existing behavior. Selecting Keep me signed in SHALL use the existing remember-me cookie behavior.

#### Scenario: Guest logs in with valid email and password
- **WHEN** a guest submits valid email and password credentials
- **THEN** the existing D20 user is authenticated
- **AND** the browser authentication session is rotated
- **AND** the shared `authenticated` prop no longer exposes guest account actions

#### Scenario: Guest chooses persistent login
- **WHEN** a guest submits valid credentials with Keep me signed in selected
- **THEN** the existing signed remember-me cookie is issued

#### Scenario: Guest submits invalid credentials
- **WHEN** a guest submits an unknown email, an incorrect password, or an account without a password
- **THEN** the request does not authenticate the caller
- **AND** Login mode displays one generic invalid email or password error only in the password form

### Requirement: Account forms keep independent Inertia state
Registration, magic-link login, and password login SHALL use distinct Inertia error bags and SHALL expose processing, success, and failure only in the form that initiated the request. While a form is processing, its submit action MUST prevent repeated submission without disabling unrelated login alternatives.

#### Scenario: Password validation fails while other login methods are visible
- **WHEN** the password form returns an invalid-credentials error
- **THEN** the error appears only in the password form
- **AND** the magic-link form and provider list do not display that error
- **AND** the guest can still request a magic link

#### Scenario: Magic-link request is processing
- **WHEN** the magic-link form is awaiting its response
- **THEN** its submit action communicates processing and cannot be submitted again
- **AND** the password form remains available

### Requirement: Successful authentication returns only to a safe local page
Account forms SHALL distinguish the local page receiving the immediate form response from the intended post-authentication destination. The server MUST accept either path only when it is a local absolute path without a scheme, host, or protocol-relative prefix. Password authentication SHALL return immediately to the accepted post-authentication path. Registration and magic-link request results SHALL return to the submitting account surface, while a magic link consumed in the same browser session SHALL return to the accepted post-authentication path. Missing or rejected values SHALL use safe route-specific fallbacks.

#### Scenario: Password login returns to the originating game page
- **WHEN** a guest opens Login on a game detail page and authenticates with a password
- **THEN** the authenticated response returns to that game detail path

#### Scenario: External return target is rejected
- **WHEN** an account form submits an external, protocol-relative, or malformed return target
- **THEN** the target is not stored or used for redirection
- **AND** authentication uses the existing safe signed-in fallback

#### Scenario: Direct magic-link request stays on login before later authentication
- **WHEN** a guest requests a magic link from `/users/log-in` while a different safe post-authentication destination is stored
- **THEN** the check-email response returns to `/users/log-in`
- **AND** consuming the link in the same browser session returns to the stored post-authentication destination

### Requirement: Login dialog remains keyboard and viewport accessible
The account dialog SHALL use native modal dialog semantics, expose an accessible name for the active mode, use programmatically associated labels for every form field, preserve visible focus indicators, support native Escape and an explicit close action, restore focus to the invoking header action, and keep all active controls reachable at supported narrow and wide viewports. The implementation MUST NOT add a custom Tab focus trap to the native modal dialog.

#### Scenario: Keyboard user switches and closes login
- **WHEN** a keyboard user opens Register, switches to Login, and closes with Escape
- **THEN** focus enters the active Login mode after the switch
- **AND** the browser contains focus within the native modal while it is open
- **AND** focus returns to the Register trigger after close

#### Scenario: Login opens on a narrow viewport
- **WHEN** a guest opens Login at a supported mobile viewport width
- **THEN** both enabled forms, provider choices, the mode switch, status messages, and close action remain visible or reachable by scrolling

### Requirement: Direct account journeys use the Inertia presentation
The existing registration, login, magic-link confirmation, account-settings, and sudo reauthentication URLs SHALL remain directly accessible and SHALL render through the Inertia application shell. These pages SHALL use the same Accounts and UserAuth semantics as the shared account dialog and MUST NOT depend on parallel HEEx auth templates.

#### Scenario: User opens the direct login page
- **WHEN** a user navigates directly to `/users/log-in`
- **THEN** the Inertia login page exposes the same magic-link and password forms as Login mode
- **AND** the user can switch to the direct registration journey

#### Scenario: User opens a valid magic link
- **WHEN** a user navigates to a valid `/users/log-in/:token` URL
- **THEN** an Inertia confirmation page identifies the account email and submits the existing token-confirmation action
- **AND** confirmation preserves the existing session rotation and safe return behavior

#### Scenario: Authenticated user must reauthenticate
- **WHEN** an authenticated user is redirected to `/users/log-in` for sudo reauthentication
- **THEN** the Inertia login page explains that reauthentication is required
- **AND** it pre-fills and locks the authenticated email according to existing behavior

#### Scenario: Authenticated user opens settings
- **WHEN** a recently authenticated user navigates to `/users/settings`
- **THEN** an Inertia settings page exposes independent email-change and password-change forms
- **AND** each form reports only its own validation and processing state
