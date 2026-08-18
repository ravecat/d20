# Email Account Login Specification

## Purpose

Define the shared and direct Inertia account journeys for magic-link and password login, including safe returns, independent form state, session security, and accessible dialog behavior.

## Requirements

### Requirement: Shared account dialog switches between registration and login

The system SHALL provide one guest account dialog with Register and Login modes. Activating the existing-user action in Register mode SHALL switch to Login mode without navigation, and activating the new-user action in Login mode SHALL switch to Register mode without navigation. The first email field in each active mode SHALL be declared as that mode's native autofocus target when the dialog is shown. Mounting the dialog for an open auth state SHALL invoke its native modal opening behavior once. Escape, supported light dismissal, and the explicit close action SHALL converge on the native dialog close event, which SHALL close shared auth state and remove the dialog. A mode change while the dialog is already open SHALL preserve the entered email, clear stale form errors and result states, update the accessible dialog name, and focus the first field in the active mode from the shared mode-switch handler after its conditional DOM update. The visible title for reauthentication, Register, and Login SHALL be selected directly inside the rendered heading from component input properties so localizable display strings remain at their markup consumption site; the component MUST NOT store the selected title in intermediate reactive state. Closing the dialog SHALL discard unfinished input and transient form and result state so the next opening starts from its requested initial mode and values. The inactive top-level mode MUST NOT remain in the rendered accessibility tree.

#### Scenario: Guest opens an account mode

- **WHEN** the shared account dialog opens in Register or Login mode
- **THEN** the browser's native dialog focusing behavior selects the first email field in the active mode

#### Scenario: Guest uses the explicit close action

- **WHEN** a guest activates the dialog's explicit close action
- **THEN** the native modal closes
- **AND** the shared auth state closes and removes the dialog
- **AND** reopening the dialog starts with fresh transient state

#### Scenario: Guest switches from registration to login

- **WHEN** a guest opens Register from the shared header, enters an email, and activates Log in
- **THEN** the same dialog displays Login mode without changing the current page URL
- **AND** the entered email remains available in the login forms
- **AND** registration-only controls are no longer rendered
- **AND** focus moves to the first login email field after Login mode is rendered

#### Scenario: Guest switches from login to registration

- **WHEN** a guest activates Create account from Login mode
- **THEN** the same dialog displays Register mode without navigation
- **AND** the entered email remains available in registration
- **AND** login-only controls are no longer rendered
- **AND** focus moves to the registration email field after Register mode is rendered

#### Scenario: Guest closes unfinished account entry

- **WHEN** a guest enters account data or reaches a transient result and closes the account dialog
- **THEN** the unfinished input and transient state are discarded
- **AND** opening Register again starts with a fresh registration form

#### Scenario: Dialog selects localizable title copy

- **WHEN** the dialog renders reauthentication, Register, or Login mode
- **THEN** its heading selects the corresponding visible title directly from component input properties at the markup consumption site
- **AND** the selected display string is not stored in intermediate reactive state

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

### Requirement: Inertia pages expose one global authentication object

Every Inertia page SHALL expose one required `auth` object through the shared reactive Page props. The object SHALL contain required boolean `authenticated`, required nullable `prompt`, required boolean `local`, and required `providers` fields. `providers.apple.available`, `providers.discord.available`, and `providers.google.available` SHALL independently report their bounded runtime availability. `prompt` SHALL contain the existing authentication-prompt structure plus a server-owned `kind` of `info`, `warning`, or `error` when the server requests Login or sudo reauthentication and SHALL be `null` otherwise. `local` SHALL identify whether the local development mailbox is available. The former top-level `authenticated`, `authPrompt`, and `localMailboxAvailable` props MUST NOT be exposed. Provider credentials and callback data MUST NOT appear in shared props.

#### Scenario: Guest page has no prompt or local mailbox

