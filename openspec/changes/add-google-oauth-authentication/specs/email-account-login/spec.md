## MODIFIED Requirements

### Requirement: Login mode exposes magic-link and password alternatives

Login mode SHALL show a magic-link form, an `or` separator, a username-or-email and password form, another `or` separator, and visible Google, Facebook, Apple, and Discord sign-in choices. The magic-link form SHALL require an email address, the password form SHALL accept either username or email as its identifier, and the two local forms SHALL submit independently. Google SHALL always be a normal full-document login link. Facebook, Apple, and Discord SHALL remain marked unavailable and MUST NOT submit, navigate, or initiate authorization.

#### Scenario: Guest reviews login methods

- **WHEN** Login mode opens
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** the guest can start Google login through normal full-document navigation
- **AND** Facebook, Apple, and Discord are visible but disabled
