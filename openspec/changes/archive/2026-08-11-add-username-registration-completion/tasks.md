## 1. Persistence and Accounts Domain

- [x] 1.1 Add the nullable case-insensitive username column and named unique index migration, including a reversible down path.
- [x] 1.2 Add canonical username format validation, uniqueness handling, and one-time claim changesets to the User schema.
- [x] 1.3 Add Accounts operations for one-time username claims, username-or-email password lookup, and username-preferred profile presentation.

## 2. Registration Completion

- [x] 2.1 Extend magic-link inspection and confirmation so unconfirmed registrations require username and complete username assignment, email confirmation, and token deletion in one transaction.
- [x] 2.2 Update the confirmation controller and Inertia page to immediately lowercase and trim the submitted username, preserve the token on controlled errors, and leave confirmed-user magic-link login unchanged.
- [x] 2.3 Cover immediate client normalization, successful completion, non-mutating GET, invalid and duplicate usernames, concurrent uniqueness enforcement, and token retention with frontend, Accounts, and controller tests.
- [x] 2.4 Render registration completion directly as responsive page content without a dialog-like card surface while preserving form semantics and states.

## 3. Existing Account Adoption

- [x] 3.1 Expose current username state to account settings and add a guarded one-time username claim action.
- [x] 3.2 Add the account-settings claim form with immediate lowercase and trim behavior for users without a username and immutable username presentation after assignment.
- [x] 3.3 Cover immediate client normalization, settings claim success, validation and duplicate failures, repeated assignment rejection, and unchanged existing authentication methods in backend and frontend tests.

## 4. Username Password Login

- [x] 4.1 Change the password session action to compare a username-or-email identifier directly through the case-insensitive database columns, without application guards or string normalization, and return one generic invalid-credentials error.
- [x] 4.2 Change only the password form to use an accessible username-or-email text field while the magic-link form remains email-only.
- [x] 4.3 Cover direct case-insensitive username and email comparisons, unknown identifiers, wrong passwords, passwordless accounts, and independent form state in backend and frontend tests.

## 5. Validation and Delivery

- [x] 5.1 Format touched files and run targeted Accounts, controller, migration, and Svelte tests.
- [x] 5.2 Run backend, frontend, type, lint, OpenSpec strict, and broad repository validation required by the change.
- [x] 5.3 Archive the completed OpenSpec change and confirm the strict archive validation and active-change list are clean.