- **WHEN** an unauthenticated guest receives an Inertia page without a stored prompt and without an available local mailbox
- **THEN** `auth.authenticated` is `false`
- **AND** `auth.prompt` is `null`
- **AND** `auth.local` is `false`
- **AND** `auth.providers.apple.available` reflects only the bounded runtime availability state
- **AND** `auth.providers.discord.available` reflects only the bounded runtime availability state
- **AND** none of the former flat authentication props is present

#### Scenario: Authenticated page reports account state

- **WHEN** an authenticated user receives an Inertia page
- **THEN** `auth.authenticated` is `true`
- **AND** the shared header derives its account actions from that nested value

#### Scenario: Stored prompt is nested in auth

- **WHEN** the server assigns a stored authentication prompt to an Inertia response
- **THEN** the existing prompt structure is available at `auth.prompt`
- **AND** its `kind` explicitly identifies the server-selected semantic severity
- **AND** reactive Page consumers can open the requested account dialog from that nested value

#### Scenario: Apple secrets remain server-side

- **WHEN** any Inertia page receives the shared authentication object
- **THEN** it contains no Apple client ID, client secret, token, subject, email, or callback payload

#### Scenario: Discord availability is shared without credentials

- **WHEN** Discord has usable server-side credentials
- **THEN** every Inertia page reports `auth.providers.discord.available` as `true`
- **AND** no Discord client secret is present in the shared page props

### Requirement: Account dialog messages expose semantic severity

The shared authentication prompt SHALL include a server-owned severity kind of `info`, `warning`, or `error`. AuthDialog SHALL present prompt messages and successful email registration or magic-link results as visually distinct inline blocks with readable text on the left, a severity-specific circular symbol on the right, a tinted surface, and a visible semantic border. Multi-line notice content SHALL align the trailing symbol with its first line, improve body-copy wrapping where the browser supports it, and keep short linked action labels intact. Info, warning, and error variants and any links in their child content SHALL use the matching global semantic theme color rather than the primary action color. Severity MUST NOT be communicated by color or icon shape alone. Informational and warning notices SHALL use polite status semantics, while error notices SHALL use alert semantics. Successful email registration and magic-link results SHALL use the informational variant. The client MUST NOT infer prompt severity from message text.

When the dialog is not requesting reauthentication, both Register and Login SHALL use the shared introduction `Save your game history and achievements. Share game sessions across devices and watch replays of completed games.`

#### Scenario: Matching Discord email requires an explicit link

- **WHEN** an unknown Discord identity returns an email already owned by a D20 account
- **THEN** the existing-method and explicit-link guidance is presented as a warning notice
- **AND** the notice remains distinguishable from the surrounding account description and forms
- **AND** assistive technology can determine that the message is a warning

#### Scenario: Local mailbox guidance follows a successful email request

- **WHEN** the local development mailbox is available before an email registration or magic-link request succeeds
- **THEN** AuthDialog does not render a standalone mailbox notice or link
- **WHEN** either email request succeeds
- **THEN** its informational check-email result appends a link to `/dev/mailbox`
- **AND** the mailbox link inherits the informational accent
- **AND** assistive technology can determine that the result is informational

#### Scenario: Authentication operation fails

- **WHEN** an authentication prompt reports an expired, unavailable, or failed operation
- **THEN** the message is presented as an error notice with alert semantics
- **AND** the message remains readable without relying on color alone

#### Scenario: Informational message wraps across lines

- **WHEN** an informational message requires multiple lines
- **THEN** its severity symbol aligns with the first line rather than the vertical midpoint of the complete paragraph
- **AND** supported browsers improve the text rag without changing the notification width
- **AND** short linked action labels remain unbroken

#### Scenario: Guest opens either account mode

- **WHEN** a guest opens Register or Login without a reauthentication prompt
- **THEN** the shared introduction explains that game sessions can be shared across devices
- **AND** Register and Login show the same introduction

### Requirement: Login mode exposes magic-link and password alternatives

