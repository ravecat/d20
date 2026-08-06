## 1. Flat auth-form errors

- [x] 1.1 Remove explicit error bags from all account forms while preserving each Inertia `Form` instance's local state.
- [x] 1.2 Refactor the frontend Inertia form mock to route a response to the form instance that submitted instead of an error-bag name, and update focused auth browser tests.
- [x] 1.3 Update the active dialog-composition artifact so later form movement preserves the corrected flat-error contract rather than restoring error bags.

## 2. Redirect regression coverage

- [x] 2.1 Update registration controller tests to model bag-free Inertia requests and assert flat email and delivery errors after the redirected page request.
- [x] 2.2 Update password-login controller tests to model the same redirect flow and assert a flat credentials error.
- [x] 2.3 Update account-settings controller tests to assert flat errors after their redirected page requests.

## 3. Validation and completion

- [x] 3.1 Format touched files and run focused registration, session, settings, and account UI tests.
- [x] 3.2 Run frontend lint, typecheck, broader backend tests, and real-browser registration error verification.
- [x] 3.3 Sync the registration and login specifications, run strict OpenSpec validation, and archive the completed change.
