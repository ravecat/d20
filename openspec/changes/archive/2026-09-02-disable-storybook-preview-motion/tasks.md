## 1. Storybook Preview Motion Policy

- [x] 1.1 Add the Storybook-only no-motion stylesheet and import it after the production application stylesheet.
- [x] 1.2 Confirm the regular application asset entry does not include the Storybook-only stylesheet and retain dedicated header animation browser coverage.

## 2. Validation and Completion

- [x] 2.1 Run scoped frontend formatting, linting, type checking, and the static Storybook build.
- [x] 2.2 Run the dedicated header browser test and Storybook visual projects without updating unrelated screenshot baselines.
- [x] 2.3 Verify the no-motion rule removes the five-second interactive theme-switch wait, reconcile #266 and OpenSpec artifacts, run strict OpenSpec validation, and archive the completed change.