Login mode SHALL show a magic-link form, an `or` separator, and a username-or-email and password form. The magic-link form SHALL require an email address, the password form SHALL accept either username or email as its identifier, and the two local forms SHALL submit independently. Google, Apple, and Discord SHALL each be a normal full-document provider link labelled `Sign in with <provider>` only when its own runtime configuration reports it available. Unavailable providers and Facebook SHALL be omitted. A second `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews login methods with Apple available

- **WHEN** Login mode opens while Apple is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** every provider action uses the `Sign in with <provider>` label pattern
- **AND** the guest can start Apple login through normal full-document navigation
- **AND** available Discord and Google links remain independently derived from their own runtime availability
- **AND** unavailable providers and Facebook are not rendered

#### Scenario: Guest reviews login methods with Apple unavailable

- **WHEN** Login mode opens while Apple is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** available Discord and Google links remain independently derived from their own runtime availability
- **AND** Apple, Facebook, and every other unavailable provider are not rendered

#### Scenario: Guest reviews login methods with Discord available

- **WHEN** Login mode opens while Discord is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** the guest can start Discord login through normal full-document navigation
- **AND** available Apple and Google links remain independently derived from their own credentials
- **AND** unavailable providers and Facebook are not rendered

#### Scenario: Guest reviews login methods with Discord unavailable

- **WHEN** Login mode opens while Discord is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** Discord is not rendered while available Apple and Google links remain independent
- **AND** no unavailable provider choice or empty provider placeholder is rendered
- **AND** the external-provider separator and group are omitted when every provider is unavailable

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

### Requirement: Magic-link login request uses the Inertia account flow

The magic-link login form SHALL submit the email through the existing Phoenix login action using its own Inertia form instance. The response MUST use neutral language that does not reveal whether the email belongs to an account. A successful request SHALL replace the magic-link form with an informational check-email inline notification inside Login mode while leaving password and provider alternatives available. When `auth.local` is `true`, the notification SHALL append a `/dev/mailbox` link after the neutral production message. When `auth.local` is `false`, no mailbox guidance or link SHALL render.

#### Scenario: Existing email requests a magic link

- **WHEN** a guest submits the magic-link form with an existing account email
- **THEN** the existing login-instruction delivery is requested
- **AND** the dialog reports in an informational status that an email will arrive if the address is in the system
- **AND** the current Inertia page remains behind the open dialog

#### Scenario: Unknown email requests a magic link

- **WHEN** a guest submits the magic-link form with an email that does not belong to an account
- **THEN** no account is created and no authentication occurs
- **AND** the dialog presents the same neutral informational check-email result used for an existing email

#### Scenario: Local magic-link request exposes the mailbox

- **WHEN** `auth.local` is `true` and a magic-link request succeeds
- **THEN** the informational result ends with a link to `/dev/mailbox`
- **AND** no standalone mailbox notice remains elsewhere in the dialog

### Requirement: Password login uses the existing Phoenix session security

The password login form SHALL require a username-or-email identifier and current password, SHALL offer an unchecked Keep me signed in choice, and SHALL authenticate through Accounts password verification and the existing Auth session creation. Username and email comparison SHALL be case-insensitive. Successful authentication MUST rotate the browser session according to existing behavior. Selecting Keep me signed in SHALL use the existing remember-me cookie behavior.

#### Scenario: Guest logs in with valid email and password

- **WHEN** a guest submits valid email and password credentials
- **THEN** the existing D20 user is authenticated
- **AND** the browser authentication session is rotated
- **AND** the shared `auth.authenticated` value no longer exposes guest account actions

#### Scenario: Guest logs in with valid username and password

- **WHEN** a guest submits a case-insensitively equivalent username and the user's valid password
- **THEN** the existing D20 user is authenticated
- **AND** the browser authentication session is rotated

#### Scenario: Guest chooses persistent login

- **WHEN** a guest submits valid username-or-email credentials with Keep me signed in selected
- **THEN** the existing signed remember-me cookie is issued

#### Scenario: Guest submits invalid credentials

- **WHEN** a guest submits an unknown identifier, an incorrect password, or an account without a password
- **THEN** the request does not authenticate the caller
- **AND** Login mode displays one generic invalid username, email, or password error only in the password form

### Requirement: Account forms keep independent Inertia state

Registration, magic-link login, password login, magic-link confirmation, username settings, email settings, and password settings SHALL use distinct Inertia form instances and SHALL expose flat field errors, processing, success, and failure only in the form that initiated the request. The forms MUST NOT require explicit error bags to isolate their local state. While a form is processing, its submit action MUST prevent repeated submission without disabling unrelated alternatives.

#### Scenario: Password validation fails while other login methods are visible

- **WHEN** the password form returns an invalid-credentials error through the complete Inertia redirect
- **THEN** the flat credentials error appears only in the password form
- **AND** the magic-link form and provider list do not display that error
- **AND** the guest can still request a magic link

#### Scenario: Magic-link request is processing

- **WHEN** the magic-link form is awaiting its response
- **THEN** its submit action communicates processing and cannot be submitted again
- **AND** the password form remains available

#### Scenario: Account-settings validation fails

- **WHEN** the username, email, or password settings form returns a validation error through the complete Inertia redirect
- **THEN** the flat field error appears only in the settings form that submitted
- **AND** the sibling settings forms remain available

### Requirement: Successful authentication returns only to a safe local page

Account forms SHALL distinguish the local page receiving the immediate form response from the intended post-authentication destination. The server MUST accept either path only when it is a local absolute path without a scheme, host, or protocol-relative prefix. Password authentication SHALL return immediately to the accepted post-authentication path. Registration and magic-link request results SHALL return to the Inertia page behind the open dialog, while a magic link consumed in the same browser session SHALL return to the accepted post-authentication path. Missing or rejected values SHALL use safe route-specific fallbacks.

#### Scenario: Password login returns to the originating game page

- **WHEN** a guest opens Login on a game detail page and authenticates with a password
- **THEN** the authenticated response returns to that game detail path

#### Scenario: External return target is rejected

- **WHEN** an account form submits an external, protocol-relative, or malformed return target
- **THEN** the target is not stored or used for redirection
- **AND** authentication uses the existing safe signed-in fallback

#### Scenario: Prompted magic-link request stays on its host page before later authentication

- **WHEN** the server opens Login mode on the home page while a different safe post-authentication destination is stored
- **AND** the guest requests a magic link
- **THEN** the check-email response returns behind the open dialog on the home page
- **AND** consuming the link in the same browser session returns to the stored post-authentication destination

### Requirement: Login dialog remains keyboard and viewport accessible

The account dialog SHALL use native modal dialog semantics, expose an accessible name for the active mode, use programmatically associated labels for every form field, preserve visible focus indicators, support native Escape and an explicit close action, and keep all active controls reachable at supported narrow and wide viewports. The implementation SHALL leave post-close focus placement to native dialog behavior and MUST NOT require a caller-supplied return-focus element or explicitly focus a caller-owned element after close. The implementation MUST NOT add a custom Tab focus trap to the native modal dialog. The account dialog SHALL declare native light dismissal for browsers that support it and MUST NOT implement backdrop hit testing through scripted pointer-coordinate or dialog-bound calculations. Browsers without native light-dismiss support SHALL retain Escape and the explicit close action.

#### Scenario: Keyboard user switches and closes login

- **WHEN** a keyboard user opens Register, switches to Login, and closes with Escape
- **THEN** focus enters the active Login mode after the switch
- **AND** the browser contains focus within the native modal while it is open
- **AND** the application closes the dialog without explicitly focusing a caller-owned element

#### Scenario: Browser supports native modal light dismissal

- **WHEN** Login mode is open in a browser that supports native modal light dismissal and the guest activates the CSS-styled backdrop
- **THEN** the browser closes the dialog without application pointer-coordinate or dialog-bound hit testing
- **AND** the application does not require a caller-supplied return-focus element

#### Scenario: Browser does not support native modal light dismissal

- **WHEN** Login mode is open in a browser without native modal light-dismiss support
- **THEN** the guest can still close the dialog with Escape or the explicit close action

#### Scenario: Login opens on a narrow viewport

- **WHEN** a guest opens Login at a supported mobile viewport width
- **THEN** Login uses the near-full-viewport inset account surface
- **AND** both enabled forms, provider choices, the mode switch, status messages, and close action remain visible or reachable by scrolling

### Requirement: Server-required authentication opens the shared dialog once

When authentication or sudo mode is required, the system SHALL store the rejected safe local destination, redirect to the public home Inertia page, and expose a one-time server prompt at `auth.prompt` that opens Login mode in the shared account dialog. The prompt SHALL identify sudo reauthentication when the caller is already authenticated and SHALL include an understandable message when authentication was requested because of a protected route or an invalid or expired magic link. The prompt MUST NOT be encoded in a query parameter and MUST be removed from the session after it is assigned to the next Inertia page.

#### Scenario: Guest requests a protected page

- **WHEN** an unauthenticated guest requests a protected local GET route
- **THEN** the server stores that route as the safe post-authentication destination
- **AND** redirects to the home page
- **AND** the home page opens Login mode with an authentication-required message from `auth.prompt`

#### Scenario: Authenticated user requires sudo mode

- **WHEN** an authenticated user without recent sudo authentication requests a sudo-protected route
- **THEN** the server stores that route as the safe post-authentication destination
- **AND** the home page opens Login mode as reauthentication with the current email locked

#### Scenario: Magic link is invalid or expired

- **WHEN** a user opens an invalid or expired magic-link confirmation URL
- **THEN** the server redirects to the home page
- **AND** the home page opens Login mode with an invalid-link message

#### Scenario: Prompt is consumed

- **WHEN** an Inertia page receives a stored server auth prompt at `auth.prompt`
- **THEN** that page exposes the prompt once
- **AND** a later page request exposes `auth.prompt` as `null`

### Requirement: Magic link is the password recovery path

The Login mode magic-link form SHALL provide account recovery without requiring the current password. After authenticating through the standalone confirmation page, the user SHALL be able to set a new password through Account Settings. The system MUST NOT introduce a separate password-reset token or standalone forgot-password page as part of this capability.

#### Scenario: User no longer knows the password

- **WHEN** a user who cannot provide the current password requests a magic link
- **THEN** the existing neutral magic-link request flow is used
- **AND** successful confirmation authenticates the user
- **AND** the user can set a password through Account Settings

### Requirement: Direct account journeys use the Inertia presentation

Magic-link confirmation and account settings SHALL remain directly accessible and SHALL render through the Inertia application shell. Registration, ordinary login, and sudo reauthentication SHALL use the shared account dialog and MUST NOT expose standalone GET pages. The existing registration and login POST actions SHALL remain available to the dialog, and all retained journeys SHALL preserve the existing Accounts and Auth semantics without parallel HEEx auth templates.

#### Scenario: Client requests the removed login page

- **WHEN** a client requests `GET /users/log-in`
- **THEN** no standalone login route handles the request

#### Scenario: User opens a valid magic link

- **WHEN** a user navigates to a valid `/users/log-in/:token` URL
- **THEN** an Inertia confirmation page identifies the account email and submits the existing token-confirmation action
- **AND** confirmation preserves the existing session rotation and safe return behavior

#### Scenario: Authenticated user must reauthenticate

- **WHEN** an authenticated user is rejected by a sudo-protected route
- **THEN** the shared account dialog explains that reauthentication is required
- **AND** it pre-fills and locks the authenticated email according to existing behavior

#### Scenario: Authenticated user opens settings

- **WHEN** a recently authenticated user navigates to `/users/settings`
- **THEN** an Inertia settings page exposes independent email-change and password-change forms
- **AND** each form reports only its own validation and processing state
