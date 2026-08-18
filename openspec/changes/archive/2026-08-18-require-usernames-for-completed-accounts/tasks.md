## 1. Model the Reachable Registration Lifecycle

- [x] 1.1 Remove the experimental confirmed-username database constraint and Ecto mapping while retaining required username validation and atomic registration completion.
- [x] 1.2 Remove authentication and session guards added solely for confirmed users without usernames, and retain tests for the supported registration-before-authentication flow.

## 2. Remove Legacy Username Adoption

- [x] 2.1 Remove the username claim Accounts API and Account Settings controller action, delete the confirmed-without-username fixture and legacy controller/context tests, and retain registration-completion validation coverage.
- [x] 2.2 Remove the registered-profile email fallback and verify registered profiles from supported flows expose username while unknown actors remain anonymous.

## 3. Account Settings and Catalog

- [x] 3.1 Make the Account Settings username prop required, remove the username claim form and its frontend test, and retain immutable username, email, password, and provider-state coverage.
- [x] 3.2 Remove the Account Settings `ClaimUsername` story and reconcile the active Apple Storybook design and delta specification with the reachable account lifecycle.

## 4. Validation and Delivery

- [x] 4.1 Format touched files and run focused Accounts, authentication, Account Settings, frontend, type, lint, and Storybook validation.
- [x] 4.2 Run `just check`, strict OpenSpec validation, synchronize the delta specifications, and archive the completed change.
